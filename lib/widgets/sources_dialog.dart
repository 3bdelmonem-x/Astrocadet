import 'package:flutter/material.dart' hide Text;
import 'game_text.dart';
import 'package:flutter/services.dart';
import '../audio/audio_service.dart';
import 'pixel_ui.dart';

/// كل مصادر اللعبة (من ملف AstroCadet_Sources.md). النصوص بالإنجليزي لأن
/// اللعبة كلها إنجليزي. الأرقام نفسها Game Values مش بيانات ناسا.
class _Source {
  final String title;
  final String info; // الناشر والتاريخ
  final String url;
  final String used; // بنستخدمه في إيه في اللعبة
  const _Source(this.title, this.info, this.url, this.used);
}

class _Topic {
  final String name;
  final IconData icon;
  final Color color;
  final List<_Source> sources;
  const _Topic(this.name, this.icon, this.color, this.sources);
}

const String _disclosure =
    'The mechanics are based on real NASA missions and research. Specific '
    'numbers (percentages, durations, costs) are game values chosen for '
    'balance, not NASA data.';

const List<String> _notes = [
  'Outpost Theta-9 is a fictional training base.',
  'The 20-Sol mission is the length of the training scenario (a game value), not a real supply window.',
  'The habitat shielding levels are a simplified game idea (think of layers of Martian soil). Real research says the Mars atmosphere already cuts most solar-storm doses, and that adding some metal shielding can even raise exposure.',
  'The 3-D printing story comes from a NASA design competition. It is an idea NASA encouraged, not a printing robot NASA built.',
  'The water recycler wear and efficiency are game values. Real stations recover about 98% of water today.',
  'The mold in the crop story happened to flowers, not food crops.',
];

const List<_Topic> _topics = [
  _Topic('DUST STORM', Icons.cloud, Color(0xFFE57B4B), [
    _Source(
      'Science Comic: Dust Storm on Mars',
      'NASA Science, 23 Jul 2018',
      'https://science.nasa.gov/?p=150668',
      'A global dust storm blocked the sun and put the Opportunity rover to sleep. Thin dust left on panels can slow the recovery.',
    ),
    _Source(
      "NASA's Opportunity Rover Mission on Mars Comes to End",
      'NASA Science, 13 Feb 2019',
      'https://science.nasa.gov/missions/mer/nasas-opportunity-rover-mission-on-mars-comes-to-end',
      'Confirms the dust storm event happened.',
    ),
  ]),
  _Topic('SOLAR vs NUCLEAR POWER', Icons.offline_bolt, Colors.amber, [
    _Source(
      'Solar vs. Fission Surface Power for Mars',
      'Rucker et al., NASA / AIAA Space 2016',
      'https://ntrs.nasa.gov/citations/20160002628',
      'Nuclear power is more reliable during dust storms for a crewed mission, which is why the Nuclear Unit keeps working.',
    ),
  ]),
  _Topic('SOLAR FLARE AND RADIATION', Icons.wb_sunny, Colors.orangeAccent, [
    _Source(
      'Curiosity radiation reading after a solar storm',
      'NASA/JPL, 2024',
      'https://www.nasa.gov/?p=670127',
      'Solar storms really do raise radiation on the surface of Mars.',
    ),
    _Source(
      'Radiation Shielding Optimization on Mars',
      'Slaba, Mertens, Blattnig, NASA Langley, 2013',
      'https://ntrs.nasa.gov/citations/20130012456',
      'The thin Mars atmosphere reduces most solar-storm doses. Long-term cosmic rays are the bigger problem.',
    ),
  ]),
  _Topic('MARS SOLAR CONJUNCTION', Icons.signal_cellular_off, Colors.purpleAccent, [
    _Source(
      "NASA's Mars Fleet Will Still Conduct Science While Lying Low",
      'NASA/JPL, 10 Nov 2023',
      'https://www.nasa.gov/solar-system/planets/mars/nasas-mars-fleet-will-still-conduct-science-while-lying-low/',
      'Earth and Mars end up on opposite sides of the Sun, so engineers pause commands for about two weeks. It happens roughly every two years. The Sol 10 to 12 blackout and the no-repairs rule are game rules.',
    ),
  ]),
  _Topic('LIFE SUPPORT LEAK', Icons.air, Colors.lightBlueAccent, [
    _Source(
      'Crew Continues Troubleshooting as Tests Isolate Small Leak',
      'NASA ISS Blog, 29 Sep 2020',
      'https://www.nasa.gov/blogs/spacestation/2020/09/29/crew-continues-troubleshooting-as-tests-isolate-small-leak/',
      'The crew closed hatches and used an ultrasonic detector to find a small leak on the ISS. Finding the leak comes before fixing it.',
    ),
    _Source(
      'Statement on International Space Station Leak Investigation',
      'NASA, RELEASE18-085, 3 Oct 2018',
      'https://www.nasa.gov/news-release/statement-on-international-space-station-leak-investigation/',
      'A tiny hole was found and repaired by the crew in 2018.',
    ),
  ]),
  _Topic('EQUIPMENT MALFUNCTION', Icons.build, Colors.redAccent, [
    _Source(
      'Investigation into the High Voltage Shutdown of the Oxygen Generator System in the ISS',
      'Carpenter et al., NASA, 2012',
      'https://ntrs.nasa.gov/citations/20120004302',
      'The ISS oxygen generator shut down, and the crew swapped the faulty part with a spare. That is why repairs use spare parts.',
    ),
  ]),
  _Topic('GREENHOUSE AND CROPS', Icons.eco, Colors.greenAccent, [
    _Source(
      'Growing Plants in Space',
      'NASA, 2019 (updated 2023)',
      'https://www.nasa.gov/exploration-research-and-technology/growing-plants-in-space/',
      'Over-watered flowers with weak airflow grew mold on the ISS, and an astronaut cleaned it. Fresh food matters because packaged vitamins fade.',
    ),
    _Source(
      'Zinnias from Space!',
      'NASA, Jan 2016',
      'https://www.nasa.gov/humans-in-space/zinnias-from-space-nasa-studies-the-multiple-benefits-of-gardening/',
      'Confirms the mold happened on the ISS zinnias.',
    ),
  ]),
  _Topic('WATER RECYCLER', Icons.water_drop, Colors.blueAccent, [
    _Source(
      'Evaluation of Technologies to Prevent Precipitation During Water Recovery from Urine',
      'Broyan et al., NASA, 2011',
      'https://ntrs.nasa.gov/citations/20110023178',
      'Mineral buildup clogged the urine processor, and a fix raised water recovery from 70% to 85%. That is why filters need care.',
    ),
    _Source(
      'NASA Achieves Water Recovery Milestone on International Space Station',
      'NASA, 20 Jun 2023',
      'https://www.nasa.gov/missions/station/iss-research/nasa-achieves-water-recovery-milestone-on-international-space-station/',
      'The ISS now recovers about 98% of its water, and long trips need close to that.',
    ),
  ]),
  _Topic('OXYGEN GENERATOR', Icons.bubble_chart, Colors.cyanAccent, [
    _Source(
      'MOXIE Sets Consecutive Personal Bests and Mars Records for Oxygen Production',
      'NASA Science, 22 Dec 2022',
      'https://science.nasa.gov/?p=354880',
      'The MOXIE experiment on Perseverance made oxygen from the Martian air. A crewed version would be much bigger.',
    ),
  ]),
  _Topic('BUILDING THE BASE (STORY)', Icons.home_work, Colors.white70, [
    _Source(
      'NASA Awards Top Three Design Finalists in 3-D Printed Habitat Challenge',
      'NASA, 27 Sep 2015',
      'https://www.nasa.gov/?p=95141',
      'A design competition for 3-D printed Mars habitats. We only use it as inspiration for the story.',
    ),
  ]),
  _Topic('TIME ON MARS', Icons.schedule, Colors.amber, [
    _Source(
      'Telling Time on Mars',
      'Allison, NASA GISS, 1998',
      'https://www.giss.nasa.gov/research/briefs/1998_allison_02/',
      'A Sol (a Martian day) is about 39 minutes and 35 seconds longer than an Earth day.',
    ),
  ]),
  _Topic('SPACE WEATHER DATA', Icons.insights, Colors.tealAccent, [
    _Source(
      'DONKI: Space Weather Database of Notifications, Knowledge, Information',
      'NASA CCMC',
      'https://ccmc.gsfc.nasa.gov/tools/DONKI',
      'A public database of solar flares and storms. It is research-grade data, not the official forecast.',
    ),
  ]),
];

/// كل المراجع كنص واحد (للنسخ)
String _allReferences() {
  final b = StringBuffer();
  for (final t in _topics) {
    for (final s in t.sources) {
      b.writeln('${s.title}. ${s.info}. ${s.url}');
    }
  }
  b.writeln();
  b.write(_disclosure);
  return b.toString();
}

/// شاشة المصادر: بتتفتح من الإعدادات. الضغط على أي مصدر بينسخ رابطه.
Future<void> showSourcesDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      String? copied; // آخر رابط اتنسخ
      return StatefulBuilder(
        builder: (context, setState) {
          Future<void> copy(String text, String key) async {
            await Clipboard.setData(ClipboardData(text: text));
            audio.sfx('ui_tap');
            setState(() => copied = key);
          }

          final maxH = MediaQuery.of(context).size.height * 0.92;
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(12),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 640, maxHeight: maxH),
              child: PixelPanel(
                borderColor: Colors.cyanAccent,
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.menu_book,
                            color: Colors.cyanAccent, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text('SOURCES',
                              style: TextStyle(
                                  color: Colors.cyanAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  letterSpacing: 1)),
                        ),
                        GestureDetector(
                          onTap: () => copy(_allReferences(), 'all'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.amber),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                                copied == 'all' ? 'COPIED!' : 'COPY ALL',
                                style: const TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => Navigator.pop(dialogContext),
                          child: const Icon(Icons.close,
                              color: Colors.white70, size: 22),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D1E36),
                              border: Border.all(color: Colors.amber),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(_disclosure,
                                style: const TextStyle(
                                    color: Colors.amber,
                                    fontSize: 11,
                                    height: 1.4)),
                          ),
                          for (final t in _topics) ...[
                            Padding(
                              padding: const EdgeInsets.only(top: 4, bottom: 4),
                              child: Row(
                                children: [
                                  Icon(t.icon, color: t.color, size: 16),
                                  const SizedBox(width: 6),
                                  Text(t.name,
                                      style: TextStyle(
                                          color: t.color,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          letterSpacing: 1)),
                                ],
                              ),
                            ),
                            for (final s in t.sources)
                              GestureDetector(
                                onTap: () => copy(s.url, s.url),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0D1E36),
                                    border: Border.all(
                                        color: t.color.withValues(alpha: 0.5)),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(s.title,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                              height: 1.3)),
                                      const SizedBox(height: 2),
                                      Text(s.info,
                                          style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 9)),
                                      const SizedBox(height: 4),
                                      Text(s.used,
                                          style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 10,
                                              height: 1.35)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(s.url,
                                                style: const TextStyle(
                                                    color: Colors.cyanAccent,
                                                    fontSize: 9)),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                              copied == s.url
                                                  ? 'COPIED!'
                                                  : 'TAP TO COPY',
                                              style: TextStyle(
                                                  color: copied == s.url
                                                      ? Colors.greenAccent
                                                      : Colors.white38,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 8)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                          const SizedBox(height: 8),
                          const Text('GOOD TO KNOW',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  letterSpacing: 1)),
                          const SizedBox(height: 4),
                          for (final n in _notes)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text('•  $n',
                                  style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                      height: 1.35)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
