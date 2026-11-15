import 'package:flutter/material.dart';
import '../game/crew.dart';
import 'smart_asset.dart';

/// صورة الشخصية: لو في صورة بتظهر، ولو لأ بنستخدم تعبير من تعبيرات القائدة
/// (placeholder) بحدود بلون الشخصية، ولو مفيش بنرسم أيقونة.
class CrewAvatar extends StatelessWidget {
  final CrewMember member;
  final double size;

  const CrewAvatar({super.key, required this.member, this.size = 48});

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(member.icon, size: size * 0.55, color: Colors.black);
    final portrait = member.portrait;

    final Widget content;
    if (portrait != null) {
      final dec = decodeSizeFor(context, size, null);
      content = Image.asset(
        portrait,
        cacheWidth: dec.w,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.none,
        errorBuilder: (c, o, s) => fallback,
      );
    } else {
      content = SmartImage.one(
        kSolar,
        'Commander-${member.placeholderMood}',
        fit: BoxFit.cover,
        fallback: fallback,
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: member.color,
        borderRadius: BorderRadius.circular(size * 0.18),
        border: Border.all(color: member.color == Colors.cyan ? Colors.white70 : member.color, width: 3),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.14),
        child: content,
      ),
    );
  }
}
