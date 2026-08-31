// Unit tests for the pure verify-purchase logic. The store providers need
// real credentials and are exercised only through their Unconfigured guard;
// everything decidable without a store is decided — and tested — here.
import {
  assertEquals,
  assert,
} from "jsr:@std/assert@1";
import {
  allowedProducts,
  parseVerifyRequest,
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
    productId: "gioco101_premium",
    verificationData: "purchase-token",
    transactionId: "GPA.1234-5678",
  });
  assert("request" in android);
  const ios = parseVerifyRequest({
    platform: "ios",
    productId: "gioco101_premium",
    verificationData: "base64receipt",
  });
  assert("request" in ios);
});

Deno.test("product allow-list: default, custom, and junk filtering", () => {
  assertEquals(allowedProducts(undefined), new Set(["gioco101_premium"]));
  assertEquals(allowedProducts(""), new Set(["gioco101_premium"]));
  assertEquals(
    allowedProducts("premium_a, premium_b"),
    new Set(["premium_a", "premium_b"]),
  );
  // Ids that fail the pattern are dropped, never silently allowed.
  assertEquals(allowedProducts("ok_id, bad id!"), new Set(["ok_id"]));
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
