/// Field validation for the auth forms.
///
/// Pure functions returning a message key's *value*, so both the widgets and
/// the tests agree on what counts as valid. No network, no persistence.
class AuthValidators {
  const AuthValidators._();

  static const int minPasswordLength = 8;
  static const int minNicknameLength = 3;
  static const int maxNicknameLength = 16;

  /// Deliberately permissive: it rejects the obviously malformed and leaves
  /// the rest to the backend, which is the only thing that can really know.
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s.]+\.[^@\s]{2,}$');

  static bool isEmailValid(String value) => _email.hasMatch(value.trim());

  static bool isPasswordValid(String value) =>
      value.length >= minPasswordLength;

  static bool isNicknameValid(String value) {
    final trimmed = value.trim();
    return trimmed.length >= minNicknameLength &&
        trimmed.length <= maxNicknameLength;
  }
}

/// What the auth form is doing right now.
enum AuthFormStatus { idle, submitting, unavailable }
