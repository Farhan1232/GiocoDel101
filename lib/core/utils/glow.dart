import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Soft light without a blur filter.
///
/// §54 — `MaskFilter.blur` is the single most expensive primitive the game
/// could reach for, and the table wants a lot of soft light. A radial gradient
/// that fades to transparent gives the same halo for a fraction of the cost,
/// and stays cheap on low-end hardware where blurs fall off a cliff.
class Glow {
  const Glow._();

  /// A round halo centred on [centre], fading out by [radius].
  static void circle(
    Canvas canvas,
    Offset centre,
    double radius,
    Color color, {
    double core = 0.35,
  }) {
    if (radius <= 0 || color.a == 0) return;
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..shader = ui.Gradient.radial(
          centre,
          radius,
          [color, color.withValues(alpha: color.a * 0.55), color.withValues(alpha: 0)],
          [0.0, core.clamp(0.05, 0.9), 1.0],
        ),
    );
  }

  /// An elliptical halo, used for the shadow the felt casts on the table.
  static void oval(Canvas canvas, Rect rect, Color color, {double core = 0.55}) {
    if (rect.isEmpty || color.a == 0 || rect.width <= 0) return;
    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.scale(1.0, rect.height / rect.width);
    circle(canvas, Offset.zero, rect.width / 2, color, core: core);
    canvas.restore();
  }
}
