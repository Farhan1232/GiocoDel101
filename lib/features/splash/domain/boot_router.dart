import '../../auth/domain/auth_session.dart';
import '../../online/domain/online_status.dart';

/// Where the splash goes once the app is ready. Pure, so it is unit-tested.
///
/// | onboarding | backend        | session   | route        |
/// |------------|----------------|-----------|--------------|
/// | not done   | any            | any       | onboarding   |
/// | done       | not configured | —         | home         |
/// | done       | configured     | none      | auth landing |
/// | done       | configured     | guest     | home         |
/// | done       | configured     | signed in | home         |
class BootRouter {
  const BootRouter._();

  static BootDestination resolve({
    required bool onboardingComplete,
    required BackendAvailability availability,
    required AuthSession? session,
  }) {
    if (!onboardingComplete) return BootDestination.onboarding;
    if (availability == BackendAvailability.notConfigured) {
      return BootDestination.home;
    }
    if (session == null) return BootDestination.authLanding;
    return BootDestination.home;
  }
}

enum BootDestination { onboarding, authLanding, home }
