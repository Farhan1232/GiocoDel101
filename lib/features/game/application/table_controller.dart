import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../domain/card_suit.dart';
import '../domain/game_card.dart';
import '../domain/game_player.dart';
import '../domain/game_state.dart';
import '../domain/round_result.dart';
import '../domain/table_session_status.dart';
import 'table_cue.dart';

/// The view registers this so the controller can wait for an animation to
/// finish before letting play continue.
typedef CuePlayer = Future<void> Function(TableCue cue);

/// What the table, the round-result and the match-result screens need from
/// whoever drives a match.
///
/// Two drivers exist: [GameController] runs the engine locally (bots, pass
/// and play); `OnlineMatchController` renders the server's authoritative
/// state and only ever *requests* moves. The screens cannot tell them apart
/// — which is the point: online and offline share one table.
abstract class TableController extends GetxController {
  /// Bumped whenever [state] changes, so `Obx` rebuilds cheaply.
  RxInt get revision;

  /// True while cues are playing or a request is in flight: input is refused.
  RxBool get busy;

  Rx<GameCard?> get selectedCard;

  /// §13 — set while the Suit Ritual is open for the viewer.
  Rx<GameCard?> get pendingSuitChoice;

  /// §11 — live Chain Storm level, 0 when calm.
  RxInt get chainLevel;
  RxInt get chainTotal;

  /// §67 — the seat waiting behind the handover card (pass & play only).
  Rx<String?> get handoverPlayerId;

  /// §61 — short-lived text over the table.
  Rx<String?> get banner;

  /// §23 — reaction bubbles, keyed by player id.
  RxMap<String, String> get reactions;

  /// §36 — set once the round is scored, consumed by the results screen.
  Rx<RoundResult?> get lastRoundResult;

  /// §M — timer and connection, as the top bar draws them.
  Rx<TableSessionStatus> get tableStatus;

  CuePlayer? cuePlayer;

  GameState get state;
  GamePlayer get currentPlayer;

  /// Seats a person at this device plays. One entry online.
  List<String> get humanIds;

  bool get isOnline;
  bool get isHumanTurn;
  GamePlayer get viewingPlayer;
  List<GamePlayer> get opponents;
  bool get canInteract;
  List<GameCard> get playableForViewer;
  bool get canDraw;
  bool get canEndTurn;
  bool get mustTakePenalty;

  /// Called by the view once it is laid out and able to play cues.
  void start();

  Future<void> selectCard(GameCard card);
  void clearSelection();
  void rejectCard(GameCard card);
  Future<void> playCard(GameCard card);
  Future<void> drawCard();
  Future<void> endTurn();
  Future<void> chooseSuit(CardSuit suit);
  void sendReaction(String phrase);
  void confirmHandover();
  Future<void> persistNow();
  Future<void> beginNextRound();

  /// Leaves the table for good. Offline this only saves; online it forfeits.
  Future<void> abandon();

  // ------------------------------------------------------------- pausing

  /// True while the match is frozen behind the pause overlay. Bots do not
  /// act and input is refused until [resume]. Online tables cannot pause —
  /// the server clock keeps running — so the default is a constant false.
  RxBool get paused => _neverPaused;
  static final RxBool _neverPaused = false.obs;

  /// Whether this driver offers a pause menu at all.
  bool get canPause => false;

  void pause() {}
  void resume() {}

  // ------------------------------------------------------------ tutorial

  /// True for the guided tutorial table: no statistics, no saves, no
  /// coach marks, a lighter exit dialog.
  bool get isTutorial => false;

  /// §65 — whether the first-run coach marks may appear on this table.
  bool get showsCoachMarks => !isTutorial;

  @protected
  bool isHumanSeat(String id) => humanIds.contains(id);
}
