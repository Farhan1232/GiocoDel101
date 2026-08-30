import '../../game/domain/bot_roster.dart';
import '../../game/domain/card_rank.dart';
import '../../game/domain/card_suit.dart';
import '../../game/domain/game_card.dart';
import '../../game/domain/game_player.dart';
import '../../game/domain/game_rules.dart';
import '../../game/domain/game_state.dart';
import '../../game/domain/player_type.dart';

/// §X — the interactive tutorial's lessons.
///
/// Every lesson is a *real* [GameState] the real [GameEngine] plays: the
/// hands, the top card and any pending chain are fixed so the situation the
/// lesson describes is exactly the one on the table, and the move the
/// player is asked for is legal by the engine's own judgement (a test
/// proves it for every lesson). Nothing here re-implements a rule.
enum TutorialLessonId {
  firstCard,
  drawing,
  ace,
  two,
  chain,
  cavallo,
  block,
  centouno;

  String get key => name;
}

/// What the tutorial is waiting for the player to do.
sealed class TutorialExpectation {
  const TutorialExpectation();
}

/// Any card the engine says is legal.
class ExpectAnyLegalCard extends TutorialExpectation {
  const ExpectAnyLegalCard();
}

/// One specific card.
class ExpectCard extends TutorialExpectation {
  const ExpectCard(this.card);
  final GameCard card;
}

/// A draw from the stock.
class ExpectDraw extends TutorialExpectation {
  const ExpectDraw();
}

/// Naming a suit after a Cavallo (any of the four is fine).
class ExpectSuit extends TutorialExpectation {
  const ExpectSuit();
}

class TutorialLesson {
  const TutorialLesson({
    required this.id,
    required this.steps,
    required this.build,
    this.opponentReplies = true,
  });

  final TutorialLessonId id;

  /// The player's moves, in order. Most lessons are one move; drawing and
  /// the Cavallo take two.
  final List<TutorialExpectation> steps;

  /// The table this lesson starts from.
  final GameState Function(TutorialSeats seats) build;

  /// After the player's last step, let the opponent take its turn so the
  /// player sees the consequence before the lesson is marked done.
  final bool opponentReplies;
}

/// Who sits at the tutorial table.
class TutorialSeats {
  const TutorialSeats({required this.playerName, required this.avatarId});

  final String playerName;
  final String avatarId;

  static const String humanId = 'p0';
  static const String opponentId = 'b1';
}

GameCard _c(CardSuit s, CardRank r) => GameCard(s, r);

/// Builds a fully determined table: the cards not placed in a hand, on the
/// discard pile or at the top of the stock fill the rest of the stock, so
/// the 40-card invariant holds and the engine accepts the state.
GameState _table(
  TutorialSeats seats, {
  required List<GameCard> hand,
  required List<GameCard> opponent,
  required GameCard top,
  List<GameCard> stockTop = const [],
  List<GameCard> discardBelowTop = const [],
  int pendingDrawCount = 0,
  int chainLength = 0,
  int score = 0,
  int opponentScore = 0,
  int round = 1,
}) {
  final opponentProfile = BotRoster.all.first;
  final players = [
    GamePlayer(
      id: TutorialSeats.humanId,
      name: seats.playerName,
      type: PlayerType.humanLocal,
      avatarId: seats.avatarId,
      score: score,
      hand: hand,
    ),
    GamePlayer(
      id: TutorialSeats.opponentId,
      name: opponentProfile.name,
      type: PlayerType.bot,
      avatarId: opponentProfile.avatarId,
      difficulty: BotDifficulty.normal,
      personality: opponentProfile.personality,
      score: opponentScore,
      hand: opponent,
    ),
  ];
  final placed = <GameCard>{
    ...hand,
    ...opponent,
    ...stockTop,
    ...discardBelowTop,
    top,
  };
  final remainder = Deck.standard.where((c) => !placed.contains(c)).toList();
  return GameState(
    gameId: 'tutorial',
    mode: GameMode.vsComputer,
    rules: const GameRules(),
    players: players,
    // The stock deals from its end: the lesson's cards sit on top.
    drawPile: [...remainder, ...stockTop],
    discardPile: [...discardBelowTop, top],
    activeSuit: top.suit,
    currentSeat: 0,
    pendingDrawCount: pendingDrawCount,
    chainLength: chainLength,
    round: round,
    seed: 101,
  );
}

class TutorialLessons {
  const TutorialLessons._();

  static final GameCard _coppeSette = _c(CardSuit.coppe, CardRank.sette);
  static final GameCard _coppeSei = _c(CardSuit.coppe, CardRank.sei);
  static final GameCard _coppeAsso = _c(CardSuit.coppe, CardRank.asso);
  static final GameCard _coppeDue = _c(CardSuit.coppe, CardRank.due);
  static final GameCard _spadeDue = _c(CardSuit.spade, CardRank.due);
  static final GameCard _spadeCavallo = _c(CardSuit.spade, CardRank.cavallo);
  static final GameCard _bastoniCavallo = _c(
    CardSuit.bastoni,
    CardRank.cavallo,
  );

  /// The opening card most lessons share: Coppe 5, so "the active suit is
  /// Coppe" stays true from one lesson to the next.
  static final GameCard _opener = _c(CardSuit.coppe, CardRank.cinque);

  /// A quiet opponent hand: no Asso, no 2, no Cavallo, nothing in Coppe.
  static final List<GameCard> _quietOpponent = [
    _c(CardSuit.bastoni, CardRank.tre),
    _c(CardSuit.bastoni, CardRank.quattro),
    _c(CardSuit.spade, CardRank.sei),
    _c(CardSuit.denari, CardRank.re),
    _c(CardSuit.denari, CardRank.quattro),
  ];

  static final List<TutorialLesson> all = [
    // 1 — seme o valore.
    TutorialLesson(
      id: TutorialLessonId.firstCard,
      steps: const [ExpectAnyLegalCard()],
      build: (seats) => _table(
        seats,
        top: _opener,
        hand: [
          _coppeSette, // suit
          _c(CardSuit.spade, CardRank.cinque), // rank
          _c(CardSuit.denari, CardRank.tre),
          _c(CardSuit.bastoni, CardRank.re),
          _c(CardSuit.denari, CardRank.sei),
        ],
        opponent: _quietOpponent,
      ),
    ),
    // 2 — pescare, poi giocare la carta pescata.
    TutorialLesson(
      id: TutorialLessonId.drawing,
      steps: [const ExpectDraw(), ExpectCard(_coppeSei)],
      build: (seats) => _table(
        seats,
        top: _opener,
        hand: [
          _c(CardSuit.denari, CardRank.tre),
          _c(CardSuit.spade, CardRank.sette),
          _c(CardSuit.bastoni, CardRank.re),
          _c(CardSuit.denari, CardRank.sette),
          _c(CardSuit.bastoni, CardRank.sei),
        ],
        opponent: _quietOpponent,
        stockTop: [_coppeSei],
      ),
    ),
    // 3 — l'Asso salta il turno (in due, torna subito a te).
    TutorialLesson(
      id: TutorialLessonId.ace,
      steps: [ExpectCard(_coppeAsso)],
      opponentReplies: false,
      build: (seats) => _table(
        seats,
        top: _opener,
        hand: [
          _coppeAsso,
          _c(CardSuit.spade, CardRank.tre),
          _c(CardSuit.denari, CardRank.sette),
          _c(CardSuit.bastoni, CardRank.sei),
          _c(CardSuit.spade, CardRank.re),
        ],
        opponent: _quietOpponent,
      ),
    ),
    // 4 — il Due: l'avversario pesca due carte.
    TutorialLesson(
      id: TutorialLessonId.two,
      steps: [ExpectCard(_coppeDue)],
      build: (seats) => _table(
        seats,
        top: _opener,
        hand: [
          _coppeDue,
          _c(CardSuit.spade, CardRank.tre),
          _c(CardSuit.denari, CardRank.sette),
          _c(CardSuit.bastoni, CardRank.sei),
          _c(CardSuit.spade, CardRank.re),
        ],
        opponent: _quietOpponent,
      ),
    ),
    // 5 — la catena: rispondi al Due con un altro Due (+4).
    TutorialLesson(
      id: TutorialLessonId.chain,
      steps: [ExpectCard(_spadeDue)],
      build: (seats) => _table(
        seats,
        top: _coppeDue,
        discardBelowTop: [_opener],
        pendingDrawCount: 2,
        chainLength: 1,
        hand: [
          _spadeDue,
          _coppeSette, // legal on any other turn, not inside a chain
          _c(CardSuit.denari, CardRank.tre),
          _c(CardSuit.bastoni, CardRank.re),
          _c(CardSuit.denari, CardRank.sei),
        ],
        opponent: _quietOpponent,
      ),
    ),
    // 6 — il Cavallo cambia seme.
    TutorialLesson(
      id: TutorialLessonId.cavallo,
      steps: [ExpectCard(_spadeCavallo), const ExpectSuit()],
      build: (seats) => _table(
        seats,
        top: _opener,
        hand: [
          _spadeCavallo,
          _c(CardSuit.denari, CardRank.tre),
          _c(CardSuit.bastoni, CardRank.sette),
          _c(CardSuit.spade, CardRank.sette),
          _c(CardSuit.bastoni, CardRank.sei),
        ],
        opponent: _quietOpponent,
      ),
    ),
    // 7 — il Cavallo blocca la catena di Due.
    TutorialLesson(
      id: TutorialLessonId.block,
      steps: [ExpectCard(_bastoniCavallo), const ExpectSuit()],
      build: (seats) => _table(
        seats,
        top: _coppeDue,
        discardBelowTop: [_opener],
        pendingDrawCount: 2,
        chainLength: 1,
        hand: [
          _bastoniCavallo,
          _c(CardSuit.bastoni, CardRank.sette),
          _c(CardSuit.denari, CardRank.tre),
          _c(CardSuit.bastoni, CardRank.re),
          _c(CardSuit.denari, CardRank.sei),
        ],
        opponent: _quietOpponent,
      ),
    ),
    // 8 — Centouno! Il tuo ultimo scarto chiude il round e porta Marco
    // esattamente a 101: torna a zero.
    TutorialLesson(
      id: TutorialLessonId.centouno,
      steps: [ExpectCard(_coppeSette)],
      opponentReplies: false,
      build: (seats) => _table(
        seats,
        top: _opener,
        round: 3,
        score: 40,
        opponentScore: 92,
        hand: [_coppeSette],
        // Cavallo (9) is the only card left: 92 + 9 = 101 exactly.
        opponent: [_bastoniCavallo],
      ),
    ),
  ];

  static TutorialLesson byId(TutorialLessonId id) =>
      all.firstWhere((l) => l.id == id);
}
