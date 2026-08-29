import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../features/game/application/game_controller.dart';
import 'localization/app_strings.dart';
import '../core/services/audio_service.dart';
import '../core/storage/local_storage.dart';
import 'theme/app_theme.dart';
import 'bindings/initial_binding.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
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
          Get.find<GameController>().persistNow();
        }
      case AppLifecycleState.resumed:
        AudioService.instance.resumeMusic();
      case AppLifecycleState.inactive:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.overlayStyle,
      child: GetMaterialApp(
        title: Strings.s.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(),
        initialBinding: InitialBinding(widget.storage),
        initialRoute: AppRoutes.splash,
        getPages: AppPages.pages,
        defaultTransition: Transition.fadeIn,
        builder: (context, child) {
          // §47/§48 — respect the platform text scale, but keep the table
          // readable by refusing extremes that would clip the hand.
          final media = MediaQuery.of(context);
          final scale = media.textScaler.scale(14) / 14;
          return MediaQuery(
            data: media.copyWith(
              textScaler: TextScaler.linear(scale.clamp(0.85, 1.30)),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
