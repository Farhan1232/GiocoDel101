// Pure request/decision logic for the verify-purchase function, kept free of
// I/O so it is testable without store credentials (verify_test.ts).

export type Platform = "android" | "ios";

export interface VerifyRequest {
  platform: Platform;
  productId: string;
  /** Android: the purchase token. iOS: the base64 receipt. Opaque here. */
  verificationData: string;
  transactionId?: string;
}

/** What a store verifier reports back for one purchase. */
export interface StoreVerdict {
  valid: boolean;
  /** The store's canonical transaction id — the idempotency key. */
  transactionId?: string;
  originalTransactionId?: string;
  /** Null/undefined = non-expiring (non-consumable). */
  expiresAt?: string;
  environment: "production" | "sandbox";
  reason?: string;
}

const PRODUCT_ID = /^[a-z0-9_.]{1,128}$/i;
const MAX_VERIFICATION_DATA = 64 * 1024; // an iOS receipt can be tens of KB

export function parseVerifyRequest(
  body: unknown,
): { request: VerifyRequest } | { error: string } {
  if (typeof body !== "object" || body === null) {
    return { error: "bad_request" };
  }
  const b = body as Record<string, unknown>;
  const platform = b.platform;
  if (platform !== "android" && platform !== "ios") {
    return { error: "bad_platform" };
  }
  const productId = b.productId;
  if (typeof productId !== "string" || !PRODUCT_ID.test(productId)) {
    return { error: "invalid_product" };
  }
  const verificationData = b.verificationData;
  if (
    typeof verificationData !== "string" ||
    verificationData.length === 0 ||
    verificationData.length > MAX_VERIFICATION_DATA
  ) {
    return { error: "bad_verification_data" };
  }
  const transactionId = b.transactionId;
  if (
    transactionId !== undefined &&
    (typeof transactionId !== "string" || transactionId.length > 256)
  ) {
    return { error: "bad_transaction_id" };
  }
  return {
    request: { platform, productId, verificationData, transactionId },
  };
}

/**
 * The products this backend will ever grant, each mapped to the entitlement
 * it buys. Anything else is refused before any store call — a client cannot
 * probe with arbitrary ids, and the entitlement key is ALWAYS the server's
 * choice, never the client's.
 *
 * These five are the canonical cosmetic non-consumables
 * (docs/FINAL_IAP_PRODUCT_IDS.md); the same ids must exist in Google Play
 * Console and App Store Connect. One product = one permanent entitlement;
 * there is no global premium flag.
 */
export const PRODUCT_ENTITLEMENTS: Readonly<Record<string, string>> = {
  gioco101_table_gold: "table.gold",
  gioco101_table_classic: "table.classic",
  gioco101_deck_special: "deck.special",
  gioco101_cardback_gold: "cardback.gold",
  gioco101_gadget_01: "gadget.01",
};

/** The entitlement a product grants, or undefined for anything unknown. */
export function entitlementFor(productId: string): string | undefined {
  return Object.hasOwn(PRODUCT_ENTITLEMENTS, productId)
    ? PRODUCT_ENTITLEMENTS[productId]
    : undefined;
}

/** The idempotency key a verdict settles on, with a safe fallback. */
export function storeTransactionId(
  verdict: StoreVerdict,
  request: VerifyRequest,
): string | undefined {
  return verdict.transactionId ?? request.transactionId ?? undefined;
}
