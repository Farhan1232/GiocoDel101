import '../../../app/localization/app_strings.dart';
import '../../../features/game/domain/game_card.dart';

/// The spoken name of a card in the player's language — "Cavallo di Spade",
/// "Knight of Swords" — for screen readers and the replay sheet.
String cardDisplayName(GameCard card) {
  final s = Strings.s;
  final rank = switch (card.rank.name) {
    'asso' => s.rankAce,
    'fante' => s.rankFante,
    'cavallo' => s.rankCavallo,
    're' => s.rankRe,
    _ => '${card.rank.value}',
  };
  final suit = switch (card.suit.name) {
    'denari' => s.suitDenari,
    'coppe' => s.suitCoppe,
    'spade' => s.suitSpade,
    _ => s.suitBastoni,
  };
  return s.cardName(rank, suit);
}
