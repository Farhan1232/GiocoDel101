// Automated bot-vs-bot stress run over the pure rules engine.
//
// Plays full matches for every difficulty {easy, normal, hard} × player
// count {2, 3, 4}, every seat a bot of that difficulty with rotating
// personalities, and checks the engine's structural invariants after every
// applied action (card conservation, no duplicates, a top card always
// visible, a live seat to act, no negative counts, every bot proposal
// accepted, termination, a stable finished state, a winner). Violations
// are counted rather than thrown so one bad seed cannot hide another.
// Pure Dart — no Flutter:
//
//   dart run tool/bot_simulation.dart
//   SIM_MATCHES=100 dart run tool/bot_simulation.dart
//
// Options (env): SIM_MATCHES = matches per combination (default 30),
//                SIM_STEP_CAP = loop iterations before a match is a hang
//                (default 40000).
//
// Seeds are deterministic (combination index × 100000 + match index), so
// any violation printed here is reproducible with
// `BotSimulator.playMatch(difficulty, players, seed: …)`.
//
// Prints one block per combination, a compact overall table, and a final
// `RESULT:` line; exits 1 on any violation or hang.
import 'dart:io';

import 'package:gioco_del_101/features/game/domain/ai/bot_simulator.dart';

int _env(String name, int fallback) {
  final raw = Platform.environment[name];
  final parsed = raw == null ? null : int.tryParse(raw);
  if (raw != null && (parsed == null || parsed <= 0)) {
    stderr.writeln('$name must be a positive integer, got "$raw"');
    exit(2);
  }
  return parsed ?? fallback;
}

void main() {
  final matches = _env('SIM_MATCHES', 30);
  final stepCap = _env('SIM_STEP_CAP', BotSimulator.defaultStepCap);
  final combos = BotSimulator.combinations;

  stdout.writeln(
    'Bot simulation: ${combos.length} combinations × $matches matches, '
    'step cap $stepCap',
  );
  final total = Stopwatch()..start();

  // Run and print each combination as it completes so a slow or looping
  // configuration is visible before the whole run ends.
  final reports = <SimulationReport>[];
  for (var i = 0; i < combos.length; i++) {
    final (difficulty, players) = combos[i];
    final report = BotSimulator.runCombination(
      difficulty,
      players,
      matches: matches,
      comboIndex: i,
      stepCap: stepCap,
    );
    reports.add(report);
    stdout.writeln();
    for (final line in report.summaryLines()) {
      stdout.writeln(line);
    }
  }

  // ---- overall table ---------------------------------------------------
  stdout.writeln();
  stdout.writeln('================ OVERVIEW ================');
  final header = [
    'combination'.padRight(20),
    'matches'.padLeft(7),
    'actions'.padLeft(8),
    'rounds'.padLeft(7),
    'reshuf'.padLeft(7),
    'chains'.padLeft(7),
    'maxCh'.padLeft(6),
    'blocks'.padLeft(7),
    'skips'.padLeft(7),
    'x101'.padLeft(5),
    'penDrw'.padLeft(7),
    'viol'.padLeft(5),
    'hang'.padLeft(5),
    '  wins by seat',
  ].join(' ');
  stdout.writeln(header);
  stdout.writeln('-' * header.length);
  for (final r in reports) {
    stdout.writeln(
      [
        '${r.difficulty.name}/${r.playerCount}p'.padRight(20),
        '${r.matches}'.padLeft(7),
        '${r.actions}'.padLeft(8),
        '${r.rounds}'.padLeft(7),
        '${r.reshuffles}'.padLeft(7),
        '${r.chains}'.padLeft(7),
        '${r.maxChain}'.padLeft(6),
        '${r.cavalloBlocks}'.padLeft(7),
        '${r.assoSkips}'.padLeft(7),
        '${r.exact101}'.padLeft(5),
        '${r.penaltyDraws}'.padLeft(7),
        '${r.violationCount}'.padLeft(5),
        '${r.hangs}'.padLeft(5),
        '  ${r.winsBySeat.join('/')}',
      ].join(' '),
    );
  }

  final totalMatches = reports.fold(0, (n, r) => n + r.matches);
  final totalActions = reports.fold(0, (n, r) => n + r.actions);
  final violations = reports.fold(0, (n, r) => n + r.violationCount);
  final hangs = reports.fold(0, (n, r) => n + r.hangs);
  final illegal = reports.fold(0, (n, r) => n + r.illegalProposals);
  final unstable = reports.fold(0, (n, r) => n + r.finishedUnstable);

  stdout.writeln();
  stdout.writeln(
    '$totalActions actions in ${total.elapsed.inMilliseconds}ms '
    '(illegal proposals $illegal, unstable finishes $unstable)',
  );
  stdout.writeln(
    'RESULT: $totalMatches matches, $violations violations, $hangs hangs',
  );
  exit(violations == 0 && hangs == 0 ? 0 : 1);
}
