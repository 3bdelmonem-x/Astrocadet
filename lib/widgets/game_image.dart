import 'package:flutter/material.dart' hide Text;
import 'game_text.dart';
import 'smart_asset.dart';

/// صورة من assets. لو الملف مش موجود بيظهر مربع أحمر مكتوب عليه اسم الملف
/// (عشان تعرفي بالظبط أنهي اسم غلط).
class GameImage extends StatelessWidget {
  final String path;
  final double? height;
  final double? width;
  final BoxFit fit;

  const GameImage(
    this.path, {
    super.key,
    this.height,
    this.width,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    final h = height;
    final size = decodeSizeFor(context, width, h);
    return Image.asset(
      path,
      height: h,
      width: width,
      fit: fit,
      cacheWidth: size.w,
      cacheHeight: size.h,
      gaplessPlayback: true,
      errorBuilder: (c, o, s) => SizedBox(
        width: width ?? 80,
        height: (h == null || h < 40) ? 40 : h,
        child: FittedBox(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.broken_image, color: Colors.redAccent),
              Text(
                path.split('/').last,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// خلفية بملء الشاشة. لو الصورة مش موجودة بيظهر لون بديل (أو مفيش حاجة لو null).
class GameBackground extends StatelessWidget {
  final String path;
  final Color? fallbackColor;

  const GameBackground(this.path, {super.key, this.fallbackColor});

  @override
  Widget build(BuildContext context) {
    final size = decodeSizeFor(context, double.infinity, null);
    return Image.asset(
      path,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      cacheWidth: size.w,
      errorBuilder: (c, o, s) => fallbackColor == null
          ? const SizedBox.shrink()
          : Container(color: fallbackColor),
    );
  }
}

/// خلفية الفضا (space.png) بملء الشاشة. الشاشة اللي جواها لازم تكون Scaffold
/// بخلفية شفافة (backgroundColor: Colors.transparent).
class SpaceBackground extends StatelessWidget {
  final Widget child;

  const SpaceBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        SmartImage(
          folders: const [''],
          names: const ['space'],
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          fallback: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B1140), Color(0xFF080D25)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
