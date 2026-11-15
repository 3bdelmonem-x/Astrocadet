import 'package:flutter/material.dart' hide Text;
import 'game_text.dart';
import '../game/game_controller.dart';
import '../game/game_engine.dart';
import '../localization/game_localization.dart';
import 'pixel_ui.dart';

/// تقرير آخر اليوم: "Feed back of sol !" (قبل ← بعد لكل مورد)
class SolFeedbackDialog extends StatelessWidget {
  final VoidCallback onNextSol;

  const SolFeedbackDialog({super.key, required this.onNextSol});

  @override
  Widget build(BuildContext context) {
    final g = gameController.game;
    final d = g.delta;
    final maxHeight = MediaQuery.of(context).size.height * 0.94;

    double before(String k, double now) => now - d[k]!;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(10),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 560, maxHeight: maxHeight),
        child: PixelPanel(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${gameText('Feed back of sol')} ${g.sol - 1} !',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              if (g.lastEvent != 'None')
                Text(
                  '${gameText('Event')}: ${gameText(g.lastEvent)}',
                  style: const TextStyle(color: Colors.redAccent, fontSize: 10),
                ),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      ResourceRow(
                        animate: true,
                        index: 0,
                        icon: Icons.air,
                        label: gameText('Oxygen'),
                        color: Colors.lightBlueAccent,
                        before: before('oxygen', g.oxygen),
                        after: g.oxygen,
                      ),
                      ResourceRow(
                        animate: true,
                        index: 1,
                        icon: Icons.bolt,
                        label: gameText('Energy'),
                        color: Colors.amber,
                        before: before('energy', g.energy),
                        after: g.energy,
                        max: energyLimit,
                      ),
                      ResourceRow(
                        animate: true,
                        index: 2,
                        icon: Icons.battery_charging_full,
                        label: gameText('Battery'),
                        color: Colors.orangeAccent,
                        before: before('battery', g.battery),
                        after: g.battery,
                        max: g.batteryMax <= 0 ? 1 : g.batteryMax,
                        showMax: true,
                      ),
                      ResourceRow(
                        animate: true,
                        index: 3,
                        icon: Icons.water_drop,
                        label: gameText('Water'),
                        color: Colors.blueAccent,
                        before: before('water', g.water),
                        after: g.water,
                      ),
                      ResourceRow(
                        animate: true,
                        index: 4,
                        icon: Icons.eco,
                        label: gameText('Food'),
                        color: Colors.greenAccent,
                        before: before('food', g.food),
                        after: g.food,
                      ),
                      ResourceRow(
                        animate: true,
                        index: 5,
                        icon: Icons.radar,
                        label: gameText('Radiation'),
                        color: Colors.orange,
                        before: before('radiation', g.radiation),
                        after: g.radiation,
                        badWhenUp: true,
                        showMax: true,
                      ),
                      ResourceRow(
                        animate: true,
                        index: 6,
                        icon: Icons.favorite,
                        label: gameText('Crew Health'),
                        color: Colors.redAccent,
                        before: before('health', g.health),
                        after: g.health,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: PixelButton(
                  label: 'Next sol !',
                  height: 34,
                  onTap: () {
                    Navigator.pop(context);
                    onNextSol();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
