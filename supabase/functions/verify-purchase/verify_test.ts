// Unit tests for the pure verify-purchase logic. The store providers need
// real credentials and are exercised only through their Unconfigured guard;
// everything decidable without a store is decided — and tested — here.
import {
  assertEquals,
  assert,
} from "jsr:@std/assert@1";
import {
  entitlementFor,
  parseVerifyRequest,
  PRODUCT_ENTITLEMENTS,
  storeTransactionId,
  type StoreVerdict,
  type VerifyRequest,
} from "./verify.ts";
import { Unconfigured, verifyApple, verifyGoogle } from "./providers.ts";

Deno.test("request validation refuses every malformed shape", () => {
  const bad = [
    null,
    "string",
    {},
    { platform: "windows", productId: "p", verificationData: "x" },
    { platform: "android", productId: "", verificationData: "x" },
    { platform: "android", productId: "no spaces!", verificationData: "x" },
    { platform: "android", productId: "p" },
    { platform: "android", productId: "p", verificationData: "" },
    {
      platform: "android",
      productId: "p",
      verificationData: "x".repeat(64 * 1024 + 1),
    },
    {
      platform: "ios",
      productId: "p",
      verificationData: "x",
      transactionId: "t".repeat(257),
    },
  ];
  for (const body of bad) {
    const parsed = parseVerifyRequest(body);
    assert("error" in parsed, `accepted: ${JSON.stringify(body)?.slice(0, 60)}`);
  }
});

Deno.test("request validation accepts the two real shapes", () => {
  const android = parseVerifyRequest({
    platform: "android",
    productId: "gioco101_table_gold",
    verificationData: "purchase-token",
    transactionId: "GPA.1234-5678",
  });
  assert("request" in android);
  const ios = parseVerifyRequest({
    platform: "ios",
    productId: "gioco101_table_gold",
    verificationData: "base64receipt",
  });
  assert("request" in ios);
});

Deno.test("the allow-list is exactly the five cosmetics, each with its own entitlement", () => {
  assertEquals(PRODUCT_ENTITLEMENTS, {
    gioco101_table_gold: "table.gold",
    gioco101_table_classic: "table.classic",
    gioco101_deck_special: "deck.special",
    gioco101_cardback_gold: "cardback.gold",
    gioco101_gadget_01: "gadget.01",
  });
  // Five products, five DISTINCT entitlements — no shared premium flag.
  assertEquals(
    new Set(Object.values(PRODUCT_ENTITLEMENTS)).size,
    5,
  );
  for (const [product, entitlement] of Object.entries(PRODUCT_ENTITLEMENTS)) {
    assertEquals(entitlementFor(product), entitlement);
  }
});

Deno.test("anything off the allow-list maps to no entitlement at all", () => {
  for (const id of [
    "gioco101_premium", // the retired session-7 placeholder
    "gioco101_table_gold2",
    "toString",
    "hasOwnProperty", // prototype probing must not leak a value
    "",
  ]) {
    assertEquals(entitlementFor(id), undefined, id);
  }
});

Deno.test("the store's transaction id outranks the client's", () => {
  const request: VerifyRequest = {
    platform: "android",
    productId: "p",
    verificationData: "v",
    transactionId: "client-claims-this",
  };
  const verdict: StoreVerdict = {
    valid: true,
    transactionId: "GPA.store-says-this",
    environment: "production",
  };
  assertEquals(storeTransactionId(verdict, request), "GPA.store-says-this");
  // Only when the store answered without one does the client's id stand in.
  assertEquals(
    storeTransactionId({ valid: true, environment: "production" }, request),
    "client-claims-this",
  );
  assertEquals(
    storeTransactionId({ valid: true, environment: "production" }, {
      ...request,
      transactionId: undefined,
    }),
    undefined,
  );
});

Deno.test("without credentials both providers refuse — never fake-verify", async () => {
  // The test environment has no store secrets; the providers must say so
  // rather than answering anything about the purchase.
  const request: VerifyRequest = {
    platform: "android",
    productId: "p",
    verificationData: "v",
  };
  let googleRefused = false;
  try {
    await verifyGoogle(request);
  } catch (e) {
    googleRefused = e instanceof Unconfigured;
  }
  assert(googleRefused, "google verifier ran without credentials");

  let appleRefused = false;
  try {
    await verifyApple({ ...request, platform: "ios" });
  } catch (e) {
    appleRefused = e instanceof Unconfigured;
  }
  assert(appleRefused, "apple verifier ran without credentials");
});
