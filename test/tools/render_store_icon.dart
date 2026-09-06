// Renders the Play Store listing icon from the game's own mark.
//
// The launcher icon in `android/app/src/main/res` tops out at 192 px, and
// Google Play wants 512 x 512. Rather than upscale a bitmap, this repaints
// the medallion — the navy field, the milled gold coin and the engraved 101 —
// as vectors at 1024 px, so the downscale to 512 is clean.
//
//   flutter test test/tools/render_store_icon.dart
//
// Writes store/icon_1024.png. Colours and proportions are sampled from the
// shipped launcher icon so the store listing and the phone home screen show
// the same mark.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const double kSize = 1024;

/// Sampled from `mipmap-xxxhdpi/ic_launcher.png` / `_foreground.png`.
const Color kFieldTop = Color(0xFF141D38);
const Color kFieldBottom = Color(0xFF0B1020);
const Color kFaceLight = Color(0xFFF0DCA8);
const Color kFaceMid = Color(0xFFE4CA90);
const Color kFaceDeep = Color(0xFFC39A55);
const Color kFaceEdge = Color(0xFFA17B3A);
const Color kRim = Color(0xFF8D611D);
const Color kReed = Color(0xFF4B3310);
const Color kRimLight = Color(0xFFC9A25E);
const Color kEngraved = Color(0xFF4A3210);
const Color kBevel = Color(0xFFC3A366);

class StoreIconPainter extends CustomPainter {
  const StoreIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final rect = Offset.zero & size;

    // The field. Brighter at the top-left, as the shipped icon is.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kFieldTop, kFieldBottom],
        ).createShader(rect),
    );

    final c = Offset(s / 2, s / 2);
    final r = s * 0.365; // 73% of the square, matching the launcher icon.

    // Milled edge: a gold ring cut by radial ticks.
    canvas.drawCircle(c, r, Paint()..color = kRim);
    const ticks = 96;
    final tickPaint = Paint()
      ..color = kReed
      ..strokeWidth = s * 0.0085
      ..strokeCap = StrokeCap.butt;
    for (var i = 0; i < ticks; i++) {
      final a = (i / ticks) * 2 * math.pi;
      final d = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + d * (r * 0.905), c + d * r, tickPaint);
    }

    // The bright inner rim line.
    canvas.drawCircle(
      c,
      r * 0.90,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.006
        ..color = kRimLight,
    );

    // The struck face.
    final faceRect = Rect.fromCircle(center: c, radius: r * 0.885);
    canvas.drawCircle(
      c,
      r * 0.885,
      Paint()
        ..shader = ui.Gradient.radial(
          c + Offset(-r * 0.22, -r * 0.26),
          r * 1.15,
          const [kFaceLight, kFaceMid, kFaceDeep, kFaceEdge],
          const [0.0, 0.28, 0.72, 1.0],
        ),
    );

    // The engraved circle inside the rim.
    canvas.drawCircle(
      c,
      r * 0.775,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.005
        ..color = kRim.withValues(alpha: 0.55),
    );

    // "101", struck into the metal: a light bevel below, the cut above.
    void numerals(Color colour, Offset shift) {
      final painter = TextPainter(
        text: TextSpan(
          text: '101',
          style: TextStyle(
            fontFamily: 'Cinzel',
            fontWeight: FontWeight.w700,
            fontSize: r * 0.62,
            color: colour,
            height: 1.0,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        c - Offset(painter.width / 2, painter.height / 2) + shift,
      );
    }

    numerals(kBevel.withValues(alpha: 0.85), Offset(0, s * 0.006));
    numerals(kEngraved, Offset.zero);

    // A soft sheen across the upper half, so the coin reads as metal.
    canvas.save();
    canvas.clipPath(Path()..addOval(faceRect));
    canvas.drawRect(
      faceRect,
      Paint()
        ..shader = ui.Gradient.linear(
          faceRect.topCenter,
          faceRect.centerLeft,
          [Colors.white.withValues(alpha: 0.16), Colors.white.withValues(alpha: 0.0)],
        ),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(StoreIconPainter oldDelegate) => false;
}

Future<void> _fonts() async {
  final loader = FontLoader('Cinzel');
  for (final path in const [
    'assets/fonts/Cinzel-Regular.ttf',
    'assets/fonts/Cinzel-SemiBold.ttf',
    'assets/fonts/Cinzel-Bold.ttf',
  ]) {
    loader.addFont(
      Future.value(ByteData.sublistView(File(path).readAsBytesSync())),
    );
  }
  await loader.load();
}

void main() {
  testWidgets('render the store icon', (tester) async {
    await _fonts();
    final key = GlobalKey();
    tester.view.physicalSize = const Size(kSize, kSize);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: const SizedBox(
          width: kSize,
          height: kSize,
          child: CustomPaint(painter: StoreIconPainter()),
        ),
      ),
    );
    await tester.pump();

    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    Directory('store').createSync(recursive: true);
    File('store/icon_1024.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    stdout.writeln('wrote store/icon_1024.png');
  });
}
