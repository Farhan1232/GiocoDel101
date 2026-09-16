// §L2 — the long-session audio guard.
//
// The client reproduced, on several phones, a game that plays normally for
// about seven or eight minutes and then slows down, sticks and force-closes,
// worse the longer the session and the higher the score. Every previous
// harness ran with audio switched off: `AudioService.init()` cannot reach a
// platform in `flutter test`, so `play()` returned before it built a single
// player and no test in the suite had ever started one.
//
// This file starts them for real, against a fake audioplayers platform, and
// asserts the one thing the whole failure hangs on: playing a sound must not
// leave a frame callback running behind it.
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gioco_del_101/core/services/audio_service.dart';
import 'support/fake_audio_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAudioPlatform platform;

  setUp(() async {
    platform = await startFakeAudio();
  });

  group('Audio never leaves the app rendering (§L2)', () {
    test('init really did reach the fake platform', () {
      expect(
        AudioService.instance.soundEnabled,
        isTrue,
        reason: 'the guard is worthless if sound is off',
      );
    });

    test('playing every sound leaves no frame callback behind', () async {
      final before = SchedulerBinding.instance.transientCallbackCount;

      // A whole session's worth of sound: every effect the table can make,
      // several times over, exactly as `_reactToCue` fires them.
      for (var pass = 0; pass < 3; pass++) {
        for (final sfx in Sfx.values) {
          AudioService.instance.play(sfx);
          // Let `play()`'s await chain reach `_resume()`, which is what
          // starts the position updater.
          for (var i = 0; i < 8; i++) {
            await Future<void>.delayed(Duration.zero);
          }
        }
      }

      expect(
        platform.resumed.length,
        Sfx.values.length * 3,
        reason: 'the fake platform never actually played anything',
      );

      // The failure: `AudioPlayer` drives a `FramePositionUpdater` that
      // re-registers a frame callback every frame and only ever stops on
      // pause/stop/completion. Android's SoundPool backend (low-latency
      // mode, which is what the table uses) has no completion listener at
      // all — `MediaPlayerWrapper` is the only one that reports one — so
      // for every distinct sound the app has played once, one poller keeps
      // running for the rest of the process: it holds the whole app at the
      // display refresh rate forever and posts an un-awaited platform-
      // channel `getCurrentPosition` per player per frame.
      //
      // That is the client's report exactly: it grows as the session goes
      // on, and the last effects to appear are the round-end ones
      // (`scoreTick`, `reset101`, `eliminate`, `victory`) — which is why it
      // gets worse at a high score.
      expect(
        SchedulerBinding.instance.transientCallbackCount,
        before,
        reason:
            'sound effects left ${SchedulerBinding.instance.transientCallbackCount - before} '
            'frame callbacks running — the app can never go idle again',
      );
    });

    test('a whole session of sound costs nothing per effect played', () async {
      final before = SchedulerBinding.instance.transientCallbackCount;
      platform.positionQueries = 0;

      // Roughly what seven or eight minutes at the table sounds like: the
      // table makes about one noise a second.
      const plays = 500;
      for (var i = 0; i < plays; i++) {
        AudioService.instance.play(Sfx.values[i % Sfx.values.length]);
      }
      for (var i = 0; i < 400; i++) {
        await Future<void>.delayed(Duration.zero);
      }

      expect(platform.resumed.length, plays);
      expect(
        SchedulerBinding.instance.transientCallbackCount,
        before,
        reason:
            'the cost of a sound must not outlive the sound: '
            '${SchedulerBinding.instance.transientCallbackCount - before} '
            'frame callbacks survived $plays effects',
      );
      // Nothing polls, so nothing crosses the platform channel between
      // effects either. Before the fix this was one message per player per
      // frame, forever.
      expect(
        platform.positionQueries,
        0,
        reason: 'something is still polling the native player position',
      );
    });

    test('every effect is heard every time it is played', () async {
      // Not a cosmetic point: the table's whole feel is the sound of a card
      // landing, and Session 7's "one dedicated player per effect that never
      // releases" traded an unbounded native map for a player that Android
      // considers to be playing forever. `WrappedPlayer.play()` refuses to
      // start an already-playing player, SoundPool never reports completion,
      // and setting the same source again does not clear the flag — so
      // without an explicit stop first, each effect would be audible exactly
      // once per app run. [AndroidSoundPoolFake] models that state machine.
      final android = await startFakeAudio(AndroidSoundPoolFake());

      const repeats = 12;
      for (var i = 0; i < repeats; i++) {
        AudioService.instance.play(Sfx.cardSlide);
        for (var j = 0; j < 12; j++) {
          await Future<void>.delayed(Duration.zero);
        }
      }

      expect(
        android.audibleStarts.values.fold<int>(0, (a, b) => a + b),
        repeats,
        reason:
            'the card slide reached soundPool.play() only '
            '${android.audibleStarts.values.fold<int>(0, (a, b) => a + b)} '
            'times out of $repeats — after the first one the table is silent',
      );
    });

    test('the music player leaves no frame callback behind', () async {
      final before = SchedulerBinding.instance.transientCallbackCount;
      AudioService.instance.configure(sound: true, music: true);
      await AudioService.instance.startMusic();
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(
        SchedulerBinding.instance.transientCallbackCount,
        before,
        reason: 'the music loop pinned a frame callback',
      );
      await AudioService.instance.stopMusic();
    });
  });
}
