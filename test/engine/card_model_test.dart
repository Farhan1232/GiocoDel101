import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gioco_del_101/features/game/domain/card_rank.dart';
import 'package:gioco_del_101/features/game/domain/card_suit.dart';
import 'package:gioco_del_101/features/game/domain/game_card.dart';

void main() {
  group('40-card model', () {
    test('the deck holds exactly 40 cards', () {
      expect(Deck.standard, hasLength(40));
      expect(Deck.size, 40);
    });

    test('every card is unique by identity and by id', () {
      expect(Deck.standard.toSet(), hasLength(40));
      expect(Deck.standard.map((c) => c.id).toSet(), hasLength(40));
    });

    test('ten cards per suit, four per rank', () {
      for (final suit in CardSuit.values) {
        expect(Deck.standard.where((c) => c.suit == suit), hasLength(10));
      }
      for (final rank in CardRank.values) {
        expect(Deck.standard.where((c) => c.rank == rank), hasLength(4));
      }
    });

    test('the four suits and ten ranks are exactly the Neapolitan set', () {
      expect(CardSuit.values.map((s) => s.name), [
        'denari',
        'coppe',
        'spade',
        'bastoni',
      ]);
      expect(CardRank.values.map((r) => r.name), [
        'asso',
        'due',
        'tre',
        'quattro',
        'cinque',
        'sei',
        'sette',
        'fante',
        'cavallo',
        're',
      ]);
      expect(CardRank.values.map((r) => r.value), [
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
      expect(CardRank.cavallo.value, 9, reason: 'the Cavallo is the "9"');
    });

    test('value equality and hashing', () {
      const a = GameCard(CardSuit.denari, CardRank.asso);
      const b = GameCard(CardSuit.denari, CardRank.asso);
      const c = GameCard(CardSuit.coppe, CardRank.asso);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
      expect(<GameCard>{a, c, GameCard(a.suit, a.rank)}, hasLength(2));
    });

    test('ids are stable and not derived from any file name', () {
      const card = GameCard(CardSuit.spade, CardRank.cavallo);
      expect(card.id, 'spade_cavallo');
      expect(card.asset.imagePath, 'assets/cards/spade_cavallo.png');
      expect(card.asset.isFigure, isTrue);
      expect(card.asset.suitKey, 'spade');
      expect(card.asset.rankKey, 'cavallo');
      expect(const GameCard(CardSuit.coppe, CardRank.sette).asset.pipCount, 7);
      expect(Deck.byId('spade_cavallo'), card);
      expect(Deck.byId('nonsense'), isNull);
    });

    test('JSON round-trips through both the object and the id forms', () {
      for (final card in Deck.standard) {
        final json = jsonDecode(jsonEncode(card.toJson()));
        expect(GameCard.fromJson(json), card);
        expect(GameCard.fromJson(card.id), card);
        expect(GameCard.fromStorage(card.toStorage()), card);
      }
    });

    test('legacy English rank keys are still readable', () {
      expect(
        GameCard.fromStorage('denari_ace'),
        const GameCard(CardSuit.denari, CardRank.asso),
      );
      expect(
        GameCard.fromStorage('coppe_seven'),
        const GameCard(CardSuit.coppe, CardRank.sette),
      );
      expect(CardRank.fromKey('two'), CardRank.due);
    });

    test('malformed tokens are rejected', () {
      expect(() => GameCard.fromStorage('nonsense'), throwsFormatException);
      expect(
        () => GameCard.fromStorage('denari_undici'),
        throwsFormatException,
      );
      expect(() => GameCard.fromStorage('cuori_asso'), throwsFormatException);
      expect(() => GameCard.fromJson(42), throwsFormatException);
    });

    test('special-card flags', () {
      expect(const GameCard(CardSuit.denari, CardRank.asso).isAsso, isTrue);
      expect(const GameCard(CardSuit.denari, CardRank.due).isDue, isTrue);
      expect(
        const GameCard(CardSuit.denari, CardRank.cavallo).isCavallo,
        isTrue,
      );
      expect(const GameCard(CardSuit.denari, CardRank.re).isAction, isFalse);
      expect(Deck.standard.where((c) => c.isAction), hasLength(12));
    });
  });
}
