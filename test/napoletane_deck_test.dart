// The printed Carte Napoletane deck — that the forty files exist, decode,
// and are what actually reaches the screen.
//
// `test/deck_preview_test.dart` proves every card *renders*; because
// `Image.asset` decodes asynchronously it renders the engraved fallback on a
// first frame, which is the right behaviour but does not prove the artwork
// loads. This file precaches first, so what it checks is the real thing.
//
// A contact sheet of the deck as the app draws it can be written out with:
//
//   RENDER_PREVIEWS=1 flutter test test/napoletane_deck_test.dart --timeout none
//
// which lands in preview/napoletane_deck.png.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gioco_del_101/core/widgets/cards/card_face_image.dart';
import 'package:gioco_del_101/core/widgets/cards/card_face_painter.dart';
import 'package:gioco_del_101/features/game/domain/card_rank.dart';
import 'package:gioco_del_101/features/game/domain/card_suit.dart';
import 'package:gioco_del_101/features/game/domain/game_card.dart';
import 'package:gioco_del_101/core/widgets/cards/playing_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Carte Napoletane deck', () {
    test('forty files ship, one per card, and nothing else', () {
      final shipped = <String>{
        for (final card in Deck.standard) card.asset.imagePath,
      };
      expect(shipped, hasLength(40), reason: 'a path collides');

      final onDisk = Directory('assets/cards')
          .listSync()
          .whereType<File>()
          .map((f) => 'assets/cards/${f.uri.pathSegments.last}')
          .where((p) => p.endsWith('.webp'))
          .toSet();

      // Exactly the deck: no card without a file, no file without a card.
      expect(
        onDisk.difference(shipped),
        isEmpty,
        reason: 'files in assets/cards that no card maps to',
      );
      expect(
        shipped.difference(onDisk),
        isEmpty,
        reason: 'cards with no artwork on disk',
      );
    });

    test(
      'every file decodes, and the whole deck is one size at 1.55',
      () async {
        final sizes = <String>{};
        for (final card in Deck.standard) {
          final data = await rootBundle.load(card.asset.imagePath);
          expect(
            data.lengthInBytes,
            greaterThan(1000),
            reason: '${card.id} is suspiciously small',
          );
          final codec = await ui.instantiateImageCodec(
            data.buffer.asUint8List(),
          );
          final frame = await codec.getNextFrame();
          final image = frame.image;
          sizes.add('${image.width}x${image.height}');
          expect(
            image.height / image.width,
            closeTo(1.55, 0.01),
            reason: '${card.id} is not the card aspect the table lays out',
          );
          image.dispose();
          codec.dispose();
        }
        // One size for the whole deck: the scale must be uniform, or a coin on
        // the Sette would not match a coin on the Due.
        expect(
          sizes,
          hasLength(1),
          reason: 'the deck is not one uniform size: $sizes',
        );
      },
    );

    test('the licence travels with the assets', () async {
      final licence = await rootBundle.loadString('assets/cards/LICENSE.txt');
      expect(licence, contains('Public domain'));
      expect(licence, contains('commons.wikimedia.org'));
      expect(licence, contains('Carte_napoletane_al_completo'));
    });

    testWidgets('every card draws its own printed face, not the fallback', (
      tester,
    ) async {
      // Pin the device pixel ratio so the decode width the widget asks for is
      // known, then warm exactly that provider. Without this every card would
      // still be showing the engraved fallback when the frame is captured,
      // and the test would prove nothing about the artwork.
      const cardWidth = 84.0;
      const ratio = 1.0;
      // Big enough for a 10 x 4 grid of cards; the default 800 x 600 surface
      // would clip the last two columns.
      tester.view.physicalSize = const Size(1000, 700);
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);
      final cacheWidth = CardFaceImage.decodeWidth(cardWidth, ratio);
      await tester.runAsync(() async {
        for (final card in Deck.standard) {
          await precacheImage(
            ResizeImage(
              AssetImage(card.asset.imagePath),
              width: cacheWidth,
              allowUpscaling: false,
            ),
            _DummyContext(),
          );
        }
      });

      final key = GlobalKey();
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(devicePixelRatio: ratio),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: RepaintBoundary(
              key: key,
              child: ColoredBox(
                color: const Color(0xFF0B1327),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final suit in CardSuit.values)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final rank in CardRank.values)
                              Padding(
                                padding: const EdgeInsets.all(4),
                                child: PlayingCard(
                                  width: cardWidth,
                                  card: GameCard(suit, rank),
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(CardFaceImage), findsNWidgets(40));

      // The real proof: not one card is still on the engraved fallback, so
      // what was rasterised below is forty printed Napoletane faces.
      expect(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is CardFacePainter,
        ),
        findsNothing,
        reason: 'a card fell back to the painter instead of its printed face',
      );

      // …and every one is pointing at an asset in the deck folder.
      for (final image in tester.widgetList<Image>(find.byType(Image))) {
        final provider = image.image;
        expect(provider, isA<ResizeImage>());
        final inner = (provider as ResizeImage).imageProvider;
        expect(inner, isA<AssetImage>());
        expect((inner as AssetImage).assetName, startsWith('assets/cards/'));
      }

      expect(tester.takeException(), isNull);

      if (Platform.environment['RENDER_PREVIEWS'] == '1') {
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 1.4);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          Directory('preview').createSync(recursive: true);
          File(
            'preview/napoletane_deck.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      }
    });
  });
}

/// `precacheImage` only needs a context to find the ambient configuration;
/// an empty one resolves an [AssetImage] against the root bundle, which is
/// exactly what the app does.
class _DummyContext extends BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
