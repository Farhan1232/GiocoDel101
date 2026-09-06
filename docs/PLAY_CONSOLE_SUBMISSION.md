# Google Play submission — every field, with the answer

Work down this list; each heading is a screen in Play Console. Values in
`code` are exact — copy them character for character, they must match the
build. Lines marked **YOU** are decisions or details only the owner has.

Build in hand: `app-release.aab`, versionName **1.0.1**, versionCode **2**,
signed `CN=Gioco del 101`.

---

## 0. Two blockers to clear before you start

**a) Account deletion — done.**
Google requires an app that creates accounts to offer deletion both in the app
and on a public web page. Both now exist: **Impostazioni → ACCOUNT → Elimina
account** erases the account immediately (server RPC `delete_my_account`,
deployed and tested against the live project), and section 9 of the privacy
policy describes the route for the web side. Nothing left to do here beyond
hosting the policy.

**b) A hosted privacy policy URL.**
Play refuses the form without one. `documentation/privacy-policy.html` is the
page — put it on any web host and paste the URL. Same for
`terms-and-conditions.html` (recommended, not required).

Both of these also want the owner's real details baked into the app. Until
they are, the legal screens honestly say "not yet designated". Send me:

- **YOU** — legal name of the publisher (person or company)
- **YOU** — support email
- **YOU** — privacy email (can be the same)
- **YOU** — country whose law governs (e.g. `Italia`)
- **YOU** — the two hosted URLs

and I rebuild the bundle with them in one command.

---

## 1. Create app

| Field | Answer |
|---|---|
| App name | `Gioco del 101` (13 of 30 characters) |
| Default language | `Italiano – it-IT` |
| App or game | **Game** |
| Free or paid | **Free** (it can never be changed to paid later) |
| Declarations | Tick both: developer programme policies, US export laws |

## 2. Store listing → App details

**Short description** (80 char max) — Italian:

```
Il classico napoletano: gioca online con gli amici o offline contro il computer.
```

English:

```
The Neapolitan classic: play online with friends or solo against the computer.
```

**Full description** (4000 char max) — Italian:

```
Gioco del 101 è il classico gioco di carte napoletane, rifatto per il telefono.

Scarta, blocca, cambia palo e cerca di non superare 101 punti. Le regole sono
quelle di sempre, le carte sono le autentiche napoletane — Denari, Coppe,
Spade e Bastoni — e ogni animazione è disegnata a mano per lo schermo.

COME SI GIOCA
• Online da 2 a 4 giocatori: crea una stanza e condividi il codice con gli
  amici, oppure lascia che la partita rapida ti trovi un tavolo libero.
• Offline contro il computer, con tre livelli di difficoltà.
• Passa e Gioca: un solo telefono, si passa di mano in mano.
• Tutorial interattivo: impari giocando, una regola alla volta.

REGOLE DELLA CASA
Somma dei 2, Cavallo sempre giocabile, ritorno a zero a 101 esatti,
eliminazione oltre 101: ogni stanza sceglie le proprie.

PROGRESSI
Obiettivi, missioni giornaliere, classifiche, statistiche e livelli. I
progressi online seguono il tuo account su ogni dispositivo.

COMPLETAMENTE GRATUITO
Tutte le regole, tutte le modalità, online e offline: gratis. Gli unici
acquisti sono cinque contenuti estetici opzionali — tavoli, mazzo, dorso e un
ornamento. Nessun vantaggio di gioco, nessun abbonamento, nessuna pubblicità.
```

English:

```
Gioco del 101 is the classic Neapolitan card game, rebuilt for the phone.

Shed your cards, block, change suit and try not to pass 101 points. The rules
are the ones you know, the cards are the authentic Neapolitan deck — Coins,
Cups, Swords and Batons — and every animation is drawn for the screen.

HOW YOU PLAY
• Online, 2 to 4 players: create a room and share the code with friends, or
  let quick match find you an open table.
• Offline against the computer, at three difficulty levels.
• Pass and Play: one phone, handed around the table.
• Interactive tutorial: learn by playing, one rule at a time.

HOUSE RULES
Stacking 2s, the Knight always playable, back to zero on exactly 101,
elimination above 101 — every room picks its own.

PROGRESSION
Achievements, daily missions, leaderboards, statistics and levels. Online
progress follows your account on every device.

COMPLETELY FREE
Every rule, every mode, online and offline: free. The only purchases are five
optional cosmetics — tables, a deck finish, a card back and an ornament. No
gameplay advantage, no subscription, no advertising.
```

## 3. Store listing → Graphics

| Asset | Requirement | Status |
|---|---|---|
| App icon | 512 × 512 PNG, 32-bit, ≤ 1 MB | **MISSING** — the largest in the project is 192 × 192. I can render a 512 × 512 from the same source. |
| Feature graphic | 1024 × 500 PNG/JPG | **MISSING** — I can produce one. |
| Phone screenshots | 2–8, min side 320 px, max 3840 px | **MISSING as individual shots** — `preview/*.png` are multi-phone galleries. I can render 4–6 real 1080 × 2340 screenshots. |
| 7-inch / 10-inch tablet | Optional unless you list on tablets | Skip for now |

Say the word and I will generate all three sets.

## 4. Store settings

| Field | Answer |
|---|---|
| App category | **Game → Card** |
| Tags | Card game, Board, Casual (pick up to 5) |
| Store listing contact — email | **YOU** (the support email; shown publicly) |
| Website / phone | **YOU**, optional |
| External marketing | Leave default |

## 5. App content → Privacy policy

Paste the hosted URL from §0(b).

## 6. App content → App access

Choose **"All functionality is available without special access"**.

That is true: *Gioca come ospite* creates a real account with one tap and
opens every online feature, so the reviewer needs no credentials from you.

## 7. App content → Ads

**"No, my app does not contain ads."** The app ships no advertising SDK — the
privacy policy states this explicitly.

## 8. App content → Content rating (IARC questionnaire)

| Question | Answer |
|---|---|
| Category | **Game** |
| Violence, blood, sexual content, nudity, profanity, drugs, alcohol, tobacco, horror | **No** to all |
| Gambling — does the game simulate gambling or let users wager? | **No.** 101 is a shedding game; nothing is wagered, there is no casino simulation and no virtual currency. |
| Do users interact or communicate? | **Yes** — online matches, visible nicknames, and eight preset reactions (no free text chat) |
| Can users share their location? | **No** |
| Does the app allow purchase of digital goods? | **Yes** |
| Does it share user-provided personal information with third parties? | **No** |
| Is there user-generated content? | **No** (nickname only; no free text in matches) |

Expected outcome: **PEGI 3 / ESRB Everyone**, with the "In-App Purchases" and
"Users Interact" notices.

## 9. App content → Target audience and content

| Field | Answer |
|---|---|
| Target age groups | **18 and over** (simplest; the game is not aimed at children) |
| Appeals to children? | **No** |
| Ads in app? | No |

Selecting 13+ or under would pull in Families policy, a separate ads
declaration and stricter data rules — avoid it unless you want that audience.

## 10. App content → Data safety

**Does your app collect or share any of the required user data types? → Yes**
**Is all of the data encrypted in transit? → Yes**
**Do you provide a way for users to request that their data is deleted? → Yes**
(true now: the in-app route plus the policy page — see §0(a))

Declare exactly these, all **collected, NOT shared** (Supabase and Google are
processors acting on your behalf, which Play does not count as sharing):

| Data type | Collected | Required? | Purpose |
|---|---|---|---|
| Personal info → **Email address** | Yes | Optional (guest accounts have none) | Account management |
| Personal info → **User IDs** (nickname, account id) | Yes | Required | Account management, App functionality |
| Financial info → **Purchase history** | Yes | Required | App functionality |
| App activity → **In-app actions** (matches, moves, results, achievements, missions, leaderboard) | Yes | Required | App functionality |
| App info & performance → **Crash logs / Diagnostics** (server-side error logs) | Yes | Required | App functionality |

Do **not** declare: location, contacts, photos, files, messages, calendar,
health, device IDs, advertising IDs — the app touches none of them.

Note in the "Data isn't collected" sense: preferences, offline statistics and
saved offline games never leave the device.

## 11. App content → the remaining declarations

| Screen | Answer |
|---|---|
| Government apps | No |
| Financial features | **No** — in-app purchases of cosmetics are not a financial feature |
| Health apps | No |
| News app | No |
| Advertising ID | **Not used** — the app declares no `AD_ID` permission |

## 11b. Why the payment sheet does not open before all this is done

Worth stating plainly, because it costs people days: **Google Play Billing
only answers an app that Play itself installed.** An APK copied onto the
phone and opened from the file manager can never show a payment sheet, no
matter what the code does. The same is true before the products exist and are
ACTIVE in the console.

The shop no longer hides that. Every card carries a real Buy button with an
indicative €4,99, and pressing one either opens the store's sheet or says
exactly which of the two preconditions is missing — naming the product id on
screen when the console does not know it yet.

So the order that works is: create the products (§12) → upload to Internal
testing (§14) → install **from the Play link** → add yourself as a license
tester (§13) → buy.

## 12. Monetisation → In-app products

Create **five** products, all type **"In-app product" → one-time (managed)**.
The ids must match the app exactly:

| Product ID | Name (Italian) | Name (English) | Description |
|---|---|---|---|
| `gioco101_table_gold` | Tavolo Oro | Gold Table | Un tavolo da gran salone: panno d'oro battuto sotto luce calda. |
| `gioco101_table_classic` | Tavolo Classico | Classic Table | Il circolo di una volta: panno verde su noce scuro. |
| `gioco101_deck_special` | Mazzo Speciale | Special Deck | Il mazzo inciso della casa, rifinito in oro. |
| `gioco101_cardback_gold` | Dorso Oro | Gold Card Back | Un dorso in oro zecchino per le tue carte. |
| `gioco101_gadget_01` | Sigillo del 101 | 101 Seal | Un sigillo d'alloro dorato impresso nel panno del tavolo. |

- Price: **YOU** — target ≈ **€4.99** each. The app always shows the store's
  own price, so you can change it later with no app update.
- **Activate** all five, or the shop shows them as unavailable.

## 13. Monetisation → License testing

Settings → License testing → add the Google accounts that will test
purchases. They are never charged.

## 14. Release → Internal testing (do this before Production)

| Field | Answer |
|---|---|
| App bundle | `app-release.aab` |
| Release name | `1.0.1 (2)` |
| Release notes (it-IT) | see below |
| Testers | Add an email list with your own account |

Release notes, Italian:

```
• Le stanze online ora si creano correttamente: codice, ingresso con codice e
  partite da 2 a 4 giocatori.
• Partita rapida e ingresso in una stanza spiegano cosa serve invece di
  restare inattivi.
• Il cambio lingua ora aggiorna tutta l'app.
• I contenuti bloccati aprono il negozio sull'oggetto scelto.
• Correzioni di stabilità della connessione al tavolo online.
```

English:

```
• Online rooms are created correctly again: room code, join by code and
  2–4 player matches.
• Quick match and Join a room now explain what they need instead of sitting
  idle.
• Switching language now updates the whole app.
• Locked items open the shop on the item you tapped.
• Connection stability fixes at the online table.
```

## 15. Release → Countries / regions

Select the countries you want. Italy at minimum; "all countries" is fine —
the app is Italian and English and prices convert automatically.

## 16. Signing

Keep **Play App Signing** enabled (Google's default, mandatory for new apps).
Upload `app-release.aab` as it is — it is already signed with your upload key:

```
SHA-256  80:02:7D:21:82:03:24:37:9B:A0:9C:54:87:E5:07:FE:C4:60:CD:B0:8D:CC:3B:05:C1:F4:8C:0A:C2:74:61:52
SHA-1    12:D5:86:ED:20:E1:35:B0:33:03:F4:E1:85:DC:68:8E:89:7F:DA:8B
```

Every future update must be signed with the same `upload-keystore.jks` and
carry a higher versionCode (1.0.1+3, 1.0.2+4, …).

---

## Technical facts Play may ask for

| | |
|---|---|
| Package name | `it.giocodel101.gioco_del_101` |
| Version | 1.0.1 (versionCode 2) |
| Min SDK | 24 (Android 7.0) |
| Target SDK | 36 (Android 16) |
| Permissions | `android.permission.INTERNET` only |
| 64-bit | Yes (arm64-v8a + armeabi-v7a + x86_64) |
| Backend | Supabase (`fnyllrjchbqfrzezfeso`) |

## Order I would do it in

1. Clear §0 (account deletion + hosted privacy policy + your details) — these
   gate everything else.
2. Create the app (§1), fill Store listing text (§2) and settings (§4).
3. Generate and upload the three graphics sets (§3).
4. Answer every App content screen (§5–§11) — Play will not let you publish
   with one unanswered.
5. Create and activate the five products (§12) and add license testers (§13).
6. Upload the bundle to Internal testing (§14), install it from Play on a
   real phone, and buy each product once.
7. Only then promote to Production.
