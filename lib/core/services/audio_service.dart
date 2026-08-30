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
/// A small pool of low-latency players lets card sounds overlap without
/// allocating a player per effect. Every failure path is swallowed — audio
/// is a nicety, never a reason to interrupt a match.
class AudioService {
  AudioService._();

  static final AudioService instance = AudioService._();

  static const int _poolSize = 5;
  final List<AudioPlayer> _pool = [];
  AudioPlayer? _music;
  int _next = 0;
  bool _ready = false;

  bool _soundEnabled = true;
  bool _musicEnabled = false;
  bool _musicShouldPlay = false;

  Future<void> init() async {
    if (_ready) return;
    try {
      for (var i = 0; i < _poolSize; i++) {
        final player = AudioPlayer()
          ..setReleaseMode(ReleaseMode.stop)
          ..setPlayerMode(PlayerMode.lowLatency);
        _pool.add(player);
      }
      // Warm the cache so the first card played is not the slow one (§54).
      await AudioCache.instance.loadAll(
        Sfx.values.map((s) => 'audio/${s.file}').toList(),
      );
      _ready = true;
    } catch (error) {
      Log.d('Audio unavailable, continuing silently: $error');
      _ready = false;
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

  void play(Sfx sfx, {double volume = 1.0}) {
    if (!_soundEnabled || !_ready || _pool.isEmpty) return;
    final player = _pool[_next];
    _next = (_next + 1) % _pool.length;
    player
        .play(AssetSource('audio/${sfx.file}'), volume: volume.clamp(0.0, 1.0))
        .catchError((Object error) => Log.d('sfx: $error'));
  }

  /// §43 — the loop sits far back in the mix and is off by default.
  Future<void> startMusic() async {
    _musicShouldPlay = true;
    if (!_musicEnabled) return;
    try {
      _music ??= AudioPlayer()..setReleaseMode(ReleaseMode.loop);
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
      for (final p in _pool) {
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
    for (final p in _pool) {
      await p.dispose();
    }
    _pool.clear();
    await _music?.dispose();
    _music = null;
    _ready = false;
  }
}
