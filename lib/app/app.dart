import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

import '../core/utils/motion.dart';
import '../core/widgets/app_dialog.dart';
import '../features/auth/application/session_controller.dart';
import '../features/auth/domain/auth_gateway.dart';

import '../features/game/application/game_controller.dart';
import '../features/settings/application/settings_controller.dart';
import 'localization/app_strings.dart';
import '../core/services/audio_service.dart';
import '../core/storage/local_storage.dart';
import 'theme/app_theme.dart';
import 'router/app_router.dart';

/// The app shell.
///
/// Also owns the lifecycle hooks (§50): leaving the foreground pauses audio,
/// and returning resumes the music if the player wants it.
class GiocoDel101App extends StatefulWidget {
  const GiocoDel101App({super.key, required this.storage});

  final LocalStorage storage;

  @override
  State<GiocoDel101App> createState() => _GiocoDel101AppState();
}

class _GiocoDel101AppState extends State<GiocoDel101App>
    with WidgetsBindingObserver {
  Worker? _sessionWatch;
  Worker? _recoveryWatch;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (Get.isRegistered<SessionController>()) {
      final sessions = Get.find<SessionController>();
      _sessionWatch = ever<bool>(sessions.expired, (raised) {
        if (!raised) return;
        sessions.expired.value = false;
        final s = Strings.s;
        unawaited(
          AppDialog.notice(
            title: s.commonErrorTitle,
            body: s.sessionExpired,
            dismissLabel: s.gotIt,
          ),
        );
      });
      // A reset link brings the player back into the app from their mail
      // client. Whatever screen the app happened to be on, this is the one
      // thing they came to do — so it is shown, and a dead link is named
      // rather than dropped.
      _recoveryWatch = ever<PasswordRecovery?>(sessions.recovery, (event) {
        if (event == null) return;
        sessions.recovery.value = null;
        unawaited(_answerResetLink(event));
      });
    }
  }

  /// Says what became of a reset link, once there is a screen to say it on.
  ///
  /// A link opened from cold reaches the app while the splash is still
  /// running, and the splash ends by *replacing* whatever route is on top —
  /// so anything pushed before it fires is thrown away. Waiting it out is
  /// what keeps the cold-start path working; the bound is there so a stuck
  /// splash cannot hold the message forever.
  Future<void> _answerResetLink(PasswordRecovery event) async {
    for (var i = 0; i < 40 && Get.currentRoute == AppRoutes.splash; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    if (!mounted) return;
    final s = Strings.s;
    switch (event) {
      case PasswordRecovery.ready:
        await Get.toNamed<void>(AppRoutes.resetPassword);
      case PasswordRecovery.linkInvalid:
        await AppDialog.notice(
          title: s.commonErrorTitle,
          body: s.resetLinkExpiredBody,
          dismissLabel: s.gotIt,
        );
    }
  }

  @override
  void dispose() {
    _sessionWatch?.dispose();
    _recoveryWatch?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        AudioService.instance.pauseAll();
        // §49/§50 — flush the match immediately; a backgrounded app may not
        // get another chance to write.
        if (Get.isRegistered<GameController>()) {
          final game = Get.find<GameController>();
          game.persistNow();
          // §W — the bots must not play on while nobody is watching.
          game.pause();
        }
      case AppLifecycleState.resumed:
        AudioService.instance.resumeMusic();
      case AppLifecycleState.inactive:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.overlayStyle,
      // §9 — the whole tree rebuilds when the player switches language.
      child: Obx(
        () => GetMaterialApp(
          title: Strings.s.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.build(),
          locale: settings.locale,
          fallbackLocale: Strings.fallback,
          supportedLocales: Strings.supported,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          localeResolutionCallback: (locale, supported) =>
              Strings.resolve(locale),
          initialRoute: AppRoutes.splash,
          getPages: AppPages.pages,
          defaultTransition: Transition.fadeIn,
          builder: (context, child) {
            // §47/§48 — respect the platform text scale, but keep the table
            // readable by refusing extremes that would clip the hand.
            final media = MediaQuery.of(context);
            Motion.systemReduceMotion = media.disableAnimations;
            final scale = media.textScaler.scale(14) / 14;
            return MediaQuery(
              data: media.copyWith(
                textScaler: TextScaler.linear(scale.clamp(0.85, 1.30)),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
        ),
      ),
    );
  }
}
