import 'dart:async';
import 'package:flutter/material.dart';
import '../audio/audio_service.dart';

/// سرعة الكتابة: رقم واحد لكل الشخصيات وكل الشاشات (حرف في الثانية).
/// عايز أسرع أو أبطأ؟ غيّر الرقم ده بس.
const double kTypeCharsPerSecond = 28;

/// نص بيتكتب حرف حرف (typewriter) من غير أصوات كلام.
/// الضغط على النص بيكمّله على طول. بيعيد الكتابة لو النص اتغير.
class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final int maxLines;

  const TypewriterText({
    super.key,
    required this.text,
    required this.style,
    this.maxLines = 4,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  Timer? _timer;
  int _shown = 0;
  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(TypewriterText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) _start();
  }

  void _start() {
    _timer?.cancel();
    _shown = 0;
    final ms = (1000 / kTypeCharsPerSecond).round();
    _timer = Timer.periodic(Duration(milliseconds: ms), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      final text = widget.text;
      if (_shown >= text.length) {
        t.cancel();
        return;
      }
      setState(() => _shown++);
      if (_shown >= text.length) {
        t.cancel();
        audio.sfx('ui_tap', volume: 0.2);
      }
    });
  }

  void _skip() {
    _timer?.cancel();
    if (_shown < widget.text.length) {
      setState(() => _shown = widget.text.length);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.text;
    final n = _shown.clamp(0, text.length);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _skip,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: text.substring(0, n)),
            // الجزء اللي لسه مكتبش: شفاف عشان الأبعاد متتغيرش
            TextSpan(
              text: text.substring(n),
              style: const TextStyle(color: Colors.transparent),
            ),
          ],
        ),
        style: widget.style,
        maxLines: widget.maxLines,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
