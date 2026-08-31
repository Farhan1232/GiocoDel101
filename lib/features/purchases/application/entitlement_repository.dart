import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../domain/entitlement.dart';

/// The server-held truth about premium.
///
/// Reads come straight off `public.user_entitlements` (RLS lets a player see
/// only their own row). Writes NEVER happen from here: a purchase is sent to
/// the `verify-purchase` Edge Function, which checks it with the store and
/// grants the entitlement with the service role. A modified APK talking to
/// this API can therefore ask, but not grant (docs/SECURITY.md).
abstract class EntitlementRepository {
  /// The player's entitlement, or null when they never bought anything.
  Future<PremiumEntitlement?> status();

  /// Hands one store purchase to the server for verification. Returns the
  /// resulting entitlement on success; throws [PurchaseException].
  /// Idempotent: re-sending the same store transaction re-answers the same
  /// grant instead of failing or granting twice.
  Future<PremiumEntitlement> verify({
    required String platform,
    required String productId,
    required String verificationData,
    String? transactionId,
  });
}

class NoBackendEntitlementRepository implements EntitlementRepository {
  const NoBackendEntitlementRepository();

  @override
  Future<PremiumEntitlement?> status() async => null;

  @override
  Future<PremiumEntitlement> verify({
    required String platform,
    required String productId,
    required String verificationData,
    String? transactionId,
  }) async =>
      throw const PurchaseException(PurchaseError.verificationUnavailable);
}

class SupabaseEntitlementRepository implements EntitlementRepository {
  SupabaseEntitlementRepository(this._client);

  final sb.SupabaseClient _client;

  @override
  Future<PremiumEntitlement?> status() async {
    if (_client.auth.currentUser == null) return null;
    try {
      final row = await _client
          .from('user_entitlements')
          .select()
          .maybeSingle();
      return PremiumEntitlement.fromRow(row);
    } on sb.PostgrestException catch (e) {
      throw PurchaseException(PurchaseError.network, e.message);
    }
  }

  @override
  Future<PremiumEntitlement> verify({
    required String platform,
    required String productId,
    required String verificationData,
    String? transactionId,
  }) async {
    if (_client.auth.currentUser == null) {
      throw const PurchaseException(PurchaseError.notSignedIn);
    }
    try {
      final res = await _client.functions.invoke(
        'verify-purchase',
        body: {
          'platform': platform,
          'productId': productId,
          'verificationData': verificationData,
          'transactionId': ?transactionId,
        },
      );
      final data = res.data;
      if (data is Map && data['ok'] == true) {
        final entitlement = PremiumEntitlement.fromRow(
          (data['entitlement'] as Map?)?.cast<String, dynamic>(),
        );
        if (entitlement != null) return entitlement;
      }
      throw const PurchaseException(PurchaseError.unknown, 'empty reply');
    } on sb.FunctionException catch (e) {
      final d = e.details;
      final code = d is Map ? d['error'] as String? : null;
      throw PurchaseException(switch (code) {
        'verification_unconfigured' => PurchaseError.verificationUnavailable,
        'verification_failed' => PurchaseError.verificationFailed,
        'transaction_owned_elsewhere' => PurchaseError.alreadyOwnedElsewhere,
        'invalid_product' => PurchaseError.productMissing,
        _ => switch (e.status) {
          401 => PurchaseError.notSignedIn,
          _ => PurchaseError.verificationFailed,
        },
      }, code ?? e.reasonPhrase);
    } on PurchaseException {
      rethrow;
    } catch (e) {
      throw PurchaseException(PurchaseError.network, e.toString());
    }
  }
}
