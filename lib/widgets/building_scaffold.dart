import 'package:flutter/material.dart' hide Text;
import 'game_text.dart';
import '../game/crew.dart';
import '../game/game_controller.dart';
import '../localization/game_localization.dart';
import 'crew_avatar.dart';
import 'top_hud_bar.dart';

class ActionSpec {
  final String label;
  final VoidCallback? onPressed; // null = الزرار مقفول
  final Color color;

  const ActionSpec(this.label, this.onPressed, {this.color = Colors.cyan});
}

/// تخطيط موحد لشاشات المباني (الألواح، الصوبة، خزان المياه):
/// فوق شريط الموارد، يسار الرسمة، يمين لوحة المعلومات والأزرار.
/// الشاشة اللي بتستخدمه لازم تتغلف بـ ListenableBuilder عشان تتحدث.
class BuildingScaffold extends StatelessWidget {
  final String title;
  final Color accent;
  final Widget background;
  final Widget visual;
  final List<String> infoLines;
  final List<ActionSpec> actions;
  final String tip;
  final CrewMember speaker; // مين بيتكلم في الشاشة دي

  const BuildingScaffold({
    super.key,
    required this.title,
    required this.accent,
    required this.background,
    required this.visual,
    required this.infoLines,
    required this.actions,
    required this.tip,
    required this.speaker,
  });

  @override
  Widget build(BuildContext context) {
    final g = gameController.game;

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
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    top: 40,
                                    bottom: 58,
                                  ),
                                  child: visual,
                                ),
                              ),
                              Positioned(
                                top: 0,
                                left: 0,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: accent,
                                    foregroundColor: Colors.black,
                                    minimumSize: const Size(60, 30),
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.arrow_back, size: 14),
                                  label: Text(
                                    gameText('BACK'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: _tipBox(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(width: 250, child: _panel(g.actionPoints)),
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

  Widget _tipBox() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF070B14).withValues(alpha: 0.92),
        border: Border.all(color: speaker.color, width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          CrewAvatar(member: speaker, size: 38),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gameText(speaker.title),
                  style: TextStyle(
                    color: speaker.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
                Text(
                  gameText(tip),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _panel(int actionPoints) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF070B14).withValues(alpha: 0.93),
        border: Border.all(color: accent, width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  gameText(title),
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.amber),
                ),
                child: Text(
                  'AP $actionPoints',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final line in infoLines)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        gameText(line),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  for (final a in actions)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: a.color,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            minimumSize: Size.zero,
                          ),
                          onPressed: a.onPressed,
                          child: Text(
                            gameText(a.label),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
