# FINAL IAP PRODUCT IDS — Gioco del 101

Session 8 (2026-09-01). These five ids are **canonical**: the app queries
exactly them, the `verify-purchase` server grants exactly them
(`supabase/functions/verify-purchase/verify.ts` → `PRODUCT_ENTITLEMENTS`),
and the client must create exactly them in **both** store consoles. All five
are **permanent one-time cosmetic purchases** — no subscription, no
consumable, no gameplay advantage. The full game stays free.

**The app never hard-codes a price.** Every displayed price is the store's
own localized metadata (`ProductDetails.price` / `currencyCode`), so the
client can change prices later in Play Console / App Store Connect without
any app update. Until the products exist in a console, the shop shows an
honest "not yet available" line — never an invented price.

---

## 1. `gioco101_table_gold`

| | |
|---|---|
| PRODUCT ID | `gioco101_table_gold` |
| TYPE | Non-consumable / one-time |
| ENTITLEMENT (server) | `table.gold` |
| DISPLAY | Tavolo Oro / Gold Table |
| WHAT IT UNLOCKS | The "Tavolo Oro" table theme: struck-gold felt, warm chandelier light |
| TARGET INITIAL PRICE | ~€4.99 |
| PRICE SOURCE IN APP | Store metadata |
| CLIENT MUST CREATE IN | Google Play Console + App Store Connect |

## 2. `gioco101_table_classic`

| | |
|---|---|
| PRODUCT ID | `gioco101_table_classic` |
| TYPE | Non-consumable / one-time |
| ENTITLEMENT (server) | `table.classic` |
| DISPLAY | Tavolo Classico / Classic Table |
| WHAT IT UNLOCKS | The "Tavolo Classico" table theme: traditional green baize on dark walnut |
| TARGET INITIAL PRICE | ~€4.99 |
| PRICE SOURCE IN APP | Store metadata |
| CLIENT MUST CREATE IN | Google Play Console + App Store Connect |

## 3. `gioco101_deck_special`

| | |
|---|---|
| PRODUCT ID | `gioco101_deck_special` |
| TYPE | Non-consumable / one-time |
| ENTITLEMENT (server) | `deck.special` |
| DISPLAY | Mazzo Speciale / Special Deck |
| WHAT IT UNLOCKS | "Mazzo Inciso Oro": the app's own original engraved vector deck, finished in gold. The authentic free Napoletane deck is never replaced — this is an optional alternative finish |
| TARGET INITIAL PRICE | ~€4.99 |
| PRICE SOURCE IN APP | Store metadata |
| CLIENT MUST CREATE IN | Google Play Console + App Store Connect |

## 4. `gioco101_cardback_gold`

| | |
|---|---|
| PRODUCT ID | `gioco101_cardback_gold` |
| TYPE | Non-consumable / one-time |
| ENTITLEMENT (server) | `cardback.gold` |
| DISPLAY | Dorso Oro / Gold Card Back |
| WHAT IT UNLOCKS | The "Oro Reale" card BACK (gilded ground, deep ink, ivory medallion). Card faces are untouched |
| TARGET INITIAL PRICE | ~€4.99 |
| PRICE SOURCE IN APP | Store metadata |
| CLIENT MUST CREATE IN | Google Play Console + App Store Connect |

## 5. `gioco101_gadget_01`

| | |
|---|---|
| PRODUCT ID | `gioco101_gadget_01` |
| TYPE | Non-consumable / one-time |
| ENTITLEMENT (server) | `gadget.01` |
| DISPLAY | Sigillo del 101 / 101 Seal |
| WHAT IT UNLOCKS | A decorative gold laurel seal pressed into the table felt (the card-back medallion motif). Pure ornament — no gameplay effect |
| TARGET INITIAL PRICE | ~€4.99 |
| PRICE SOURCE IN APP | Store metadata |
| CLIENT MUST CREATE IN | Google Play Console + App Store Connect |

---

## Copyable block for the client

```
GOOGLE PLAY / APP STORE PRODUCT IDS

gioco101_table_gold
gioco101_table_classic
gioco101_deck_special
gioco101_cardback_gold
gioco101_gadget_01

PRODUCT TYPE:
NON-CONSUMABLE / ONE-TIME PURCHASE

INITIAL TARGET PRICE:
ABOUT €4.99 EACH

IMPORTANT:
REAL PRICE IS CONFIGURED IN GOOGLE PLAY CONSOLE / APP STORE CONNECT.
APP DISPLAYS STORE-RETURNED LOCALIZED PRICE.
```

## Ownership model

One product grants one **independent** server entitlement
(`user_entitlements`, keyed `(user_id, entitlement)`). A player may own
none, one, several or all five. There is no global "premium" flag; the
session-7 placeholder `gioco101_premium` is retired and refused by the
server. Restore Purchases recovers every owned item, free, on the same
store account.
