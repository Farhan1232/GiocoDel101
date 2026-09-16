// A stand-in for the audioplayers platform plugin, so tests can exercise the
// real sound path instead of skipping it.
//
// This exists because the sound path had never been executed by a single
// test: `AudioService.init()` cannot reach a platform under `flutter test`,
// so `play()` returned before it built a player, and every long-session
// harness measured a table that made no noise. The one defect that explained
// the client's crash lived exactly there.
import 'dart:async';
import 'dart:io';

import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gioco_del_101/core/services/audio_service.dart';

/// Stands in for the Android/iOS plugin: records what the app asked for and
/// answers exactly as a real low-latency (SoundPool) player does — including
/// the part that matters, that it never reports a position and never reports
/// completion.
class FakeAudioPlatform extends AudioplayersPlatformInterface {
  final Map<String, StreamController<AudioEvent>> _events = {};
  final List<String> resumed = [];
  int positionQueries = 0;

  @override
  Future<void> create(String playerId) async {
    _events[playerId] = StreamController<AudioEvent>.broadcast();
  }

  @override
  Stream<AudioEvent> getEventStream(String playerId) =>
      (_events[playerId] ??= StreamController<AudioEvent>.broadcast()).stream;

  @override
  Future<void> dispose(String playerId) async {
    await _events.remove(playerId)?.close();
  }

  @override
  Future<void> resume(String playerId) async => resumed.add(playerId);

  /// Exactly what `SoundPoolPlayer.getCurrentPosition()` returns.
  @override
  Future<int?> getCurrentPosition(String playerId) async {
    positionQueries++;
    return null;
  }

  @override
  Future<int?> getDuration(String playerId) async => null;

  @override
  Future<void> pause(String playerId) async {}
  @override
  Future<void> stop(String playerId) async {}
  @override
  Future<void> release(String playerId) async {}
  @override
  Future<void> seek(String playerId, Duration position) async {}
  @override
  Future<void> setBalance(String playerId, double balance) async {}
  @override
  Future<void> setVolume(String playerId, double volume) async {}
  @override
  Future<void> setReleaseMode(String playerId, ReleaseMode releaseMode) async {}
  @override
  Future<void> setPlaybackRate(String playerId, double rate) async {}
  @override
  Future<void> setAudioContext(String playerId, AudioContext ctx) async {}
  @override
  Future<void> setPlayerMode(String playerId, PlayerMode mode) async {}
  @override
  Future<void> setSourceUrl(
    String playerId,
    String url, {
    bool? isLocal,
    String? mimeType,
  }) async {
    _events[playerId]?.add(
      const AudioEvent(eventType: AudioEventType.prepared, isPrepared: true),
    );
  }

  @override
  Future<void> setSourceBytes(
    String playerId,
    Uint8List bytes, {
    String? mimeType,
  }) async {}

  @override
  Future<void> emitLog(String playerId, String message) async {}
  @override
  Future<void> emitError(String playerId, String code, String message) async {}
}

class FakeGlobalAudioPlatform implements GlobalAudioplayersPlatformInterface {
  final _events = StreamController<GlobalAudioEvent>.broadcast();

  @override
  Future<void> init() async {}
  @override
  Future<void> setGlobalAudioContext(AudioContext ctx) async {}
  @override
  Stream<GlobalAudioEvent> getGlobalEventStream() => _events.stream;
  @override
  Future<void> emitGlobalLog(String message) async {}
  @override
  Future<void> emitGlobalError(String code, String message) async {}
}

/// Stands the fake platform up, answers path_provider for [AudioCache], and
/// starts [AudioService] for real. Returns the platform so a test can read
/// what the app asked it to do.
/// Set [disposePlayers] false inside a `testWidgets` body.
/// `AudioPlayer.dispose()` awaits plugin-side futures that only settle while
/// something is pumping, and by the time a tear-down runs nothing is; the
/// await then never returns and the test times out. Nothing in the app calls
/// it either — the sixteen effect players are meant to live as long as the
/// process — so skipping it costs a widget test nothing.
Future<T> startFakeAudio<T extends FakeAudioPlatform>([
  T? fake,
  bool disposePlayers = true,
]) async {
  final platform = fake ?? FakeAudioPlatform() as T;
  AudioplayersPlatformInterface.instance = platform;
  GlobalAudioplayersPlatformInterface.instance = FakeGlobalAudioPlatform();
  final temp = await Directory.systemTemp.createTemp('gd101_audio');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => temp.path,
      );
  addTearDown(() async {
    AudioService.instance.configure(sound: false, music: false);
    if (disposePlayers) {
      await AudioService.instance.dispose();
    }
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });
  AudioService.instance.configure(sound: true, music: false);
  await AudioService.instance.init();
  return platform;
}

/// A faithful transcription of what the Android plugin does with the calls
/// this app makes, so a Dart test can see whether a sound would actually be
/// heard.
///
/// [FakeAudioPlatform] records requests; this one models consequences. Every
/// branch below is a line-for-line port of `audioplayers_android` 5.3.0:
///
/// * `WrappedPlayer.source` — setting the *same* source again is a no-op that
///   only re-signals "prepared"; it does not touch `playing`.
/// * `WrappedPlayer.play()` — `if (!playing && !released) { playing = true;
///   if (prepared) requestFocusAndStart() }`. Already-playing is a no-op.
/// * `WrappedPlayer.pause()` — `if (playing) { playing = false; ... }`.
/// * `WrappedPlayer.stop()` — under `ReleaseMode.stop` this is `pause()` then
///   `seek(0)`.
/// * `SoundPoolPlayer.start()` — `streamId != null` resumes the old stream
///   (inaudible once it has finished); only a null `streamId` reaches
///   `soundPool.play(...)`, which is the one call that makes a noise.
/// * `SoundPoolPlayer.seekTo(0)` — stops, clearing `streamId`.
/// * SoundPool has no completion listener at all — only `MediaPlayerWrapper`
///   installs one — so nothing ever clears `playing` on its own.
class AndroidSoundPoolFake extends FakeAudioPlatform {
  final Map<String, _AndroidPlayer> _players = {};

  /// How many times each player actually reached `soundPool.play(...)` — the
  /// number of times the player would have been heard.
  final Map<String, int> audibleStarts = {};

  _AndroidPlayer _p(String id) => _players.putIfAbsent(id, _AndroidPlayer.new);

  @override
  Future<void> create(String playerId) async {
    await super.create(playerId);
    _players[playerId] = _AndroidPlayer();
  }

  @override
  Future<void> setSourceUrl(
    String playerId,
    String url, {
    bool? isLocal,
    String? mimeType,
  }) async {
    final p = _p(playerId);
    if (p.source != url) {
      p.source = url;
      p.released = false;
      p.prepared = true;
      p.streamId = null;
    }
    await super.setSourceUrl(
      playerId,
      url,
      isLocal: isLocal,
      mimeType: mimeType,
    );
  }

  @override
  Future<void> resume(String playerId) async {
    await super.resume(playerId);
    final p = _p(playerId);
    if (!p.playing && !p.released) {
      p.playing = true;
      if (p.prepared) {
        // SoundPoolPlayer.start()
        if (p.streamId == null) {
          p.streamId = ++_nextStreamId;
          audibleStarts.update(playerId, (v) => v + 1, ifAbsent: () => 1);
        }
      }
    }
  }

  @override
  Future<void> pause(String playerId) async {
    final p = _p(playerId);
    if (p.playing) p.playing = false;
  }

  @override
  Future<void> stop(String playerId) async {
    final p = _p(playerId);
    // ReleaseMode.stop -> pause(), then seek(0), which clears the stream.
    if (p.playing) p.playing = false;
    if (p.prepared) p.streamId = null;
  }

  @override
  Future<void> release(String playerId) async {
    final p = _p(playerId);
    p
      ..playing = false
      ..prepared = false
      ..released = true
      ..source = null
      ..streamId = null;
  }

  int _nextStreamId = 0;
}

class _AndroidPlayer {
  String? source;
  bool playing = false;
  bool prepared = false;
  bool released = true;
  int? streamId;
}
