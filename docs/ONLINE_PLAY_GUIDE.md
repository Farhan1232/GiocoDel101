# Gioco del 101 — playing online

Everything the online side does, in the order you meet it. Written for two
phones on a table in front of you.

---

## 1. What you need

- The app, **version 1.0.1 or later**, on each device.
- An internet connection on each.
- **One account per device.** Two people cannot share one account: the second
  sign-in takes the seat from the first.

You do **not** need to register. On the welcome screen **GIOCA COME OSPITE**
(*Play as guest*) creates a real account in one tap and opens every online
feature. Register later if you want your progress to follow you to another
phone — a guest account lives on that device.

---

## 2. Getting in — three doors

From Home tap **GIOCA ONLINE**. There are three ways to a table.

| | When to use it |
|---|---|
| **PARTITA RAPIDA** (Quick match) | You want to play now, against whoever is waiting |
| **CREA STANZA** (Create room) | You want to play with someone you know |
| **ENTRA IN UNA STANZA** (Join a room) | Someone gave you a six-letter code |

---

## 3. Playing with a friend — the room code

### On the first phone: make the room

1. **GIOCA ONLINE → CREA STANZA**
2. **GIOCATORI** — choose **2**, **3** or **4**. This is the size of the
   table; the match starts only when every seat is filled.
3. Optional: a room name, a **turn timer** (Nessuno, 15s, 30s, 60s) and the
   **house rules** — stacking 2s, the Knight always playable, back to zero at
   exactly 101, elimination past 101. Whatever you set here is what the whole
   table plays by.
4. **CREA LA STANZA**.

You land in the waiting room with a **six-character code**, for example
`BGKK39`, and the seat count showing **1/2**.

**CONDIVIDI IL CODICE** copies it to the clipboard so you can send it. Or just
read it out — it is deliberately short, upper-case, and letters that look
alike are never used.

> The host is ready automatically. That is why the first phone shows no
> "Sono pronto" button.

### On the second phone: join

5. **GIOCA ONLINE → ENTRA IN UNA STANZA**
6. Type the six characters. Case does not matter and confusable letters are
   filtered as you type; the six dashes fill in as you go. **INCOLLA** pastes
   a code you were sent.
7. **ENTRA**.

Both phones now show **2/2** and each other's nicknames.

### Start

8. On the joining phone tap **Sono pronto** (*I'm ready*).
9. On the host's phone **INIZIA LA PARTITA** lights up. Tap it.

Both phones arrive at the table within a second or two, cards dealt.

**With 3 or 4 players** it is identical — pick the size in step 2, and every
seat must be filled and ready before Start enables.

---

## 4. Quick match — playing with strangers

1. **GIOCA ONLINE → PARTITA RAPIDA**
2. Choose the table size. **Both players must choose the same number**: the
   queue only pairs people who asked for the same size.
3. **Cerca partita** (*Find a match*).

When enough players are waiting, the server builds the room and everyone drops
into it. It **starts by itself** — no Ready, no Start button. Quick matches
always use a 30-second turn timer so any two waiting players are compatible.

If you are testing with your own two phones, start the search on both within
about half a minute of each other.

**After 30 seconds alone** the screen offers **Continua contro CPU**. That is
an *offline* match against the computer, clearly labelled — it is offered, not
substituted, and it does not count towards the leaderboard.

**Annulla la ricerca** really leaves the queue.

---

## 5. At the table

Play runs clockwise. Only the player whose turn it is can do anything; the
other phones update on their own.

**Playing a card.** A card must match the **suit** or the **value** of the card
on top of the discard pile. Playable cards are highlighted.

**If you cannot play**, tap the deck (or **Pesca**) to draw one card. If the
drawn card is playable you may play it immediately; otherwise **Passa** ends
your turn.

### The four cards that change things

| Card | What it does |
|---|---|
| **Asso** (Ace) | The next player loses their turn. With two players the turn comes straight back to you. |
| **Due** (2) | The next player draws two. If they hold a 2 they can raise it: +4, +6, +8. Whoever cannot answer draws the lot and loses the turn. |
| **Cavallo** (Knight, the 9) | Playable on anything, at any time. You then **choose the new suit**. It is also the defence against a chain of 2s — it cancels the chain and nobody draws. There are only four in the deck. |
| **Re, Fante, numbers** | Nothing special — suit or value. |

### LAST CARD

When you are about to play your **second-to-last** card, tap **LAST CARD**
*before* you play it. The declaration is announced to the whole table.

### Scoring — the point of the game

Empty your hand before the others. When someone goes out, the cards still in
everyone else's hands become **penalty points**:

- Ace = 1, numbers = their number, King = 10
- **Jack and Knight = 25 each**

Those points add to your running total.

- Go **over 101** and you are eliminated.
- Land on **exactly 101** and your score goes **back to zero** — the twist that
  turns matches around.

The last player standing wins.

---

## 6. The turn timer

If the room set one, a ring counts down beside your seat. Let it run out and
the turn passes automatically. Rooms with **Nessuno** have no clock.

---

## 7. Losing connection, and getting back

Nothing is stored on your phone: the match lives on the server.

- Lose signal for a moment and the app reconnects by itself.
- **Close the app entirely**, or your phone dies, and the match keeps going.
  Reopen the app and Home shows **Rientra nella partita** (*Rejoin the
  match*) — tap it and you are back at the same table, same hand.

## 8. Leaving on purpose

**Abbandona** in the in-game menu forfeits: it counts as a loss and you cannot
rejoin. With two players the other player wins immediately; with three or four
the match continues without you.

## 9. After the match

The result screen shows the final points. **Rivincita / Rematch** offers
another match with the same players — everyone has to accept.

Wins, experience and leaderboard position only move for **online** matches
against real players.

---

## 10. One thing that does not work yet

**Reactions and the presence dots do not arrive.** The eight preset reactions
(Ciao, Bravo, Mamma mia…) and the little "player is connected" indicators rely
on a Supabase message channel that the project is currently refusing, even for
players genuinely seated at the match.

**The game itself is unaffected** — every card, every draw, every score travels
on a different channel that works normally. This is cosmetic only, and the fix
is a decision the owner still has to make.

---

## 11. If something goes wrong

| What you see | What it means |
|---|---|
| *"Accedi o gioca come ospite per usare le funzioni online"* | Nobody is signed in on this device. Tap the sign-in button offered. |
| *"Codice non valido"* / room not found | The code was mistyped, or the room was closed. Codes are six characters. |
| *"La stanza è piena"* | Somebody took the last seat first. |
| *"Sei già in una partita"* | You have a match still running. Rejoin it from Home and finish or leave it. |
| *"La partita è già iniziata"* | The host started before you joined. |
| Search finds nobody | Nobody else is queued **for that table size**. Both phones must pick the same number. |
| Stuck on "Riconnessione…" | The connection to the table dropped. It retries by itself; if it persists, close and reopen the app and use **Rientra nella partita**. |

---

## Quick reference for testing with two phones

```
Phone 1                          Phone 2
─────────────────────────────    ─────────────────────────────
GIOCA COME OSPITE                GIOCA COME OSPITE
GIOCA ONLINE                     GIOCA ONLINE
CREA STANZA                      ENTRA IN UNA STANZA
  players: 2                       type the code
  CREA LA STANZA                    ENTRA
  read the code ──────────────►    Sono pronto
INIZIA LA PARTITA
        ↓                                ↓
   both phones are at the dealt table
```
