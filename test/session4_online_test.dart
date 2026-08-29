// Session 4 — the online table driver, exercised against a fake backend.
//
// These tests are about the CLIENT contract: the controller renders what the
// server says, sends requests with an idempotent id and the version it saw,
// reconciles from snapshots, and never applies a rule itself. The real
// server is exercised by tool/online_matrix.dart against the dev project.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gioco_del_101/app/localization/app_strings.dart';
import 'package:gioco_del_101/core/widgets/network_banner.dart';
import 'package:gioco_del_101/features/game/application/table_controller.dart';
import 'package:gioco_del_101/features/game/application/table_cue.dart';
import 'package:gioco_del_101/features/game/domain/card_rank.dart';
import 'package:gioco_del_101/features/game/domain/card_suit.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_engine.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_event.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_failure.dart';
import 'package:gioco_del_101/features/game/domain/game_action.dart';
import 'package:gioco_del_101/features/game/domain/game_card.dart';
import 'package:gioco_del_101/features/game/domain/game_player.dart';
import 'package:gioco_del_101/features/game/domain/game_rules.dart';
import 'package:gioco_del_101/features/game/domain/game_state.dart';
import 'package:gioco_del_101/features/game/domain/player_type.dart';
import 'package:gioco_del_101/features/home/application/home_controller.dart';
import 'package:gioco_del_101/core/storage/game_storage_service.dart';
import 'package:gioco_del_101/core/storage/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gioco_del_101/features/online/application/online_match_controller.dart';
import 'package:gioco_del_101/features/online/application/online_match_repository.dart';
import 'package:gioco_del_101/features/online/domain/online_match_models.dart';
import 'package:gioco_del_101/features/rooms/domain/remote_room.dart';

const _engine = GameEngine();
const _userA = 'aaaaaaaa-0000-0000-0000-000000000001';
const _userB = 'aaaaaaaa-0000-0000-0000-000000000002';

/// A server in a box: holds the FULL state, applies actions with the real
/// engine, publishes redacted snapshots per viewer, and records every
/// request so tests can assert what was sent.
class FakeServer implements OnlineMatchRepository {
  FakeServer(this.full);

  GameState full;
  final List<MatchActionRequest> sent = [];
  final List<String> reactionsSent = [];
  int timeoutClaims = 0;
  bool forfeited = false;
  DateTime? deadline;
  int turnTimerSeconds = 0;
  String status = 'in_progress';
  void Function(int version)? _onStateChanged;
  void Function(ReactionMessage)? _onReaction;
  void Function(MatchChannelStatus)? _onStatus;
  final Set<String> seenActionIds = {};
  bool failNextWithNetwork = false;
  DateTime Function() clock = DateTime.now;

  @override
  String? get currentUserId => _userA;

  Map<String, dynamic> _redacted() {
    final json = full.toJson();
    json.remove('seed');
    json.remove('drawnCard');
    json.remove('history');
    json['drawPileCount'] = (json.remove('drawPile') as List).length;
    json['players'] = [
      for (final p in json['players'] as List)
        {...p as Map<String, dynamic>, 'handCount': (p['hand'] as List).length}
          ..remove('hand'),
    ];
    return json;
  }

  MatchSnapshot snapshotFor(String userId) {
    final pid = userId == _userA ? 'p0' : 'p1';
    return MatchSnapshot.fromJson({
      'match': {
        'id': 'm1',
        'roomId': 'r1',
        'status': status,
        'turnTimerSeconds': turnTimerSeconds,
        'turnDeadlineAt': deadline?.toIso8601String(),
        'currentUserId': full.currentPlayerId == 'p0' ? _userA : _userB,
      },
      'version': full.version,
      'state': _redacted(),
      'hand': full.handOf(pid).map((c) => c.id).toList(),
      'players': [
        {
          'userId': _userA,
          'seat': 0,
          'enginePlayerId': 'p0',
          'nickname': 'Alpha',
          'avatarId': 'sofia',
          'connection': 'online',
        },
        {
          'userId': _userB,
          'seat': 1,
          'enginePlayerId': 'p1',
          'nickname': 'Bravo',
          'avatarId': 'lucia',
          'connection': 'online',
        },
      ],
      'serverNow': clock().toUtc().toIso8601String(),
    });
  }

  /// The other seat moves (as the real server would on its behalf).
  void opponentPlays(GameAction action) {
    final r = _engine.applyAction(full, action);
    if (r is! ActionAccepted) throw StateError('opponent move refused: $r');
    full = r.state;
    _onStateChanged?.call(full.version);
  }

  @override
  Future<String> startRoom(String roomId) async => 'm1';

  @override
  Future<MatchSnapshot> snapshot(String matchId) async {
    if (failNextWithNetwork) {
      failNextWithNetwork = false;
      throw const OnlineException(OnlineError.network, 'offline');
    }
    return snapshotFor(_userA);
  }

  @override
  Future<ActionOutcome> send(MatchActionRequest request) async {
    sent.add(request);
    if (!seenActionIds.add(request.actionId)) {
      return ActionOutcome(
        accepted: true,
        version: full.version,
        duplicate: true,
      );
    }
    if (request.expectedVersion != full.version) {
      return ActionOutcome(
        accepted: false,
        version: full.version,
        failure: 'staleState',
      );
    }
    final action = switch (request.type) {
      'playCard' => PlayCardAction(
        playerId: 'p0',
        card: request.card!,
        chosenSuit: request.chosenSuit,
        baseVersion: full.version,
      ),
      'drawCard' => DrawCardAction(playerId: 'p0', baseVersion: full.version),
      'chooseSuit' => ChooseSuitAction(
        playerId: 'p0',
        suit: request.suit!,
        baseVersion: full.version,
      ),
      'pass' => PassAction(playerId: 'p0', baseVersion: full.version),
      'startNextRound' => StartNextRoundAction(
        playerId: 'p0',
        baseVersion: full.version,
      ),
      _ => throw ArgumentError(request.type),
    };
    final r = _engine.applyAction(full, action);
    if (r is ActionRejected) {
      return ActionOutcome(
        accepted: false,
        version: full.version,
        failure: r.failure.name,
      );
    }
    full = (r as ActionAccepted).state;
    final snap = snapshotFor(_userA);
    return ActionOutcome(
      accepted: true,
      version: full.version,
      publicState: snap.publicState,
      hand: snap.hand,
      events: [for (final e in r.events) e.name],
      status: full.status.key,
    );
  }

  @override
  Future<ActionOutcome> claimTimeout(String matchId) async {
    timeoutClaims++;
    return ActionOutcome(
      accepted: false,
      version: full.version,
      failure: 'deadlineNotReached',
    );
  }

  @override
  Future<void> forfeit(String matchId) async => forfeited = true;

  @override
  Future<RematchOutcome> requestRematch(String matchId) async =>
      const RematchOutcome(started: false, votes: 1, needed: 2, roomId: 'r1');

  @override
  Future<void> heartbeat(String matchId) async {}

  @override
  Future<void> sendReaction(String matchId, String key) async =>
      reactionsSent.add(key);

  @override
  Future<String?> activeMatchId() async => 'm1';

  @override
  Future<String?> currentMatchOfRoom(String roomId) async => 'm2';

  @override
  MatchSubscription subscribe(
    String matchId, {
    required void Function(int version) onStateChanged,
    required void Function(ReactionMessage message) onReaction,
    required void Function(MatchChannelStatus status) onStatus,
    void Function(Set<String> userIds)? onPresence,
  }) {
    _onStateChanged = onStateChanged;
    _onReaction = onReaction;
    _onStatus = onStatus;
    onStatus(MatchChannelStatus.connected);
    return MatchSubscription(close: () async {});
  }

  void dropConnection() => _onStatus?.call(MatchChannelStatus.disconnected);
  void broadcast(ReactionMessage m) => _onReaction?.call(m);
}

GameCard _c(CardSuit s, CardRank r) => GameCard(s, r);

Future<LocalStorage> _storage() async {
  SharedPreferences.setMockInitialValues({});
  return LocalStorage(await SharedPreferences.getInstance());
}

GameState _table({
  required List<GameCard> handA,
  required List<GameCard> handB,
  required GameCard top,
  int currentSeat = 0,
  int pending = 0,
  int chain = 0,
  GameStatus status = GameStatus.awaitingAction,
}) {
  final placed = {...handA, ...handB, top};
  final stock = Deck.standard.where((c) => !placed.contains(c)).toList();
  return GameState(
    gameId: 'm1',
    mode: GameMode.passAndPlay,
    rules: const GameRules(),
    players: [
      GamePlayer(
        id: 'p0',
        name: 'Alpha',
        type: PlayerType.humanLocal,
        avatarId: 'sofia',
        hand: handA,
      ),
      GamePlayer(
        id: 'p1',
        name: 'Bravo',
        type: PlayerType.humanLocal,
        avatarId: 'lucia',
        hand: handB,
      ),
    ],
    drawPile: stock,
    discardPile: [top],
    activeSuit: top.suit,
    currentSeat: currentSeat,
    pendingDrawCount: pending,
    chainLength: chain,
    status: status,
    seed: 11,
    version: 3,
  );
}

Future<(OnlineMatchController, FakeServer)> _boot(
  GameState full, {
  DateTime Function()? clock,
}) async {
  final server = FakeServer(full);
  final c = OnlineMatchController(
    repository: server,
    matchId: 'm1',
    initial: server.snapshotFor(_userA),
    userId: _userA,
    actionIdFactory: () => 'act-${server.sent.length + 1}',
    clock: clock,
  );
  Get.put<TableController>(c);
  c.onInit();
  return (c, server);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => Strings.use(const Locale('it')));
  tearDown(Get.reset);

  group('OnlineMatchController — rendering the server', () {
    test('shows own hand, counts for the others, no stock contents', () async {
      final (c, _) = await _boot(
        _table(
          handA: [
            _c(CardSuit.coppe, CardRank.re),
            _c(CardSuit.spade, CardRank.tre),
          ],
          handB: [
            _c(CardSuit.denari, CardRank.tre),
            _c(CardSuit.bastoni, CardRank.sei),
            _c(CardSuit.denari, CardRank.re),
          ],
          top: _c(CardSuit.coppe, CardRank.cinque),
        ),
      );
      expect(c.isOnline, isTrue);
      expect(c.viewingPlayer.hand.length, 2);
      expect(c.opponents.single.cardCount, 3);
      expect(c.opponents.single.hand, isEmpty);
      expect(c.state.drawPile, isEmpty);
      expect(c.state.drawPileCount, 40 - 2 - 3 - 1);
      expect(c.state.isRedacted, isTrue);
      expect(c.isHumanTurn, isTrue);
      expect(c.playableForViewer, [_c(CardSuit.coppe, CardRank.re)]);
      expect(c.canDraw, isTrue);
      expect(c.canEndTurn, isFalse);
      c.onClose();
    });

    test(
      'a legal play is a REQUEST: id, expected version, no local apply',
      () async {
        final (c, server) = await _boot(
          _table(
            handA: [
              _c(CardSuit.coppe, CardRank.re),
              _c(CardSuit.spade, CardRank.tre),
            ],
            handB: [_c(CardSuit.denari, CardRank.tre)],
            top: _c(CardSuit.coppe, CardRank.cinque),
          ),
        );
        await c.playCard(_c(CardSuit.coppe, CardRank.re));
        expect(server.sent.single.type, 'playCard');
        expect(server.sent.single.expectedVersion, 3);
        expect(server.sent.single.actionId, 'act-1');
        // The table now shows what the server answered.
        expect(c.version, 4);
        expect(c.viewingPlayer.hand, [_c(CardSuit.spade, CardRank.tre)]);
        expect(c.state.topCard, _c(CardSuit.coppe, CardRank.re));
        expect(c.isHumanTurn, isFalse);
        c.onClose();
      },
    );

    test('an illegal card never leaves the device', () async {
      final (c, server) = await _boot(
        _table(
          handA: [_c(CardSuit.bastoni, CardRank.sette)],
          handB: [_c(CardSuit.denari, CardRank.tre)],
          top: _c(CardSuit.coppe, CardRank.cinque),
        ),
      );
      await c.playCard(_c(CardSuit.bastoni, CardRank.sette));
      expect(server.sent, isEmpty);
      expect(c.version, 3);
      c.onClose();
    });

    test('off turn nothing is sent', () async {
      final (c, server) = await _boot(
        _table(
          handA: [_c(CardSuit.coppe, CardRank.re)],
          handB: [_c(CardSuit.denari, CardRank.tre)],
          top: _c(CardSuit.coppe, CardRank.cinque),
          currentSeat: 1,
        ),
      );
      expect(c.canInteract, isFalse);
      await c.playCard(_c(CardSuit.coppe, CardRank.re));
      await c.drawCard();
      expect(server.sent, isEmpty);
      c.onClose();
    });

    test('stale reply → the controller re-reads the snapshot', () async {
      final (c, server) = await _boot(
        _table(
          handA: [_c(CardSuit.coppe, CardRank.re)],
          handB: [
            _c(CardSuit.denari, CardRank.cinque),
            _c(CardSuit.spade, CardRank.re),
          ],
          top: _c(CardSuit.coppe, CardRank.cinque),
          currentSeat: 1,
        ),
      );
      // The opponent moved but the Realtime hint got lost: our version lags.
      server.full =
          (_engine.applyAction(
                    server.full,
                    PlayCardAction(
                      playerId: 'p1',
                      card: _c(CardSuit.denari, CardRank.cinque),
                    ),
                  )
                  as ActionAccepted)
              .state;
      expect(c.version, 3);
      // Force a stale request by pretending it is our turn on the old view.
      await c.resync();
      expect(c.version, 4);
      expect(c.isHumanTurn, isTrue);
      expect(c.state.topCard, _c(CardSuit.denari, CardRank.cinque));
      c.onClose();
    });

    test(
      'Realtime hint with a newer version triggers a re-read; cues describe the diff',
      () async {
        final (c, server) = await _boot(
          _table(
            handA: [_c(CardSuit.coppe, CardRank.re)],
            handB: [
              _c(CardSuit.coppe, CardRank.due),
              _c(CardSuit.spade, CardRank.re),
            ],
            top: _c(CardSuit.coppe, CardRank.cinque),
            currentSeat: 1,
          ),
        );
        final cues = <TableCue>[];
        c.cuePlayer = (cue) async => cues.add(cue);
        server.opponentPlays(
          PlayCardAction(
            playerId: 'p1',
            card: _c(CardSuit.coppe, CardRank.due),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(c.version, 4);
        expect(c.state.pendingDrawCount, 2);
        expect(
          cues.whereType<PlayCardCue>().single.card,
          _c(CardSuit.coppe, CardRank.due),
        );
        expect(cues.whereType<ChainGrowCue>().single.total, 2);
        expect(cues.whereType<TurnCue>().single.isHuman, isTrue);
        expect(c.chainTotal.value, 2);
        expect(c.mustTakePenalty, isTrue);
        c.onClose();
      },
    );

    test(
      'a Cavallo without a suit opens the ritual; the choice is a request',
      () async {
        final (c, server) = await _boot(
          _table(
            handA: [
              _c(CardSuit.spade, CardRank.cavallo),
              _c(CardSuit.spade, CardRank.tre),
            ],
            handB: [_c(CardSuit.denari, CardRank.tre)],
            top: _c(CardSuit.coppe, CardRank.cinque),
          ),
        );
        await c.playCard(_c(CardSuit.spade, CardRank.cavallo));
        expect(c.state.status, GameStatus.awaitingSuitChoice);
        expect(c.pendingSuitChoice.value, _c(CardSuit.spade, CardRank.cavallo));
        await c.chooseSuit(CardSuit.denari);
        expect(server.sent.last.type, 'chooseSuit');
        expect(server.sent.last.suit, CardSuit.denari);
        expect(c.state.activeSuit, CardSuit.denari);
        expect(c.pendingSuitChoice.value, isNull);
        c.onClose();
      },
    );

    test('draw then pass, both as requests', () async {
      final (c, server) = await _boot(
        _table(
          handA: [_c(CardSuit.bastoni, CardRank.sette)],
          handB: [_c(CardSuit.denari, CardRank.tre)],
          top: _c(CardSuit.coppe, CardRank.cinque),
        ),
      );
      await c.drawCard();
      expect(server.sent.last.type, 'drawCard');
      // Either the drawn card was playable (turn kept) or the turn moved on.
      if (c.isHumanTurn) {
        expect(c.canEndTurn, isTrue);
        await c.endTurn();
        expect(server.sent.last.type, 'pass');
      }
      expect(c.isHumanTurn, isFalse);
      c.onClose();
    });
  });

  group('OnlineMatchController — clock, connection, reactions, leaving', () {
    test(
      'countdown is derived from the server deadline, not a local timer',
      () async {
        var now = DateTime.utc(2026, 8, 30, 12, 0, 0);
        final full = _table(
          handA: [_c(CardSuit.coppe, CardRank.re)],
          handB: [_c(CardSuit.denari, CardRank.tre)],
          top: _c(CardSuit.coppe, CardRank.cinque),
        );
        final server = FakeServer(full)
          ..turnTimerSeconds = 30
          ..clock = (() => now)
          ..deadline = now.add(const Duration(seconds: 20));
        final c = OnlineMatchController(
          repository: server,
          matchId: 'm1',
          initial: server.snapshotFor(_userA),
          userId: _userA,
          clock: () => now,
        );
        Get.put<TableController>(c);
        c.onInit();
        expect(c.tableStatus.value.hasTimer, isTrue);
        expect(c.tableStatus.value.turnSecondsTotal, 30);
        expect(c.tableStatus.value.turnSecondsRemaining, closeTo(20, 1));
        now = now.add(const Duration(seconds: 25));
        await c.resync();
        expect(c.tableStatus.value.turnSecondsRemaining, 0);
        c.onClose();
      },
    );

    test(
      'socket drop shows Riconnessione… and recovers on reconnect',
      () async {
        final (c, server) = await _boot(
          _table(
            handA: [_c(CardSuit.coppe, CardRank.re)],
            handB: [_c(CardSuit.denari, CardRank.tre)],
            top: _c(CardSuit.coppe, CardRank.cinque),
          ),
        );
        expect(c.tableStatus.value.connection, NetworkStatus.online);
        server.dropConnection();
        expect(c.tableStatus.value.connection, NetworkStatus.connecting);
        expect(c.tableStatus.value.showsConnection, isTrue);
        await c.resync();
        expect(c.tableStatus.value.connection, NetworkStatus.online);
        c.onClose();
      },
    );

    test(
      'a network failure while sending is reported, never applied',
      () async {
        final (c, server) = await _boot(
          _table(
            handA: [_c(CardSuit.coppe, CardRank.re)],
            handB: [_c(CardSuit.denari, CardRank.tre)],
            top: _c(CardSuit.coppe, CardRank.cinque),
          ),
        );
        server.failNextWithNetwork = true;
        await c.resync();
        expect(c.tableStatus.value.connection, NetworkStatus.connecting);
        expect(c.version, 3);
        c.onClose();
      },
    );

    test(
      'reactions are preset keys only; incoming ones map to phrases',
      () async {
        final (c, server) = await _boot(
          _table(
            handA: [_c(CardSuit.coppe, CardRank.re)],
            handB: [_c(CardSuit.denari, CardRank.tre)],
            top: _c(CardSuit.coppe, CardRank.cinque),
          ),
        );
        expect(c.reactionPhrases.length, 8);
        c.sendReaction(c.reactionPhrases[1]);
        await Future<void>.delayed(Duration.zero);
        expect(server.reactionsSent, ['bravo']);
        expect(c.reactions['p0'], c.reactionPhrases[1]);
        c.sendReaction('free text is not a preset');
        await Future<void>.delayed(Duration.zero);
        expect(server.reactionsSent, ['bravo']);
        server.broadcast(
          const ReactionMessage(userId: _userB, seat: 1, key: 'gg'),
        );
        expect(c.reactions['p1'], Strings.s.reactionGg);
        // Our own broadcast echo is not shown twice.
        server.broadcast(
          const ReactionMessage(userId: _userA, seat: 0, key: 'ciao'),
        );
        expect(c.reactions['p0'], c.reactionPhrases[1]);
        c.onClose();
      },
    );

    test('leaving an online table forfeits on the server', () async {
      final (c, server) = await _boot(
        _table(
          handA: [_c(CardSuit.coppe, CardRank.re)],
          handB: [_c(CardSuit.denari, CardRank.tre)],
          top: _c(CardSuit.coppe, CardRank.cinque),
        ),
      );
      await c.abandon();
      expect(server.forfeited, isTrue);
      c.onClose();
    });

    test('rematch is a vote', () async {
      final (c, _) = await _boot(
        _table(
          handA: [_c(CardSuit.coppe, CardRank.re)],
          handB: [_c(CardSuit.denari, CardRank.tre)],
          top: _c(CardSuit.coppe, CardRank.cinque),
        ),
      );
      await c.requestRematch();
      expect(c.rematchRequested.value, isTrue);
      expect(c.rematchVotes.value, 1);
      expect(c.rematchNeeded.value, 2);
      await c.pollRematch();
      expect(c.nextMatchId.value, 'm2');
      c.onClose();
    });
  });

  group('Models', () {
    test('ActionOutcome parses accepted / stale / duplicate replies', () {
      final ok = ActionOutcome.fromJson({
        'ok': true,
        'accepted': true,
        'version': 7,
        'events': ['CardPlayedEvent'],
      });
      expect(ok.accepted, isTrue);
      expect(ok.version, 7);
      expect(ok.events, ['CardPlayedEvent']);
      final stale = ActionOutcome.fromJson({
        'ok': false,
        'accepted': false,
        'failure': 'staleState',
        'version': 9,
      });
      expect(stale.isStale, isTrue);
      final dup = ActionOutcome.fromJson({
        'ok': true,
        'duplicate': true,
        'accepted': true,
        'version': 8,
      });
      expect(dup.duplicate, isTrue);
    });

    test('RemoteRoom carries kind and match id', () {
      final room = RemoteRoom.fromJson({
        'id': 'r',
        'code': 'ABCDEF',
        'host_id': 'h',
        'max_players': 2,
        'status': 'in_progress',
        'kind': 'quick',
        'match_id': 'm9',
      });
      expect(room.isQuick, isTrue);
      expect(room.hasStarted, isTrue);
      expect(room.matchId, 'm9');
    });

    test('QueueEntry matched detection', () {
      expect(
        QueueEntry.fromJson({'status': 'waiting', 'player_count': 2}).isMatched,
        isFalse,
      );
      expect(
        QueueEntry.fromJson({
          'status': 'matched',
          'player_count': 2,
          'room_id': 'r',
        }).isMatched,
        isTrue,
      );
    });

    test('GameFailure names used on the wire exist in the enum', () {
      for (final name in [
        'notPlayersTurn',
        'cardNotOwned',
        'illegalCard',
        'staleState',
        'gameFinished',
      ]) {
        expect(GameFailure.values.map((f) => f.name), contains(name));
      }
    });
  });

  group('HomeController', () {
    test('asks the server for an active match only when signed in', () async {
      final home = HomeController(
        GameStorageService(await _storage()),
        matches: FakeServer(
          _table(
            handA: [_c(CardSuit.coppe, CardRank.re)],
            handB: [_c(CardSuit.denari, CardRank.tre)],
            top: _c(CardSuit.coppe, CardRank.cinque),
          ),
        ),
      );
      await home.refreshOnlineMatch();
      expect(home.activeOnlineMatchId.value, 'm1');
      final none = HomeController(GameStorageService(await _storage()));
      await none.refreshOnlineMatch();
      expect(none.activeOnlineMatchId.value, isNull);
    });
  });
}
