import 'package:flutter_test/flutter_test.dart';
import 'package:gioco_del_101/features/game/domain/ai/bot_simulator.dart';
import 'package:gioco_del_101/features/game/domain/player_type.dart';

/// Full bot-vs-bot matches for every difficulty × table size, with the
/// engine's structural invariants checked after every applied action.
///
/// The heavy lifting lives in [BotSimulator] so `tool/bot_simulation.dart`
/// can run the same checks at scale; this test keeps a small, seeded slice
/// of it in the regular suite. Seeds are fixed, so a failure here prints a
/// seed that reproduces it in the tool.
void main() {
  const matchesPerCombination = 6;

  group('Bot simulation keeps the engine invariants', () {
    final combos = BotSimulator.combinations;
    for (var i = 0; i < combos.length; i++) {
      final (difficulty, players) = combos[i];
      test('${difficulty.name} × $players players', () {
        final report = BotSimulator.runCombination(
          difficulty,
          players,
          matches: matchesPerCombination,
          comboIndex: i,
        );

        final detail = report.summaryLines().join('\n');
        expect(report.hangs, 0, reason: 'hangs\n$detail');
        expect(
          report.illegalProposals,
          0,
          reason: 'illegal bot proposals\n$detail',
        );
        expect(
          report.finishedUnstable,
          0,
          reason: 'finished state moved\n$detail',
        );
        expect(report.violations, isEmpty, reason: detail);

        // Sanity: the run really played matches, not empty loops.
        expect(report.actions, greaterThan(0));
        expect(report.rounds, greaterThanOrEqualTo(matchesPerCombination));
        expect(
          report.winsBySeat.fold(0, (n, w) => n + w),
          matchesPerCombination,
          reason: 'every match must name a winner',
        );
      });
    }
  });

  test('the same seed replays the same match', () {
    final a = BotSimulator.playMatch(BotDifficulty.hard, 3, seed: 4242);
    final b = BotSimulator.playMatch(BotDifficulty.hard, 3, seed: 4242);
    expect(a.violations, isEmpty);
    expect(a.finished, isTrue);
    expect(a.steps, b.steps);
    expect(a.winnerSeat, b.winnerSeat);
  });
}
