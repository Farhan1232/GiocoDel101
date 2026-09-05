import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'app/bindings/backend_services.dart';
import 'app/bindings/initial_binding.dart';
import 'core/services/audio_service.dart';
import 'features/purchases/application/purchase_store.dart';
import 'core/services/supabase_bootstrap.dart';
import 'core/storage/local_storage.dart';
import 'features/online/domain/online_status.dart';
import 'core/utils/log.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The forty printed faces settle at ~32 MB decoded (one 360-px entry per
  // card, see CardFaceImage.decodeWidth). Flutter's default cache budget is
  // 100 MiB — more than a mid-range phone can spare for card art on top of
  // the Dart heap and the GPU textures. Cap it so the deck fits comfortably
  // and anything beyond that is evicted instead of accumulating.
  PaintingBinding.instance.imageCache.maximumSizeBytes = 48 << 20;

  // The bundled faces are SIL Open Font License; register the text so it is
  // discoverable from the app itself, not just from the repository.
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(const [
      'Cinzel',
    ], await rootBundle.loadString('assets/fonts/OFL-Cinzel.txt'));
    yield LicenseEntryWithLineBreaks(const [
      'Manrope',
    ], await rootBundle.loadString('assets/fonts/OFL-Manrope.txt'));
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

  // Supabase, when credentials are compiled in (--dart-define). Session
  // restore happens inside initialise, so by the time the first frame draws
  // the app already knows whether someone is signed in — no route flashes.
  final client = await SupabaseBootstrap.initialize();
  OnlineStatus.report(
    client == null
        ? BackendAvailability.notConfigured
        : BackendAvailability.ready,
  );
  final backend = client == null
      ? BackendServices.none()
      : BackendServices.supabase(client);

  // The billing plugin exists only where a store does. Everywhere else the
  // purchase layer answers "store unavailable" instead of crashing.
  final store =
      !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)
      ? InAppPurchaseStore()
      : const UnavailablePurchaseStore();

  // Registered before the first frame so the app shell can read the chosen
  // language (and everything else) while it builds.
  InitialBinding(storage, backend: backend, store: store).dependencies();
  // Audio warms up in the background: the splash must not wait on it (§24).
  unawaited(AudioService.instance.init());

  runApp(GiocoDel101App(storage: storage));
}

void unawaited(Future<void> future) {
  future.catchError((Object error) => Log.d('startup: $error'));
}
