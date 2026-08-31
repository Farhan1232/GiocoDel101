// Gioco del 101 — purchase verification.
//
// Flutter reports a store purchase; NOTHING it says is trusted. The flow:
//
//   request ─▶ authenticate (JWT → auth.users.id)
//           ─▶ validate shape + product allow-list          (verify.ts)
//           ─▶ verify with the store, credentials required   (providers.ts)
//           ─▶ srv_grant_entitlement: idempotent on the store transaction,
//              refuses a transaction already owned by another account
//           ─▶ respond {ok, entitlement}
//
// Without store credentials in the function's environment the answer is
// 503 `verification_unconfigured` — verification is never faked and nothing
// is ever granted on the client's word alone.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2.49.4";
import {
  entitlementFor,
  parseVerifyRequest,
  storeTransactionId,
} from "./verify.ts";
import { Unconfigured, verifyApple, verifyGoogle } from "./providers.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const admin = createClient(SUPABASE_URL, SERVICE_KEY, {
  auth: { persistSession: false },
});

function reply(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return reply(405, { error: "method" });

  // Who is asking — the entitlement lands on THIS account, never on an id
  // the client names.
  const auth = req.headers.get("Authorization") ?? "";
  const asUser = createClient(SUPABASE_URL, ANON_KEY, {
    global: { headers: { Authorization: auth } },
    auth: { persistSession: false },
  });
  const { data: userData, error: userError } = await asUser.auth.getUser();
  const userId = userData?.user?.id;
  if (userError || !userId) return reply(401, { error: "unauthorized" });

  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return reply(400, { error: "bad_request" });
  }
  const parsed = parseVerifyRequest(body);
  if ("error" in parsed) return reply(400, { error: parsed.error });
  const request = parsed.request;

  // The five-product allow-list AND the entitlement decision, both the
  // server's (verify.ts). An unknown product is refused before any store
  // call; a known one maps to exactly one entitlement key.
  const entitlement = entitlementFor(request.productId);
  if (!entitlement) {
    return reply(400, { error: "invalid_product" });
  }

  try {
    const verdict = request.platform === "android"
      ? await verifyGoogle(request)
      : await verifyApple(request);

    if (!verdict.valid) {
      console.log(
        `verify-purchase: refused user=${userId} product=${request.productId} reason=${verdict.reason}`,
      );
      return reply(402, { error: "verification_failed" });
    }

    const txn = storeTransactionId(verdict, request);
    if (!txn) return reply(402, { error: "verification_failed" });

    const { data, error } = await admin.rpc("srv_grant_entitlement", {
      p_user: userId,
      p_entitlement: entitlement,
      p_platform: request.platform,
      p_product: request.productId,
      p_store_txn: txn,
      p_original_txn: verdict.originalTransactionId ?? null,
      p_expires: verdict.expiresAt ?? null,
      p_environment: verdict.environment,
    });
    if (error) {
      console.error(`verify-purchase: grant failed ${error.message}`);
      return reply(500, { error: "internal" });
    }
    const result = data as Record<string, unknown>;
    if (result.error === "transaction_owned_elsewhere") {
      return reply(409, { error: "transaction_owned_elsewhere" });
    }
    if (result.ok !== true) {
      console.error(`verify-purchase: grant refused ${result.error}`);
      return reply(500, { error: "internal" });
    }
    return reply(200, { ok: true, entitlement: result.entitlement });
  } catch (e) {
    if (e instanceof Unconfigured) {
      // Store credentials are not provisioned yet (docs/IAP_STORE_SETUP.md).
      return reply(503, { error: "verification_unconfigured" });
    }
    console.error(`verify-purchase: ${e}`);
    return reply(500, { error: "internal" });
  }
});
