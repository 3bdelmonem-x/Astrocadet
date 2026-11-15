import 'package:flutter/material.dart' hide Text;
import 'game_text.dart';
import '../game/game_controller.dart';
import '../game/game_engine.dart';
import '../localization/game_localization.dart';
import 'event_card.dart';
import 'pixel_ui.dart';

/// تقرير الصبح: "Morning report !" بالموارد وعلامات LOW!! والحدث المتوقع.
class MorningReportDialog extends StatelessWidget {
  final VoidCallback onBegin;

  const MorningReportDialog({super.key, required this.onBegin});

  @override
  Widget build(BuildContext context) {
    final g = gameController.game;
    final d = g.delta;
    final maxHeight = MediaQuery.of(context).size.height * 0.94;

    String eventText;
    if (g.event == 'None') {
      eventText = g.conjunction
          ? 'Solar Conjunction: Earth contact is dark.'
          : 'No events expected today.';
      eventText = gameText(eventText);
    } else {
      final info = eventInfo[g.event];
      eventText =
          '${gameText(g.event)}: ${info == null ? '' : gameText(info[0])}';
    }

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
                '${gameText('Morning report !')}   ${gameText('SOL')} ${g.sol}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
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
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: g.event == 'None' && !g.conjunction
                                ? Colors.white24
                                : Colors.redAccent,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          eventText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    '${gameText('Action Points')}: ${g.actionPoints} / $actionPointCap  (+$dailyActionPoints ${gameText('every Sol')})',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  PixelButton(
                    label: 'Back to Base',
                    height: 34,
                    onTap: () {
                      Navigator.pop(context);
                      onBegin();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
