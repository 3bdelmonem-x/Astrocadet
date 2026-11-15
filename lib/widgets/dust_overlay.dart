import 'package:flutter/material.dart';
import 'smart_asset.dart';

/// تراب متحرك فوق المشهد (dust1.png) أثناء العاصفة.
/// طبقتين بتتحركوا عكس بعض بسرعات مختلفة، ومن غير ما نكرر الصورة جنب بعضها
/// (عشان مايبانش خط وصل). بيتحط في الشاشة بس وقت العاصفة، فمبيستهلكش حاجة باقي الوقت.
class DustOverlay extends StatefulWidget {
  /// مدى الحركة يمين وشمال بنسبة من عرض الشاشة
  final double drift;
  const DustOverlay({super.key, this.drift = 0.05});

  @override
  State<DustOverlay> createState() => _DustOverlayState();
}

class _DustOverlayState extends State<DustOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _a = AnimationController(
      vsync: this, duration: const Duration(seconds: 7))
    ..repeat(reverse: true);
  late final AnimationController _b = AnimationController(
      vsync: this, duration: const Duration(seconds: 11))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    super.dispose();
  }

  Widget _layer(AnimationController c, double dir, double opacity,
      double scale, BoxConstraints box) {
    return AnimatedBuilder(
      animation: c,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(c.value) - 0.5; // -0.5 .. 0.5
        return Opacity(
          opacity: opacity * (0.8 + 0.2 * (t + 0.5)),
          child: Transform.translate(
            offset: Offset(t * 2 * widget.drift * box.maxWidth * dir,
                t * 0.01 * box.maxHeight),
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
      // scale > 1 عشان أطراف الصورة متظهرش وهي بتتحرك
      child: SmartImage.any(
        kBase,
        const ['dust1'],
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        fallback: Container(color: Colors.orange.withValues(alpha: 0.12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: LayoutBuilder(
          builder: (context, box) => Stack(
            fit: StackFit.expand,
            children: [
              _layer(_a, 1, 0.75, 1.14, box),
              _layer(_b, -1, 0.45, 1.25, box),
            ],
          ),
        ),
      ),
    );
  }
}
