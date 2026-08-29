import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'core/services/audio_service.dart';
import 'core/storage/local_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The bundled faces are SIL Open Font License; register the text so it is
  // discoverable from the app itself, not just from the repository.
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(
      const ['Cinzel', 'Manrope'],
      await rootBundle.loadString('assets/fonts/OFL.txt'),
    );
  });

  // §27/§47 — portrait-first on phones, where the fan and the felt are tuned
  // for a tall frame. Tablets are big enough to rotate freely.
  final view = WidgetsBinding.instance.platformDispatcher.views.first;
  final shortestSide = view.physicalSize.shortestSide / view.devicePixelRatio;
  await SystemChrome.setPreferredOrientations(
    shortestSide >= 600
        ? DeviceOrientation.values
        : const [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
  );
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final storage = await LocalStorage.open();
  // Audio warms up in the background: the splash must not wait on it (§24).
  unawaited(AudioService.instance.init());

  runApp(GiocoDel101App(storage: storage));
}

void unawaited(Future<void> future) {
  future.catchError((Object error) => debugPrint('startup: $error'));
}
