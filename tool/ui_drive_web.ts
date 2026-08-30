// Drives the REAL Flutter app (web build) in headless Chrome as one player,
// while an independent supabase-js client plays the other seat, against
// the remote development project. Screenshots land in the output dir.
//
//   flutter build web --dart-define-from-file=env/supabase.dev.json
//   (cd build/web && python3 -m http.server 8787 --bind 127.0.0.1 &)
//   deno run -A tool/ui_drive_web.ts <outDir> [appUrl]
//
// The Chrome player is driven through Flutter's semantics tree (the same
// nodes a screen reader uses), so it can only press what the UI exposes:
// it signs in, creates a room, starts the match, and then plays every turn
// with "Pesca" / "Passa" / "Prendi +N" — never a card, since cards have no
// semantics label. The guest plays cards with the compiled engine.
/// <reference lib="dom" />
import puppeteer from "npm:puppeteer-core@23";
import { createClient } from "npm:@supabase/supabase-js@2.49.4";
import { engineSync } from "../supabase/functions/match/engine.ts";

const OUT = Deno.args[0] ?? ".";
const APP = Deno.args[1] ?? "http://127.0.0.1:8787/";
const URL = "https://fnyllrjchbqfrzezfeso.supabase.co";
const KEY = "sb_publishable_xO6ZTjeNdRcm2GqLHD9lUw_QjhNlfGe";
const HOST_EMAIL = "s4-ui-host@example.com";
// The dev-project test account's password comes from the environment; a
// credential, even a throw-away one, does not live in the repository.
const HOST_PASSWORD = Deno.env.get("UI_HOST_PASSWORD") ?? "";
if (!HOST_PASSWORD) {
  console.error("UI_HOST_PASSWORD is required (the s4-ui-host test account)");
  Deno.exit(2);
}

let failures = 0;
function check(name: string, ok: boolean, detail?: unknown) {
  console.log(`${ok ? "PASS" : "FAIL"}  ${name}${detail === undefined ? "" : `  (${typeof detail === "string" ? detail : JSON.stringify(detail)})`}`);
  if (!ok) failures++;
}
const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

// ------------------------------------------------------------- Chrome side
const browser = await puppeteer.launch({
  executablePath: "/usr/bin/google-chrome",
  headless: true,
  args: ["--no-sandbox", "--window-size=420,900", "--autoplay-policy=no-user-gesture-required"],
});
const page = await browser.newPage();
await page.setViewport({ width: 420, height: 900, deviceScaleFactor: 1 });
const consoleLog: string[] = [];
page.on("console", (m) => {
  const t = m.text();
  if (/WebGL|GL Driver|AudioContext|DevTools/.test(t)) return;
  consoleLog.push(`[${m.type()}] ${t.slice(0, 400)}`);
  if (/exception|error/i.test(t)) console.log("[app]", t.slice(0, 200));
});
page.on("pageerror", (e) => consoleLog.push(`[pageerror] ${e.message}\n${(e.stack ?? "").split("\n").slice(0, 12).join("\n")}`));
const flushConsole = () => Deno.writeTextFileSync(`${OUT}/console.log`, consoleLog.join("\n"));
setInterval(flushConsole, 5000);

type Node = { i: number; role: string; tappable: boolean; label: string; text: string; disabled: boolean };
async function nodes(): Promise<Node[]> {
  return await page.evaluate(() => {
    const out: any[] = [];
    document.querySelectorAll("flt-semantics").forEach((e: any, i: number) => {
      out.push({
        i,
        role: e.getAttribute("role") || "",
        tappable: e.hasAttribute("flt-tappable"),
        label: e.getAttribute("aria-label") || "",
        text: (e.textContent || "").replace(/\s+/g, " ").trim(),
        disabled: e.getAttribute("aria-disabled") === "true",
      });
    });
    return out;
  });
}
async function buttons(): Promise<Node[]> {
  return (await nodes()).filter((n) => n.role === "button" || n.tappable);
}
async function findButton(re: RegExp): Promise<Node | undefined> {
  const bs = await buttons();
  return bs.filter((b) => re.test(b.label) || re.test(b.text)).pop();
}
/** A real pointer click at the node's centre: reaches the canvas gesture
 *  layer even where the semantics node itself has no tap action. */
async function clickNode(i: number) {
  const r = await page.evaluate((idx: number) => {
    const el = document.querySelectorAll("flt-semantics")[idx] as any;
    if (!el) return null;
    const b = el.getBoundingClientRect();
    return { x: b.x + b.width / 2, y: b.y + b.height / 2, w: b.width, h: b.height };
  }, i);
  if (!r || r.w === 0 || r.h === 0) {
    await page.evaluate((idx: number) => (document.querySelectorAll("flt-semantics")[idx] as any)?.click(), i);
    return;
  }
  await page.mouse.click(r.x, r.y);
}
async function clickButton(re: RegExp, label = re.source, timeoutMs = 20000): Promise<boolean> {
  const t0 = Date.now();
  while (Date.now() - t0 < timeoutMs) {
    const b = await findButton(re);
    if (b && !b.disabled) {
      await clickNode(b.i);
      await sleep(900);
      return true;
    }
    await sleep(500);
  }
  console.log(`   (button ${label} not found/enabled)`);
  return false;
}
async function hasText(re: RegExp): Promise<boolean> {
  return (await nodes()).some((n) => re.test(n.text) || re.test(n.label));
}
async function waitText(re: RegExp, timeoutMs = 20000): Promise<boolean> {
  const t0 = Date.now();
  while (Date.now() - t0 < timeoutMs) {
    if (await hasText(re)) return true;
    await sleep(500);
  }
  return false;
}
async function shot(name: string) {
  await page.screenshot({ path: `${OUT}/${name}.png` });
}

await page.goto(APP, { waitUntil: "networkidle2", timeout: 120000 });
await sleep(5000);
const ph = await page.$("flt-semantics-placeholder");
if (ph) {
  await ph.evaluate((e: any) => e.click());
  await sleep(3000);
}
check("Flutter web app booted in Chrome and exposed its semantics tree", (await nodes()).length > 0);
if (await findButton(/^Salta$/)) await clickButton(/^Salta$/);
await sleep(1000);

// Sign in as the host.
check("account landing shown (Accedi / Registrati / Ospite)", !!(await findButton(/^Accedi/)) && !!(await findButton(/OSPITE/)));
await clickButton(/^Accedi/, "Accedi");
await sleep(1500);
/** Visible text fields, top to bottom, with their on-screen rectangles. */
async function textFields(): Promise<Array<{ x: number; y: number; label: string }>> {
  return await page.evaluate(() =>
    Array.from(document.querySelectorAll("input, textarea"))
      .map((e: any) => {
        const r = e.getBoundingClientRect();
        const label = e.getAttribute("aria-label") || e.parentElement?.getAttribute("aria-label") || "";
        return { x: r.x + r.width / 2, y: r.y + r.height / 2, w: r.width, h: r.height, label };
      })
      .filter((f) => f.w > 40 && f.h > 10)
      .sort((a, b) => a.y - b.y)
      .map(({ x, y, label }) => ({ x, y, label }))
  );
}
async function fillField(which: number | RegExp, text: string) {
  const fields = await textFields();
  const f = typeof which === "number" ? fields[which] : fields.find((x) => which.test(x.label));
  if (!f) throw new Error(`no text field ${which} (have ${JSON.stringify(fields)})`);
  await page.mouse.click(f.x, f.y);
  await sleep(400);
  await page.keyboard.down("Control");
  await page.keyboard.press("KeyA");
  await page.keyboard.up("Control");
  await page.keyboard.press("Backspace");
  await page.keyboard.type(text, { delay: 15 });
  await sleep(300);
}
const fields = await textFields();
check("login form has two visible text fields", fields.length >= 2, fields.map((f) => f.label));
await fillField(/^Email/i, HOST_EMAIL);
await fillField(/^Password/i, HOST_PASSWORD);
await shot("ui_10_login_filled");
const loginBtns = (await buttons()).filter((b) => /accedi/i.test(b.label) || /accedi/i.test(b.text));
await clickNode(loginBtns[loginBtns.length - 1].i);
const home = await waitText(/GIOCA ONLINE/, 30000);
check("signed in through the real login screen → Home", home);
await shot("ui_11_home");
await sleep(2000);
console.log("   Home offers Rientra nella partita:", !!(await findButton(/Rientra/i)));

// Create a 2-player private room through the UI.
await clickButton(/GIOCA ONLINE/);
await shot("ui_12a_online_hub");
await clickButton(/CREA STANZA/);
await sleep(1000);
await shot("ui_12b_create_room");
// Table size segmented control: pick "2".
const two = (await nodes()).filter((n) => n.text === "2" || n.label === "2");
if (two.length) await clickNode(two[0].i);
await sleep(500);
await clickButton(/CREA LA STANZA/);
const inLobby = await waitText(/Codice stanza/i, 30000);
check("room created on the server; lobby shows a real code", inLobby);
await sleep(1500);
const codeNode = (await nodes()).find((n) => /^[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{6}$/.test(n.text));
const code = codeNode?.text ?? "";
check("six-character room code read from the lobby", code.length === 6, code);
await shot("ui_12_lobby_waiting");

// ------------------------------------------------------------ guest side
// Fill every remaining seat with an independent authenticated client.
type Guest = { client: any; id: string; name: string };
const guests: Guest[] = [];
const guestByPid = new Map<string, Guest>();
let roomId = "";
for (let g = 1; g <= 3; g++) {
  const client = createClient(URL, KEY, { auth: { persistSession: false, autoRefreshToken: true } });
  const email = `s4-ui-guest-${Date.now()}-${g}@example.com`;
  const su = await client.auth.signUp({ email, password: "UiGuest-2026!", options: { data: { nickname: `Ospite UI ${g}`, avatar_id: "lucia" } } });
  if (!su.data.session) { check(`guest ${g} signed up`, false, su.error?.message); break; }
  const joined = await client.rpc("join_room", { p_code: code });
  if (joined.error) {
    if (/room_full/.test(joined.error.message)) { await client.auth.signOut(); break; }
    check(`guest ${g} joined by code`, false, joined.error.message);
    break;
  }
  roomId = joined.data.id as string;
  const ready = await client.rpc("set_ready", { p_room_id: roomId, p_ready: true });
  check(`independent guest ${g} signed up, joined by code and set ready`, !ready.error, ready.error?.message);
  guests.push({ client, id: su.data.user!.id, name: `Ospite UI ${g}` });
}
check("every free seat was filled by an independent client", guests.length >= 1, guests.length);
const guest = guests[0].client;
const su = { data: { user: { id: guests[0].id } } };
await sleep(2500);
const seatShown = await waitText(new RegExp(guests[guests.length - 1].name), 15000);
check("host's lobby shows the guests' seats via Realtime/poll", seatShown);
await shot("ui_13_lobby_full");

// Host starts.
const started = await clickButton(/INIZIA LA PARTITA/, "INIZIA", 30000);
check("host pressed Start", started);
const onTable = await waitText(/Round/, 45000);
check("table screen reached (Round 1)", onTable);
await sleep(2000);
await shot("ui_20_table_round1");

const { data: roomRow } = await guest.from("rooms").select("match_id, host_id").eq("id", roomId).single();
const hostUserId = roomRow?.host_id as string;
const matchId = roomRow?.match_id as string;
check("room points at the dealt match", !!matchId, matchId);

// ------------------------------------------------------------- the game
const engine = engineSync();
let guestPid = "";
let hostPid = "";
let guestActions = 0, hostTurns = 0, rounds = 1, resultSheets = 0;
let lastShot = 0;
const t0 = Date.now();
let finished = false;
for (let step = 0; step < 1200 && Date.now() - t0 < 25 * 60_000; step++) {
  const snap = await guest.rpc("match_snapshot", { p_match_id: matchId });
  if (snap.error) {
    console.log("snapshot error", snap.error.message);
    await sleep(1000);
    continue;
  }
  const s = snap.data as any;
  if (!guestPid) {
    guestPid = s.players.find((p: any) => p.userId === su.data.user!.id).enginePlayerId;
    hostPid = s.players.find((p: any) => p.userId !== su.data.user!.id).enginePlayerId;
  }
  const state = s.state;
  if (state.status === "finished" || s.match.status !== "in_progress") {
    finished = state.status === "finished";
    break;
  }
  if (state.round !== rounds) {
    rounds = state.round;
    console.log(`   round ${rounds} (version ${s.version}, scores ${state.players.map((p: any) => p.score).join("/")})`);
  }
  const current = state.players[state.currentSeat].id;
  const version = s.version;
  if (guestByPid.size === 0) {
    for (const p of s.players) {
      const g = guests.find((x) => x.id === p.userId);
      if (g) guestByPid.set(p.enginePlayerId, g);
    }
  }
  const actor = guestByPid.get(current) ?? guests[0];
  const act = async (action: Record<string, unknown>) => {
    const { data, error }: { data: any; error: any } = await actor.client.functions.invoke("match", {
      body: { op: "action", matchId, actionId: crypto.randomUUID(), expectedVersion: version, action },
    });
    if (error) console.log("   guest action error", error.message);
    if (data?.accepted) guestActions++;
    else if (data && !data.duplicate) console.log(`   guest refused: ${data.failure}`);
  };

  if (state.status === "roundOver") {
    // Either the host taps "Prossimo Round" or the guest deals.
    if (await findButton(/Prossimo Round/)) {
      await clickButton(/Prossimo Round/);
      resultSheets++;
    } else {
      await act({ type: "startNextRound" });
    }
    await sleep(1500);
    continue;
  }

  if (guestByPid.has(current)) {
    // This guest re-reads ITS OWN snapshot (its hand), then acts.
    const mine = await actor.client.rpc("match_snapshot", { p_match_id: matchId });
    const mineData = mine.data as any;
    if (mine.error || mineData.version !== version) { await sleep(500); continue; }
    const hand = mineData.hand as string[];
    const merged = { ...state, players: state.players.map((p: any) => p.id === current ? { ...p, hand } : p) };
    if (state.status === "awaitingSuitChoice") {
      const suits: Record<string, number> = {};
      for (const c of hand) suits[c.split("_")[0]] = (suits[c.split("_")[0]] ?? 0) + 1;
      const suit = Object.entries(suits).sort((a, b) => b[1] - a[1])[0]?.[0] ?? "denari";
      await act({ type: "chooseSuit", suit });
    } else {
      const p = engine.playable(merged, current);
      if (p.cards.length) await act({ type: "playCard", card: p.cards[0] });
      else if (p.canDraw) await act({ type: "drawCard" });
      else if (p.canPass) await act({ type: "pass" });
    }
    await sleep(600);
    continue;
  }

  // Host's turn: the Chrome player presses what the table offers. First-run
  // coach marks sit over the table until acknowledged. The buttons appear a
  // beat after the state (animations), so poll for them.
  hostTurns++;
  while (await findButton(/HO CAPITO/i)) await clickButton(/HO CAPITO/i, "coach", 3000);
  let acted = false;
  const turnStart = Date.now();
  while (!acted && Date.now() - turnStart < 12_000) {
    const took = await findButton(/^Prendi/);
    const draw = took ?? (await findButton(/\bPesca\b/));
    if (draw && !draw.disabled) {
      console.log(`   host: tapping ${took ? "Prendi" : "Pesca"} (node ${draw.i})`);
      await clickNode(draw.i);
      acted = true;
      // A drawn playable card keeps the turn: decline it and pass.
      const passStart = Date.now();
      while (Date.now() - passStart < 6_000) {
        const pass = await findButton(/\bPassa\b/);
        if (pass && !pass.disabled) {
          console.log("   host: tapping Passa");
          await clickNode(pass.i);
          break;
        }
        await sleep(400);
      }
      break;
    }
    const pass = await findButton(/\bPassa\b/);
    if (pass && !pass.disabled) {
      console.log("   host: tapping Passa");
      await clickNode(pass.i);
      acted = true;
      break;
    }
    await sleep(400);
  }
  if (Date.now() - lastShot > 60_000) {
    lastShot = Date.now();
    await shot(`ui_21_table_step${step}`);
  }
  await sleep(800);
}
console.log(`   ${guestActions} guest actions, ${hostTurns} host UI turns, ${rounds} rounds, ${resultSheets} result sheets tapped, ${Math.round((Date.now() - t0) / 1000)}s`);
check(`the match reached 'finished' with the host playing only through the UI (${guests.length + 1} players)`, finished);
const onResult = await waitText(/VINCITORE|Rivincita/, 30000);
check("host's screen shows the match result", onResult);
await shot("ui_30_match_result");
// The claim "the host played through the UI" is checked on the SERVER: its
// own accepted actions must exist, and it must not have been timed out.
const { data: hostRows } = await guest.from("match_actions").select("id, actor_id").eq("match_id", matchId);
const { data: hostSeat } = await guest.from("match_players").select("consecutive_timeouts, forfeited_at").eq("match_id", matchId).eq("user_id", hostUserId).single();
const hostActions = (hostRows ?? []).filter((r: any) => r.actor_id === hostUserId).length;
check(`server logged actions by the Chrome host itself (${hostActions}) and never forfeited it`, hostActions > 0 && !hostSeat?.forfeited_at, hostSeat);
const { data: mps } = await guest.from("match_players").select("user_id,is_winner,placement,xp_awarded").eq("match_id", matchId);
check("server recorded a winner and placements", !!mps && mps.some((r: any) => r.is_winner) && mps.every((r: any) => r.placement), mps);
const { data: prof } = await guest.from("profiles").select("matches,wins,losses,xp").eq("id", guests[0].id).single();
check("guest profile updated server-side", !!prof && (prof as any).matches >= 1, prof);

flushConsole();
await browser.close();
console.log(failures === 0 ? "ALL PASS" : `${failures} FAILURE(S)`);
Deno.exit(failures === 0 ? 0 : 1);
