// Does the Play service account have what purchase verification needs?
//
//   deno run --allow-read --allow-net tool/play_access_check.ts <key.json>
//
// It signs the same JWT `supabase/functions/verify-purchase/providers.ts`
// signs, with the same Web Crypto calls, and asks Play about a deliberately
// fake purchase token. What comes back separates the two failures that look
// identical from inside the app:
//
//   400/404  Play knows us and rejected the token   → verification IS live
//   401/403  Play refused the service account       → the console grant is
//                                                     missing or not yet
//                                                     propagated
//
// Nothing is purchased, granted or written. The key never leaves this machine.
const PACKAGE = Deno.env.get("ANDROID_PACKAGE_NAME") ??
  "it.giocodel101.gioco_del_101";
const PRODUCT = Deno.env.get("PRODUCT_ID") ?? "gioco101_table_gold";

function b64url(data: ArrayBuffer | string): string {
  const bytes = typeof data === "string"
    ? new TextEncoder().encode(data)
    : new Uint8Array(data);
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function pemToDer(pem: string): ArrayBuffer {
  const raw = atob(
    pem.replace(/-----BEGIN PRIVATE KEY-----/, "")
      .replace(/-----END PRIVATE KEY-----/, "").replace(/\s+/g, ""),
  );
  const bytes = new Uint8Array(raw.length);
  for (let i = 0; i < raw.length; i++) bytes[i] = raw.charCodeAt(i);
  return bytes.buffer;
}

const path = Deno.args[0];
if (!path) {
  console.error("usage: play_access_check.ts <service-account-key.json>");
  Deno.exit(2);
}
const account = JSON.parse(await Deno.readTextFile(path));
console.log(`service account : ${account.client_email}`);
console.log(`package         : ${PACKAGE}`);

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

const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
  method: "POST",
  headers: { "Content-Type": "application/x-www-form-urlencoded" },
  body: new URLSearchParams({
    grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
    assertion: `${header}.${claims}.${b64url(signature)}`,
  }),
});
if (!tokenRes.ok) {
  console.log(`\n✗ the key itself is not accepted by Google (${tokenRes.status})`);
  console.log("  the JSON is wrong, revoked, or for a deleted account.");
  Deno.exit(1);
}
console.log("✓ Google accepted the key");

const accessToken = (await tokenRes.json()).access_token as string;
const res = await fetch(
  "https://androidpublisher.googleapis.com/androidpublisher/v3/applications/" +
    `${encodeURIComponent(PACKAGE)}/purchases/products/` +
    `${encodeURIComponent(PRODUCT)}/tokens/not-a-real-purchase-token`,
  { headers: { Authorization: `Bearer ${accessToken}` } },
);

if (res.status === 400 || res.status === 404) {
  console.log(`✓ Play answered ${res.status} for a fake token`);
  console.log("\nVERIFICATION IS LIVE — real purchases will be granted.");
  Deno.exit(0);
}
if (res.status === 401 || res.status === 403) {
  console.log(`✗ Play refused the service account (${res.status})`);
  console.log(
    "\nNOT LIVE YET. In Play Console → Users and permissions → this service\n" +
      "account → App permissions for this app, tick\n" +
      '  "View financial data, orders, and cancellation survey responses"\n' +
      "then wait a few minutes (Google can take up to 24h) and run this again.",
  );
  Deno.exit(1);
}
console.log(`? Play answered ${res.status}: ${(await res.text()).slice(0, 300)}`);
Deno.exit(1);
