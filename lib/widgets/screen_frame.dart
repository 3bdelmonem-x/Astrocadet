import 'package:flutter/material.dart' hide Text;
import 'game_text.dart';
import 'pixel_ui.dart';
import 'top_hud_bar.dart';
import '../localization/game_localization.dart';

/// إطار شاشات الداخل (الألواح، الصوبة، المياه) حسب الـ Figma:
/// فوق الـ HUD، وتحته المشهد (scene) وفوق يسار صندوق المعلومات وزرار الرجوع،
/// وتحت صندوق الحوار ولوحة التفاصيل.
class ScreenFrame extends StatelessWidget {
  final Widget background;
  final Widget scene;
  final String infoTitle;
  final List<String> infoLines;
  final Color accent;
  final Widget dialogue;
  final Widget detail;

  const ScreenFrame({
    super.key,
    required this.background,
    required this.scene,
    required this.infoTitle,
    required this.infoLines,
    required this.dialogue,
    required this.detail,
    this.accent = Colors.cyan,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // الكيبورد مبيصغرش الشاشة ولا بيقص الخلفية
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFF070D18),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: background),
            Column(
              children: [
                TopHudBar(onNotificationsTap: () {}, onTodoListTap: () {}),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(child: scene),
                      Positioned(
                        top: 6,
                        left: 8,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InfoBox(
                              title: infoTitle,
                              lines: infoLines,
                              color: accent,
                            ),
                            const SizedBox(height: 6),
                            BackPixelButton(color: accent),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                  child: SizedBox(
                    height: 92,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 5, child: dialogue),
                        const SizedBox(width: 8),
                        Expanded(flex: 4, child: detail),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// لوحة التفاصيل اللي تحت يمين: سطور معلومات + أزرار على اليمين
class DetailPanel extends StatelessWidget {
  final List<Widget> lines;
  final List<Widget> buttons;

  const DetailPanel({super.key, required this.lines, required this.buttons});

  @override
  Widget build(BuildContext context) {
    return PixelPanel(
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: lines,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final b in buttons)
                Padding(padding: const EdgeInsets.only(bottom: 4), child: b),
            ],
          ),
        ],
      ),
    );
  }
}

/// سطر نص صغير للوحة التفاصيل
Widget detailLine(
  String text, {
  Color color = Colors.white,
  bool bold = false,
}) {
  return Text(
    gameText(text),
    style: TextStyle(
      color: color,
      fontSize: 9,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      height: 1.3,
    ),
  );
}
