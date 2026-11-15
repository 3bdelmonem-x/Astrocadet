import 'package:flutter/material.dart';

/// أيقونة بيكسل للفوز والخسارة: كاس دهبي بيكسل للفوز، ودايرة حمرا فيها X للخسارة.
class PixelStatusIcon extends StatelessWidget {
  final bool won;
  final double size;

  const PixelStatusIcon({super.key, required this.won, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.square(size),
        painter: _PixelStatusPainter(won),
      ),
    );
  }
}

class _PixelStatusPainter extends CustomPainter {
  final bool won;
  const _PixelStatusPainter(this.won);

  static const int n = 16;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / n;
    Paint p(Color c) => Paint()
      ..color = c
      ..isAntiAlias = false;
    void px(int x, int y, Paint paint) => canvas.drawRect(
        Rect.fromLTWH(x * cell, y * cell, cell + 0.5, cell + 0.5), paint);
    void rect(int x, int y, int w, int h, Paint paint) {
      for (var j = 0; j < h; j++) {
        for (var i = 0; i < w; i++) {
          px(x + i, y + j, paint);
        }
      }
    }

    if (won) {
      // كاس بيكسل دهبي
      final dark = p(const Color(0xFF3A2606));
      final gold = p(const Color(0xFFFFC83D));
      final shade = p(const Color(0xFFC98A12));
      final light = p(const Color(0xFFFFF0A8));

      // جسم الكاس: إطار غامق
      rect(3, 0, 10, 1, dark);
      rect(3, 1, 1, 6, dark);
      rect(12, 1, 1, 6, dark);
      rect(4, 7, 1, 1, dark);
      rect(11, 7, 1, 1, dark);
      rect(5, 8, 1, 1, dark);
      rect(10, 8, 1, 1, dark);
      rect(6, 9, 4, 1, dark);
      // تعبئة دهبي
      rect(4, 1, 8, 6, gold);
      rect(5, 7, 6, 1, gold);
      rect(6, 8, 4, 1, gold);
      rect(10, 2, 1, 5, shade);
      rect(9, 7, 1, 1, shade);
      rect(5, 2, 1, 4, light);
      // الودان
      rect(0, 2, 3, 1, gold);
      rect(0, 6, 3, 1, gold);
      rect(0, 3, 1, 3, shade);
      rect(13, 2, 3, 1, gold);
      rect(13, 6, 3, 1, gold);
      rect(15, 3, 1, 3, shade);
      // الساق والقاعدة
      rect(6, 10, 1, 2, dark);
      rect(9, 10, 1, 2, dark);
      rect(7, 10, 2, 2, gold);
      rect(4, 12, 8, 3, dark);
      rect(5, 12, 6, 1, gold);
      rect(5, 13, 6, 1, shade);
      return;
    }

    // الخسارة: دايرة بيكسل حمرا فيها X
    const main = Color(0xFFFF4B4B);
    const shadeC = Color(0xFF9B1C1C);
    const outline = Color(0xFF0A0F18);
    const inside = Color(0xFF0D1E36);
    final pOut = p(outline), pMain = p(main), pShade = p(shadeC), pIn = p(inside);

    const c = (n - 1) / 2;
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        final dx = x - c, dy = y - c;
        final d2 = dx * dx + dy * dy;
        if (d2 > 8.6 * 8.6) continue;
        if (d2 > 7.6 * 7.6) {
          px(x, y, pOut);
        } else if (d2 > 5.9 * 5.9) {
          px(x, y, dy > 2 ? pShade : pMain);
        } else {
          px(x, y, pIn);
        }
      }
    }
    for (var i = 4; i <= 11; i++) {
      px(i, i, pMain);
      px(i + 1 > 11 ? i : i + 1, i, pMain);
      px(15 - i, i, pMain);
      px(15 - i - 1 < 4 ? 15 - i : 15 - i - 1, i, pMain);
    }
  }

  @override
  bool shouldRepaint(covariant _PixelStatusPainter old) => old.won != won;
}
