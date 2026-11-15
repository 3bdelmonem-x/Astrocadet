import 'package:flutter/material.dart' hide Text;
import 'game_text.dart';
import '../audio/audio_service.dart';
import '../game/game_controller.dart';
import '../game/game_engine.dart';
import '../localization/game_localization.dart';

// [الوصف, اسم الإجراء]
const Map<String, List<String>> eventInfo = {
  'Dust Storm': [
    'Dust blocks the sun. Solar output falls to 3% (10% if you shelter). '
        'The storm lasts a few Sols.',
    'Shelter & reduce operations',
  ],
  'Solar Flare': [
    'A radiation spike hits the base: +25 Radiation, or only +5 if you shelter.',
    'Shelter in habitat',
  ],
  'Mars Solar Conjunction': [
    'Earth contact is dark. No repairs and no help from Mission Control '
        'until Sol 12.',
    '',
  ],
  'Life Support Leak': [
    'Oxygen use doubles until the leak is repaired.',
    'Repair the leak',
  ],
  'Equipment Malfunction': [
    'Energy output drops by 15% until the equipment is repaired.',
    'Repair equipment',
  ],
  'Crop Contamination': [
    'Food output drops by 40% until the greenhouse is treated.',
    'Treat the greenhouse',
  ],
  'Water System Strain': [
    'Water recycler efficiency drops by 15% until it is maintained.',
    'Maintain the recycler',
  ],
};

class EventCard extends StatelessWidget {
  const EventCard({super.key});

  @override
  Widget build(BuildContext context) {
    final g = gameController.game;
    final info =
        eventInfo[g.event] ??
        ['Something unusual is happening at the outpost.', 'Respond'];
    final canRespond = gameController.canRespond;
    final isBlackout = g.event == 'Mars Solar Conjunction';

    String? note;
    if (g.mitigated) {
      note = 'Already handled this Sol.';
    } else if (!isBlackout && !canRespond) {
      final repair =
          g.event == 'Life Support Leak' || g.event == 'Equipment Malfunction';
      if (repair && g.conjunction) {
        note = 'No repairs possible during the blackout.';
      } else {
        note =
            'Not enough ${eventCostLabel(g.event).split(' ').last == 'AP' ? 'Action Points' : eventCostLabel(g.event).split(' ').last} for this.';
      }
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.redAccent, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.redAccent,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      gameText(g.event),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                gameText(info[0]),
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 14),
              if (!isBlackout)
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: canRespond ? Colors.cyan : Colors.white24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: canRespond
                        ? () {
                            Navigator.pop(context);
                            gameController.respond();
                          }
                        : null,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${gameText(info[1])} — ${gameText(eventCostLabel(g.event))}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              if (note != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    gameText(note),
                    style: const TextStyle(color: Colors.amber, fontSize: 11),
                  ),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      isBlackout
                          ? 'Understood — 0 AP'
                          : 'Continue operations — 0 AP',
                      style: const TextStyle(fontSize: 13, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// بيفتح كارت الحدث ومعاه صوته: صافرة الإنذار وصوت الحدث والمزيكا بتوطّى.
/// استخدميه دايماً بدل showDialog(EventCard) عشان الصوت يشتغل صح.
Future<void> showEventCard(BuildContext context) async {
  audio.onEventCard(gameController.game.event);
  await showDialog<void>(context: context, builder: (_) => const EventCard());
  audio.endEventCard(gameController.game);
}
