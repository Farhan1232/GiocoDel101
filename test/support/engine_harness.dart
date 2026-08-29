import 'dart:math';

import 'package:gioco_del_101/features/game/domain/engine/game_engine.dart';
import 'package:gioco_del_101/features/game/domain/card_rank.dart';
import 'package:gioco_del_101/features/game/domain/card_suit.dart';
import 'package:gioco_del_101/features/game/domain/game_card.dart';
import 'package:gioco_del_101/features/game/domain/game_player.dart';
import 'package:gioco_del_101/features/game/domain/game_rules_config.dart';
import 'package:gioco_del_101/features/game/domain/match_state.dart';
import 'package:gioco_del_101/features/game/domain/player_type.dart';
import 'package:gioco_del_101/features/game/domain/round_state.dart';

GameCard c(CardSuit s, CardRank r) => GameCard(s, r);

/// Builds a fully determined table so rule tests never depend on a shuffle.
GameEngine buildEngine({
  required List<List<GameCard>> hands,
  required GameCard top,
  CardSuit? activeSuit,
  List<GameCard> drawPile = const [],
  List<GameCard> discardBelowTop = const [],
  GameRulesConfig rules = const GameRulesConfig(),
  List<int>? scores,
  int currentIndex = 0,
  int pendingPenalty = 0,
  int chainLength = 0,
  GameMode mode = GameMode.vsComputer,
}) {
  final players = <GamePlayer>[
    for (var i = 0; i < hands.length; i++)
      GamePlayer(
        id: 'p$i',
        name: 'P$i',
        type: i == 0 ? PlayerType.humanLocal : PlayerType.bot,
        avatarId: 'marco',
        difficulty: i == 0 ? null : BotDifficulty.normal,
        score: scores == null ? 0 : scores[i],
        hand: List.of(hands[i]),
      ),
  ];
  final round = RoundState(
    drawPile: List.of(drawPile),
    discardPile: [...discardBelowTop, top],
    activeSuit: activeSuit ?? top.suit,
    currentIndex: currentIndex,
    pendingPenalty: pendingPenalty,
    chainLength: chainLength,
  );
  return GameEngine.fromState(
    MatchState(players: players, rules: rules, round: round, mode: mode),
    random: Random(7),
  );
}
