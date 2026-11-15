import 'dart:async';
import 'package:flutter/material.dart' hide Text;
import 'game_text.dart';
import '../game/crew.dart';
import '../audio/audio_service.dart';
import 'crew_avatar.dart';
import 'typewriter_text.dart';
import 'smart_asset.dart';
import '../localization/game_localization.dart';

/// لوحة داكنة بحدود سماوية (شكل الـ Figma)
class PixelPanel extends StatelessWidget {
  final Widget child;
  final Color borderColor;
  final EdgeInsets padding;
  final double? width;
  final double? height;

  const PixelPanel({
    super.key,
    required this.child,
    this.borderColor = Colors.cyan,
    this.padding = const EdgeInsets.all(8),
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF070B14).withValues(alpha: 0.94),
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(3),
      ),
      child: child,
    );
  }
}

/// زرار: لو صورة الزرار موجودة في الـ assets بيستخدمها، وإلا بيرسم زرار بنفس الشكل.
/// onTap = null يعني الزرار مقفول.
class PixelButton extends StatelessWidget {
  final String label;
  final List<String> assetNames;
  final VoidCallback? onTap;
  final Color color;
  final double height;
  final double? width;
  // صوت الضغط (null = مفيش صوت). الزرار المقفول بيطلع صوت الرفض ui_denied.
  final String? sound;

  const PixelButton({
    super.key,
    required this.label,
    this.assetNames = const [],
    this.onTap,
    this.color = Colors.cyan,
    this.height = 30,
    this.width,
    this.sound = 'ui_tap',
  });

  Widget _textButton() {
    return Container(
      height: height,
      width: width,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1E36),
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        gameText(label),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget child = assetNames.isEmpty
        ? _textButton()
        : SmartImage.any(
            kBase,
            assetNames,
            height: height,
            width: width,
            fallback: _textButton(),
          );
    return Opacity(
      opacity: onTap == null ? 0.4 : 1,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          final tap = onTap;
          if (tap == null) {
            audio.sfx('ui_denied', volume: 0.6);
            return;
          }
          final snd = sound;
          if (snd != null) audio.sfx(snd);
          tap();
        },
        child: child,
      ),
    );
  }
}

/// زرار الرجوع (Button-Back)
class BackPixelButton extends StatelessWidget {
  final Color color;
  const BackPixelButton({super.key, this.color = Colors.cyan});

  @override
  Widget build(BuildContext context) {
    return PixelButton(
      label: 'BACK',
      assetNames: const ['Button-Back'],
      color: color,
      height: 30,
      sound: null,
      onTap: () => Navigator.pop(context),
    );
  }
}

/// صندوق المعلومات اللي فوق يسار (زي "SOLAR FIELD / Panels: 6")
class InfoBox extends StatelessWidget {
  final String title;
  final List<String> lines;
  final Color color;

  const InfoBox({
    super.key,
    required this.title,
    required this.lines,
    this.color = Colors.cyan,
  });

  @override
  Widget build(BuildContext context) {
    return PixelPanel(
      borderColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                gameText(title),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          for (final l in lines)
            Text(gameText(l), style: TextStyle(color: color, fontSize: 9)),
        ],
      ),
    );
  }
}

/// صندوق الحوار: صورة المتكلم + اسمه + النص
class DialogueBox extends StatelessWidget {
  final CrewMember speaker;
  final String mood; // لتعبير نادية فقط
  final String text;

  const DialogueBox({
    super.key,
    required this.speaker,
    required this.text,
    this.mood = 'Neutral',
  });

  // المزاج بيغيّر نغمة الصوت شوية

  @override
  Widget build(BuildContext context) {
    final isCommander = speaker.id == nadia.id;
    return PixelPanel(
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          isCommander
              ? CommanderPortrait(mood: mood, size: 66)
              : CrewAvatar(member: speaker, size: 66),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1E36),
                    border: Border.all(color: speaker.color),
                  ),
                  child: Text(
                    gameText(isCommander ? 'Commander' : speaker.title),
                    style: TextStyle(
                      color: speaker.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: TypewriterText(
                    text: gameText(text),
                    maxLines: 4,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// صف مورد في تقرير الصبح وتقرير آخر اليوم: الأيقونة، قبل، شريط، بعد، سهم
class ResourceRow extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double before;
  final double after;
  final double max;
  final bool badWhenUp; // الإشعاع: الزيادة وحشة
  final bool showMax; // اكتب "/100" بدل الرقم بعد
  final int index; // ترتيب الصف في التقرير (للظهور المتتابع)
  final bool animate; // يظهر صف صف مع صوت tick

  const ResourceRow({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.before,
    required this.after,
    this.max = 100,
    this.badWhenUp = false,
    this.showMax = false,
    this.index = 0,
    this.animate = false,
  });

  @override
  State<ResourceRow> createState() => _ResourceRowState();
}

class _ResourceRowState extends State<ResourceRow> {
  late bool _visible = !widget.animate;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _timer = Timer(Duration(milliseconds: 120 + widget.index * 140), () {
        if (!mounted) return;
        setState(() => _visible = true);
        // tick بنغمة بتعلى مع كل صف
        audio.sfx('report_row', volume: 0.5, rate: 1.0 + widget.index * 0.08);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = widget.icon;
    final label = widget.label;
    final color = widget.color;
    final before = widget.before;
    final after = widget.after;
    final max = widget.max;
    final badWhenUp = widget.badWhenUp;
    final showMax = widget.showMax;
    final delta = after - before;
    final up = delta > 0.001;
    final down = delta < -0.001;
    final good = badWhenUp ? down : up;
    final low = badWhenUp ? after >= 60 : after <= 25;
    final double progress = max <= 0
        ? 0.0
        : (after / max).clamp(0.0, 1.0).toDouble();

    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        margin: const EdgeInsets.only(bottom: 5),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1E36),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: low ? Colors.redAccent : Colors.cyan,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 5),
            SizedBox(
              width: 74,
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            SizedBox(
              width: 26,
              child: Text(
                before.round().toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 62,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    showMax
                        ? '${after.round()}/${max.round()}'
                        : after.round().toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  if (up || down)
                    Text(
                      up ? '▲' : '▼',
                      style: TextStyle(
                        color: good ? Colors.greenAccent : Colors.redAccent,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            if (low)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  badWhenUp ? 'HIGH!!' : 'LOW!!',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
