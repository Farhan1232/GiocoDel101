// The store verifiers. Each returns a StoreVerdict or throws Unconfigured
// when its credentials are absent — verification is NEVER faked: without
// credentials the function answers `verification_unconfigured` and grants
// nothing (docs/IAP_STORE_SETUP.md lists what to provision).
//
// Secrets live in Edge Function environment variables only:
//   GOOGLE_SERVICE_ACCOUNT_JSON  the Play service account key (JSON, verbatim)
//   ANDROID_PACKAGE_NAME         e.g. com.example.giocodel101
//   APPLE_BUNDLE_ID              the iOS bundle id
//   APPLE_SHARED_SECRET          App Store shared secret (subscriptions)
//
// The product allow-list is code, not configuration: the five cosmetic ids
// and their entitlements live in verify.ts (PRODUCT_ENTITLEMENTS).

import type { StoreVerdict, VerifyRequest } from "./verify.ts";

export class Unconfigured extends Error {}

// ---------------------------------------------------------------- Google Play

interface ServiceAccount {
  client_email: string;
  private_key: string;
}

function pemToDer(pem: string): ArrayBuffer {
  const b64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s+/g, "");
  const raw = atob(b64);
  const bytes = new Uint8Array(raw.length);
  for (let i = 0; i < raw.length; i++) bytes[i] = raw.charCodeAt(i);
  return bytes.buffer;
}

function b64url(data: ArrayBuffer | string): string {
  const bytes = typeof data === "string"
    ? new TextEncoder().encode(data)
    : new Uint8Array(data);
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

async function googleAccessToken(account: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = b64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claims = b64url(JSON.stringify({
    iss: account.client_email,
    scope: "https://www.googleapis.com/auth/androidpublisher",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  }));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToDer(account.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(`${header}.${claims}`),
  );
  const jwt = `${header}.${claims}.${b64url(signature)}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  if (!res.ok) throw new Error(`google token: ${res.status}`);
  const data = await res.json();
  return data.access_token as string;
}

/** One-time (in-app) products; a subscription would use purchases.subscriptionsv2. */
export async function verifyGoogle(req: VerifyRequest): Promise<StoreVerdict> {
  const accountJson = Deno.env.get("GOOGLE_SERVICE_ACCOUNT_JSON");
  const packageName = Deno.env.get("ANDROID_PACKAGE_NAME");
  if (!accountJson || !packageName) throw new Unconfigured();

  const account = JSON.parse(accountJson) as ServiceAccount;
  const token = await googleAccessToken(account);
  const url = "https://androidpublisher.googleapis.com/androidpublisher/v3" +
    `/applications/${encodeURIComponent(packageName)}` +
    `/purchases/products/${encodeURIComponent(req.productId)}` +
    `/tokens/${encodeURIComponent(req.verificationData)}`;
  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (res.status === 404 || res.status === 400) {
    return {
      valid: false,
      environment: "production",
      reason: `google ${res.status}`,
    };
  }
  if (!res.ok) throw new Error(`google verify: ${res.status}`);
  const p = await res.json();
  // purchaseState: 0 purchased, 1 canceled, 2 pending.
  if (p.purchaseState !== 0) {
    return {
      valid: false,
      environment: p.purchaseType === 0 ? "sandbox" : "production",
      reason: `purchaseState ${p.purchaseState}`,
    };
  }
  return {
    valid: true,
    transactionId: (p.orderId as string | undefined) ?? undefined,
    environment: p.purchaseType === 0 ? "sandbox" : "production",
  };
}

// ------------------------------------------------------------- App Store

/**
 * Receipt validation via /verifyReceipt (functional for one-time products;
 * the App Store Server API is the modern replacement once the client has an
 * App Store Connect API key — noted in docs/IAP_STORE_SETUP.md).
 */
export async function verifyApple(req: VerifyRequest): Promise<StoreVerdict> {
  const bundleId = Deno.env.get("APPLE_BUNDLE_ID");
  if (!bundleId) throw new Unconfigured();
  const sharedSecret = Deno.env.get("APPLE_SHARED_SECRET");

  const body: Record<string, unknown> = {
    "receipt-data": req.verificationData,
    "exclude-old-transactions": true,
  };
  if (sharedSecret) body.password = sharedSecret;

  let data = await postReceipt(
    "https://buy.itunes.apple.com/verifyReceipt",
    body,
  );
  if (data.status === 21007) {
    // A sandbox receipt sent to production: Apple's documented retry.
    data = await postReceipt(
      "https://sandbox.itunes.apple.com/verifyReceipt",
      body,
    );
  }
  const environment = data.environment === "Sandbox"
    ? "sandbox" as const
    : "production" as const;
  if (data.status !== 0) {
    return { valid: false, environment, reason: `apple ${data.status}` };
  }
  const receipt = data.receipt as Record<string, unknown> | undefined;
  if (!receipt || receipt.bundle_id !== bundleId) {
    return { valid: false, environment, reason: "bundle mismatch" };
  }
  const inApp = (receipt.in_app as Record<string, unknown>[] | undefined) ?? [];
  const latest = (data.latest_receipt_info as
    | Record<string, unknown>[]
    | undefined) ?? [];
  const entry = [...latest, ...inApp].find(
    (t) => t.product_id === req.productId,
  );
  if (!entry) {
    return { valid: false, environment, reason: "product not in receipt" };
  }
  const expiresMs = entry.expires_date_ms as string | undefined;
  return {
    valid: true,
    transactionId: entry.transaction_id as string | undefined,
    originalTransactionId: entry.original_transaction_id as string | undefined,
    expiresAt: expiresMs
      ? new Date(Number(expiresMs)).toISOString()
      : undefined,
    environment,
  };
}

async function postReceipt(
  url: string,
  body: Record<string, unknown>,
): Promise<Record<string, unknown>> {
  const res = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  if (!res.ok) throw new Error(`apple verify: ${res.status}`);
  return await res.json() as Record<string, unknown>;
}
