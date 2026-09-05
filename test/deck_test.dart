import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gioco_del_101/features/game/domain/engine/deck_factory.dart';
import 'package:gioco_del_101/features/game/domain/card_rank.dart';
import 'package:gioco_del_101/features/game/domain/card_suit.dart';
import 'package:gioco_del_101/features/game/domain/game_card.dart';

void main() {
  group('Neapolitan deck', () {
    test('holds exactly 40 cards', () {
      expect(DeckFactory.ordered(), hasLength(40));
      expect(DeckFactory.shuffled(Random(1)), hasLength(40));
    });

    test('contains no duplicates', () {
      final deck = DeckFactory.shuffled(Random(3));
      expect(deck.map((c) => c.id).toSet(), hasLength(40));
    });

    test('has ten ranks in each of four suits', () {
      final deck = DeckFactory.ordered();
      for (final suit in CardSuit.values) {
        final ofSuit = deck.where((c) => c.suit == suit).toList();
        expect(ofSuit, hasLength(10));
        expect(ofSuit.map((c) => c.rank).toSet(), CardRank.values.toSet());
      }
    });

    test('maps ranks to 1..10 with Fante/Cavallo/Re as 8/9/10', () {
      expect(CardRank.asso.value, 1);
      expect(CardRank.sette.value, 7);
      expect(CardRank.fante.value, 8);
      expect(CardRank.cavallo.value, 9);
      expect(CardRank.re.value, 10);
      expect(CardRank.values.map((r) => r.value).toList(), [
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
      ]);
    });

    test('shuffle is reproducible for a given seed', () {
      final a = DeckFactory.shuffled(Random(2026)).map((c) => c.id).toList();
      final b = DeckFactory.shuffled(Random(2026)).map((c) => c.id).toList();
      expect(a, b);
    });

    test('card ids round-trip through storage', () {
      for (final card in DeckFactory.ordered()) {
        expect(GameCard.fromStorage(card.toStorage()), card);
      }
    });
  });
}
