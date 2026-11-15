import 'package:flutter/material.dart' hide Text;
import '../widgets/game_text.dart';
import '../widgets/game_image.dart';
import '../widgets/pixel_status_icon.dart';
import '../audio/audio_service.dart';
import '../game/game_controller.dart';
import 'main_menu_screen.dart';

class MissionDebriefScreen extends StatelessWidget {
  final bool won;
  final String message;

  const MissionDebriefScreen({
    super.key,
    required this.won,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final g = gameController.game;
    final accent = won ? Colors.greenAccent : Colors.redAccent;
    // قرارات اللاعب: السطور اللي فيها صرف AP
    final decisions =
        g.history
        .where((line) =>
            line.contains(' AP)') ||
            line.contains(' water)') ||
            line.contains(' energy)') ||
            line.contains('Collect ') ||
            line.contains('Harvest '))
        .toList();

    return SpaceBackground(
      child: Scaffold(
      // الكيبورد مبيصغرش الشاشة ولا بيقص الخلفية
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PixelStatusIcon(won: won, size: 64),
                  const SizedBox(height: 8),
                  Text(
                    won ? 'MISSION COMPLETE' : 'MISSION FAILED',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: accent,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Rank: ${g.rank}   •   Sols survived: ${won ? g.sol : g.sol - 1}/20',
                    style: const TextStyle(
                        color: Colors.cyanAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'O₂ ${g.oxygen.round()}  •  Water ${g.water.round()}  •  Food ${g.food.round()}  •  '
                    'Radiation ${g.radiation.round()}  •  Health ${g.health.round()}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 90),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Your decisions',
                              style: TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11)),
                          const SizedBox(height: 4),
                          if (decisions.isEmpty)
                            const Text('You made no decisions.',
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 10)),
                          for (final line in decisions)
                            Text(line,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161B22),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const Text(
                      'NASA Fact: Mars atmosphere is 95% CO2. NASA\'s MOXIE on the Perseverance rover made oxygen from it, and the ISS now recovers about 98% of its water.\n'
                      'The mechanics are based on real NASA missions and research. Specific numbers (percentages, durations, costs) are game values chosen for balance, not NASA data.',
                      style: TextStyle(
                          color: Colors.cyan, fontSize: 11, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF161B22),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      audio.sfx('ui_tap');
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MainMenuScreen()),
                        (route) => false,
                      );
                    },
                    child: const Text('MAIN MENU',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  // توقيع Lumera (أكبر شوية من اللي في القائمة الرئيسية)
                  const Text(
                    'Made by Lumera',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }
}
