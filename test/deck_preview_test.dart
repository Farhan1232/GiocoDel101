import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gioco_del_101/features/game/domain/engine/deck_factory.dart';
import 'package:gioco_del_101/app/theme/app_colors.dart';
import 'package:gioco_del_101/app/theme/card_backs.dart';
import 'package:gioco_del_101/core/widgets/cards/playing_card.dart';

/// §66 — proves every one of the forty faces and every card back renders.
///
/// The contact sheet in `preview/` is written only when asked for, because
/// rasterising it through the software backend used by `flutter test` is slow:
///
/// ```
/// RENDER_PREVIEWS=1 flutter test test/deck_preview_test.dart --timeout none
/// ```
Future<void> _loadFonts() async {
  for (final entry in const [
    (
      'Cinzel',
      ['assets/fonts/Cinzel-Regular.ttf', 'assets/fonts/Cinzel-Bold.ttf'],
    ),
    (
      'Manrope',
      [
        'assets/fonts/Manrope-Regular.ttf',
        'assets/fonts/Manrope-Bold.ttf',
        'assets/fonts/Manrope-ExtraBold.ttf',
      ],
    ),
  ]) {
    final loader = FontLoader(entry.$1);
    for (final path in entry.$2) {
      loader.addFont(
        Future.value(ByteData.sublistView(File(path).readAsBytesSync())),
      );
    }
    await loader.load();
  }
}

void main() {
  testWidgets('all forty faces and every card back render', (tester) async {
    await _loadFonts();
    final deck = DeckFactory.ordered();
    expect(deck, hasLength(40));

    const cardWidth = 108.0;
    final key = GlobalKey();

    tester.view.physicalSize = const Size(1240, 1180);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(1240, 1180)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: RepaintBoundary(
            key: key,
            child: Container(
              color: AppColors.midnightNavy,
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var row = 0; row < 4; row++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var col = 0; col < 10; col++)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                              ),
                              child: PlayingCard(
                                width: cardWidth,
                                card: deck[row * 10 + col],
                              ),
                            ),
                        ],
                      ),
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final back in CardBacks.all)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: PlayingCard(
                            width: cardWidth,
                            faceUp: false,
                            backId: back.id,
                          ),
                        ),
                      const SizedBox(width: 24),
                      PlayingCard(width: cardWidth * 1.4, card: deck[8]),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(PlayingCard), findsNWidgets(45));

    if (Platform.environment['RENDER_PREVIEWS'] == '1') {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.6);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      Directory('preview').createSync(recursive: true);
      File(
        'preview/deck_contact_sheet.png',
      ).writeAsBytesSync(bytes!.buffer.asUint8List());
    }
  });
}
