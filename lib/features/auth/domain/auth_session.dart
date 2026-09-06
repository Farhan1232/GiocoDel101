/// Who is signed in right now, as far as the app needs to know.
///
/// A value object built from the backend session. `null` everywhere it is
/// held means "logged out". A guest is a real anonymous backend user with a
/// user id of its own — never a local flag.
class AuthSession {
  const AuthSession({required this.userId, required this.isGuest, this.email});

  final String userId;
  final bool isGuest;
  final String? email;

  bool get isPermanent => !isGuest;

  @override
  bool operator ==(Object other) =>
      other is AuthSession &&
      other.userId == userId &&
      other.isGuest == isGuest &&
      other.email == email;

  @override
  int get hashCode => Object.hash(userId, isGuest, email);
}

/// Why an auth call did not succeed, in terms the UI can translate.
enum AuthErrorCode {
  /// No backend is compiled in.
  unavailable,
  invalidCredentials,
  emailTaken,
  weakPassword,
  network,
  rateLimited,

  /// Anonymous sign-ins are switched off on the server.
  guestDisabled,
  unknown,
}

/// What happened when the player asked for their account to be erased.
///
/// Deletion is not an [AuthOutcome]: it succeeds by leaving nobody signed in,
/// and its one interesting refusal — a match still in progress — has nothing
/// to do with credentials.
enum AccountDeletion {
  /// The account and everything it owned is gone.
  done,

  /// Still seated at a live online match. Deleting would pull the seat out
  /// from under the other players, so the server refuses until it ends.
  inLiveMatch,

  notSignedIn,
  network,

  /// No backend is compiled in, so there is no account to delete.
  unavailable,
  unknown,
}

/// The outcome of one auth call. Exactly one of the three.
sealed class AuthOutcome {
  const AuthOutcome();
}

class AuthSuccess extends AuthOutcome {
  const AuthSuccess(this.session);

  final AuthSession session;
}

/// The account exists but must confirm its email before it can sign in.
class AuthNeedsConfirmation extends AuthOutcome {
  const AuthNeedsConfirmation(this.email);

  final String email;
}

class AuthFailed extends AuthOutcome {
  const AuthFailed(this.code, [this.detail]);

  final AuthErrorCode code;

  /// The backend's own message, for logs. Never shown raw.
  final String? detail;
}
