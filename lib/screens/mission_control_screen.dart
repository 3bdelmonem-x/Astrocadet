import 'package:flutter/material.dart' hide Text;
import '../widgets/game_text.dart';
import '../game/crew.dart';
import '../game/game_controller.dart';
import '../widgets/building_scaffold.dart';
import '../widgets/crew_avatar.dart';

/// شاشة الاتصال بالأرض: د. رييس بتدي نصايح (1 AP)، والاتصال بيقطع في Sol 10-12.
class MissionControlScreen extends StatelessWidget {
  const MissionControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: gameController,
      builder: (context, _) {
        final g = gameController.game;
        final dark = g.conjunction;
        final canAsk = g.decisionPhase && g.actionPoints >= 1 && !dark;
        final advice = gameController.lastAdvice;

        return BuildingScaffold(
          title: 'MISSION CONTROL',
          accent: Colors.purpleAccent,
          speaker: missionControl,
          background: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purpleAccent.withValues(alpha: 0.18),
                  const Color(0xFF070D18),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          visual: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    dark ? Icons.signal_wifi_off : Icons.satellite_alt,
                    size: 56,
                    color: dark ? Colors.redAccent : Colors.greenAccent,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dark ? 'LINK: DARK (Solar Conjunction)' : 'LINK: ONLINE',
                    style: TextStyle(
                      color: dark ? Colors.redAccent : Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 330,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purpleAccent),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CrewAvatar(member: missionControl, size: 40),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            dark
                                ? 'No signal from Earth until Sol 12. You are on your own.'
                                : (advice ??
                                    'Ask for advice and I will tell you what to fix next.'),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 11, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          infoLines: [
            'Earth contact: ${dark ? 'OFFLINE' : 'ONLINE'}',
            'Asking for advice costs 1 AP',
            'Contact drops during Sol 10 to 12',
            'Advice is based on your base right now',
          ],
          actions: [
            ActionSpec(
              dark ? 'NO CONTACT' : 'ASK FOR ADVICE — 1 AP',
              canAsk ? () => gameController.askAdvice() : null,
              color: Colors.purpleAccent,
            ),
          ],
          tip: dark
              ? 'Contact is dark. Trust your training, Cadet.'
              : 'Mission Control sees the whole picture. Ask when you are unsure.',
        );
      },
    );
  }
}
