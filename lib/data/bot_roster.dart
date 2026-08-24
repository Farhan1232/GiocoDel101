import 'dart:math';

import '../models/player_type.dart';

/// §22 — the four opponents, their temperaments and the medallion each one
/// wears. Personality changes how a bot weighs a move and which reaction it
/// throws out; it never changes what a bot is allowed to see.
class BotProfile {
  const BotProfile({
    required this.name,
    required this.avatarId,
    required this.personality,
    required this.blurb,
  });

  final String name;
  final String avatarId;
  final BotPersonality personality;
  final String blurb;
}

class BotRoster {
  const BotRoster._();

  static const List<BotProfile> all = [
    BotProfile(
      name: 'Marco',
      avatarId: 'marco',
      personality: BotPersonality.aggressive,
      blurb: 'Non si tiene mai un Asso in mano',
    ),
    BotProfile(
      name: 'Sofia',
      avatarId: 'sofia',
      personality: BotPersonality.tactical,
      blurb: 'Conserva le carte forti per il momento giusto',
    ),
    BotProfile(
      name: 'Luca',
      avatarId: 'luca',
      personality: BotPersonality.risky,
      blurb: 'Ogni tanto fa una giocata che non ti aspetti',
    ),
    BotProfile(
      name: 'Giulia',
      avatarId: 'giulia',
      personality: BotPersonality.calm,
      blurb: 'Controlla i semi con pazienza',
    ),
  ];

  /// Picks [count] distinct opponents, order shuffled.
  static List<BotProfile> pick(int count, Random random) {
    final pool = List<BotProfile>.of(all);
    for (var i = pool.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final tmp = pool[i];
      pool[i] = pool[j];
      pool[j] = tmp;
    }
    return pool.take(count.clamp(0, pool.length)).toList();
  }
}
