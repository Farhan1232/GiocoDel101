import 'package:audioplayers/audioplayers.dart';
import '../utils/log.dart';

/// §42 — every sound the game can make.
enum Sfx {
  cardPickup('card_pickup.wav'),
  cardSlide('card_slide.wav'),
  cardDrop('card_drop.wav'),
  shuffle('shuffle.wav'),
  invalid('invalid.wav'),
  click('click.wav'),
  ace('ace.wav'),
  chain1('chain_1.wav'),
  chain2('chain_2.wav'),
  chain3('chain_3.wav'),
  chain4('chain_4.wav'),
  suitSelect('suit_select.wav'),
  scoreTick('score_tick.wav'),
  reset101('reset_101.wav'),
  victory('victory.wav'),
  eliminate('eliminate.wav');

  const Sfx(this.file);

  final String file;

  /// §11 — the Chain Storm rises in pitch as the stack grows.
  static Sfx chainForLevel(int level) => switch (level.clamp(1, 4)) {
    1 => Sfx.chain1,
    2 => Sfx.chain2,
    3 => Sfx.chain3,
    _ => Sfx.chain4,
  };
}

/// Plays the bundled sound set. All assets are local; nothing streams.
///
/// One low-latency player per effect, created on first use and bounded by
/// the [Sfx] catalogue. A player whose source never changes costs the
/// Android backend one bookkeeping entry for the life of the app; the old
/// round-robin pool re-assigned a source on almost every effect, and each
/// re-assignment appended a native map entry that is only removed on
/// release — an unbounded list over a long session. Every failure path is
/// swallowed — audio is a nicety, never a reason to interrupt a match.
class AudioService {
  AudioService._();

  static final AudioService instance = AudioService._();

  final Map<Sfx, AudioPlayer> _players = {};

  /// The tail of each effect's in-flight call chain; see [play].
  final Map<Sfx, Future<void>> _pending = {};
  AudioPlayer? _music;
  bool _ready = false;
  Future<void>? _initing;

  bool _soundEnabled = true;
  bool _musicEnabled = false;
  bool _musicShouldPlay = false;

  Future<void> init() {
    // Coalesce concurrent calls: a second `init` racing the first must not
    // build a second set of native players.
    return _initing ??= _init();
  }

  Future<void> _init() async {
    if (_ready) return;
    try {
      // Warm the cache so the first card played is not the slow one (§54).
      await AudioCache.instance.loadAll(
        Sfx.values.map((s) => 'audio/${s.file}').toList(),
      );
      _ready = true;
    } catch (error) {
      Log.d('Audio unavailable, continuing silently: $error');
      _ready = false;
      _initing = null; // a later call may retry
    }
  }

  void configure({required bool sound, required bool music}) {
    _soundEnabled = sound;
    final wasEnabled = _musicEnabled;
    _musicEnabled = music;
    if (wasEnabled && !music) {
      stopMusic();
    } else if (!wasEnabled && music && _musicShouldPlay) {
      startMusic();
    }
  }

  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;

  /// A low-latency player for one effect, with position reporting turned off.
  AudioPlayer _newEffectPlayer() => _silencePositionUpdates(AudioPlayer())
    ..setReleaseMode(ReleaseMode.stop)
    ..setPlayerMode(PlayerMode.lowLatency);

  /// Detaches the player's position poller — the single most expensive thing
  /// audioplayers does, and pure waste here.
  ///
  /// Every `AudioPlayer` is built with a `FramePositionUpdater`, and `play()`
  /// starts it. That updater re-registers a *transient frame callback* on
  /// every frame and, from inside it, posts an un-awaited
  /// `getCurrentPosition` over the platform channel. Two things follow on a
  /// real phone:
  ///
  /// * The app can never go idle. A frame callback always outstanding means
  ///   Flutter draws at the display rate forever, even on a still table.
  /// * `FramePositionUpdater.start()` does not check whether it is already
  ///   running: it calls `_tick` again, which schedules *another* self-
  ///   rescheduling chain and overwrites the one id `stop()` could have
  ///   cancelled. So every single `play()` — roughly one per card — strands
  ///   one more chain, permanently. After the seven or eight minutes the
  ///   client reported, that is several hundred chains, each posting a
  ///   platform-channel round trip per frame: tens of thousands of messages
  ///   a second, a scheduler list that grows all session, and a backlog of
  ///   in-flight replies that nothing bounds. The game slows down, sticks,
  ///   and the process is killed — and it is worse the longer the session
  ///   runs, which is exactly the report.
  ///
  /// Android's low-latency backend cannot report a position or a completion
  /// at all (`SoundPoolPlayer.getCurrentPosition()` returns null and only
  /// `MediaPlayerWrapper` installs a completion listener), so the poller
  /// could never have produced a single useful value, and nothing in the game
  /// listens to `onPositionChanged`. Removing it costs nothing audible.
  AudioPlayer _silencePositionUpdates(AudioPlayer player) =>
      player..positionUpdater = null;

  void play(Sfx sfx, {double volume = 1.0}) {
    if (!_soundEnabled || !_ready) return;
    final player = _players.putIfAbsent(sfx, _newEffectPlayer);
    final source = AssetSource('audio/${sfx.file}');
    final level = volume.clamp(0.0, 1.0);
    // Stop before playing, and keep one effect's calls in order.
    //
    // A dedicated player that never releases is the right shape — the old
    // round-robin pool re-assigned a source on almost every effect, and the
    // Android backend appends a native bookkeeping entry per source change
    // that only `release()` removes. But a player that is never stopped is
    // one Android believes is *still playing*: `WrappedPlayer.play()` starts
    // nothing while `playing` is true, setting the same source again does not
    // clear that flag, and SoundPool has no completion listener to clear it
    // either (only `MediaPlayerWrapper` installs one). Even if it did get
    // through, `SoundPoolPlayer.start()` would `resume()` the finished stream
    // rather than start a new one. Without the stop, every effect is audible
    // exactly once per app run and the table falls silent after the first
    // few seconds. The stop clears both the flag and the stale stream id, so
    // the next play reaches `soundPool.play(...)` and is heard. This is safe
    // only because the release mode is `stop`: under `release` the same call
    // would drop the source and the next play would re-register it, which is
    // the native-map growth the dedicated player exists to avoid.
    //
    // Chained per effect so a rapid repeat cannot interleave its stop with
    // the previous play. Only the latest future is held, so the chain costs
    // one object, not a growing list.
    _pending[sfx] = (_pending[sfx] ?? Future<void>.value())
        .then((_) => player.stop())
        .then((_) => player.play(source, volume: level))
        .catchError((Object error) => Log.d('sfx: $error'));
  }

  /// §43 — the loop sits far back in the mix and is off by default.
  Future<void> startMusic() async {
    _musicShouldPlay = true;
    if (!_musicEnabled) return;
    try {
      _music ??= _silencePositionUpdates(AudioPlayer())
        ..setReleaseMode(ReleaseMode.loop);
      await _music!.setVolume(0.22);
      await _music!.play(AssetSource('audio/music_loop.wav'), volume: 0.22);
    } catch (error) {
      Log.d('music: $error');
    }
  }

  Future<void> stopMusic() async {
    _musicShouldPlay = false;
    try {
      await _music?.stop();
    } catch (_) {
      // Nothing to stop.
    }
  }

  /// Called when the app leaves the foreground (§50).
  Future<void> pauseAll() async {
    try {
      await _music?.pause();
      for (final p in _players.values) {
        await p.stop();
      }
    } catch (_) {
      // Best effort only.
    }
  }

  Future<void> resumeMusic() async {
    if (_musicEnabled && _musicShouldPlay) {
      try {
        await _music?.resume();
      } catch (_) {
        await startMusic();
      }
    }
  }

  Future<void> dispose() async {
    _pending.clear();
    for (final p in _players.values) {
      await p.dispose();
    }
    _players.clear();
    await _music?.dispose();
    _music = null;
    _ready = false;
    _initing = null;
  }
}
