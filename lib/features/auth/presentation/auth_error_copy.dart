import '../../../app/localization/app_strings.dart';
import '../domain/auth_session.dart';

/// Localised copy for an [AuthErrorCode]. Never shows the backend's text.
extension AuthErrorCopy on AppLocalizations {
  String authError(AuthErrorCode code) => switch (code) {
    AuthErrorCode.unavailable => authBackendPending,
    AuthErrorCode.invalidCredentials => authErrorInvalidCredentials,
    AuthErrorCode.emailTaken => authErrorEmailTaken,
    AuthErrorCode.weakPassword => authErrorWeakPassword,
    AuthErrorCode.network => authErrorNetwork,
    AuthErrorCode.rateLimited => authErrorRateLimited,
    AuthErrorCode.guestDisabled => authErrorGuestDisabled,
    AuthErrorCode.unknown => authErrorUnknown,
  };
}
