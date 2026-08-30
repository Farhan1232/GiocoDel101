import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../online/domain/online_status.dart';
import '../domain/auth_gateway.dart';
import '../domain/auth_session.dart';
import '../../../core/utils/log.dart';

/// [AuthGateway] over Supabase Auth.
///
/// Every method performs a real request and reports exactly what came back.
/// Errors are mapped to [AuthErrorCode] by the backend's own error codes so the
/// UI never has to parse messages.
class SupabaseAuthGateway implements AuthGateway {
  SupabaseAuthGateway(this._client);

  final sb.SupabaseClient _client;

  sb.GoTrueClient get _auth => _client.auth;

  @override
  BackendAvailability get availability => OnlineStatus.availability;

  @override
  AuthSession? get current => _toSession(_auth.currentSession);

  @override
  Stream<AuthSession?> get changes => _auth.onAuthStateChange
      .map((state) => _toSession(state.session))
      .distinct();

  static AuthSession? _toSession(sb.Session? session) {
    final user = session?.user;
    if (session == null || user == null) return null;
    return AuthSession(
      userId: user.id,
      isGuest: user.isAnonymous,
      email: user.email,
    );
  }

  @override
  Future<AuthOutcome> signUp({
    required String email,
    required String password,
    required String nickname,
    required String avatarId,
  }) => _guard(() async {
    final response = await _auth.signUp(
      email: email.trim(),
      password: password,
      // Read by the database trigger that initialises the profile; the
      // trigger validates both values again server-side.
      data: {'nickname': nickname.trim(), 'avatar_id': avatarId},
    );
    final session = _toSession(response.session);
    if (session != null) return AuthSuccess(session);
    // Email confirmation is switched on: the user exists but cannot sign in
    // until the link in the email is opened.
    return AuthNeedsConfirmation(email.trim());
  });

  @override
  Future<AuthOutcome> signIn({
    required String email,
    required String password,
  }) => _guard(() async {
    final response = await _auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    final session = _toSession(response.session);
    if (session == null) return const AuthFailed(AuthErrorCode.unknown);
    return AuthSuccess(session);
  });

  @override
  Future<AuthOutcome> signInAsGuest() => _guard(() async {
    final response = await _auth.signInAnonymously();
    final session = _toSession(response.session);
    if (session == null) return const AuthFailed(AuthErrorCode.unknown);
    return AuthSuccess(session);
  });

  @override
  Future<AuthOutcome> sendPasswordReset(String email) => _guard(() async {
    await _auth.resetPasswordForEmail(email.trim());
    // There is no session to return; success is "the request was accepted".
    return const AuthNeedsConfirmation('');
  });

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on sb.AuthException catch (error) {
      // A revoked or expired refresh token still means "signed out" locally.
      Log.d('auth: signOut ${error.code ?? error.statusCode}');
    }
  }

  Future<AuthOutcome> _guard(Future<AuthOutcome> Function() call) async {
    try {
      return await call();
    } on sb.AuthException catch (error) {
      Log.d('auth: ${error.code ?? error.statusCode} ${error.message}');
      return AuthFailed(mapError(error), error.message);
    } on SocketException catch (error) {
      return AuthFailed(AuthErrorCode.network, error.message);
    } on TimeoutException {
      return const AuthFailed(AuthErrorCode.network);
    } on sb.PostgrestException catch (error) {
      // The profile trigger raised: the account was not created.
      return AuthFailed(AuthErrorCode.unknown, error.message);
    } catch (error) {
      // supabase_flutter wraps some transport errors in its own types.
      final text = error.toString();
      if (text.contains('SocketException') ||
          text.contains('ClientException') ||
          text.contains('Connection')) {
        return AuthFailed(AuthErrorCode.network, text);
      }
      return AuthFailed(AuthErrorCode.unknown, text);
    }
  }

  /// Supabase Auth error codes → what the screen can say.
  /// https://supabase.com/docs/guides/auth/debugging/error-codes
  @visibleForTesting
  static AuthErrorCode mapError(sb.AuthException error) {
    switch (error.code) {
      case 'invalid_credentials':
      case 'email_not_confirmed':
        return AuthErrorCode.invalidCredentials;
      case 'user_already_exists':
      case 'email_exists':
        return AuthErrorCode.emailTaken;
      case 'weak_password':
        return AuthErrorCode.weakPassword;
      case 'over_request_rate_limit':
      case 'over_email_send_rate_limit':
        return AuthErrorCode.rateLimited;
      case 'anonymous_provider_disabled':
        return AuthErrorCode.guestDisabled;
    }
    switch (error.statusCode) {
      case '400':
      case '401':
        return AuthErrorCode.invalidCredentials;
      case '422':
        return AuthErrorCode.emailTaken;
      case '429':
        return AuthErrorCode.rateLimited;
    }
    return AuthErrorCode.unknown;
  }
}
