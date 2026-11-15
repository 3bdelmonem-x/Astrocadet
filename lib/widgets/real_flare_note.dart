import 'package:flutter/material.dart' hide Text;
import 'game_text.dart';
import '../services/donki_service.dart';

/// سطر "بيانات ناسا حقيقية" جوه كارت Solar Flare.
/// بيعرض آخر توهج حقيقي من DONKI. أرقام اللعبة (+25 / +5) تفضل Game Values.
class RealFlareNote extends StatelessWidget {
  const RealFlareNote({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RealFlare?>(
      future: DonkiService.instance.latestFlare(),
      builder: (context, snap) {
        String body;
        Color color = Colors.tealAccent;
        if (snap.connectionState != ConnectionState.done) {
          body = 'Checking NASA space weather...';
          color = Colors.white54;
        } else if (snap.data == null) {
          body = 'Live NASA data is not available right now (offline or '
              'rate limit). The game still works with its own values.';
          color = Colors.white54;
        } else {
          final f = snap.data!;
          final peak = f.peakTime.replaceAll('T', ' ').replaceAll('Z', ' UTC');
          body = 'Latest real solar flare: class ${f.classType}, peak $peak.'
              '${f.sourceLocation == null || f.sourceLocation!.isEmpty ? '' : ' Location on the Sun: ${f.sourceLocation}.'}';
        }
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1E36),
            border: Border.all(color: color.withValues(alpha: 0.6)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('REAL NASA DATA · DONKI (live)',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 1)),
              const SizedBox(height: 3),
              Text(body,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 11, height: 1.35)),
              const SizedBox(height: 3),
              const Text(
                  'Source: NASA CCMC, ccmc.gsfc.nasa.gov/tools/DONKI. The '
                  'radiation numbers in the game are game values.',
                  style: TextStyle(color: Colors.white38, fontSize: 9)),
            ],
          ),
        );
      },
    );
  }
}
