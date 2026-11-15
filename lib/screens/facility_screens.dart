import 'package:flutter/material.dart' hide Text;
import '../widgets/game_text.dart';
import '../game/crew.dart';
import '../game/game_controller.dart';
import '../game/game_engine.dart';
import '../widgets/building_scaffold.dart';
import '../widgets/smart_asset.dart';

/// بيانات العداد اللي بيظهر في شاشة المنشأة
class GaugeData {
  final String label;
  final double value;
  final double max;
  final Color color;

  const GaugeData(this.label, this.value, this.max, this.color);
}

// إنتاج واستهلاك الطاقة المتوقع في اليوم (بعد الأحداث والميل)
double _energyIncome(Game g) => g.expectedProduction();

double _energyDemand(Game g) =>
    g.autoDemand() + g.buildings['Water Recycler']! * waterCycleEnergy;

/// شاشة عامة لأي منشأة: المربعات اللي اتبنت + عداد + معلومات + أزرار.
/// لو buildingKey = null تبقى شاشة الحماية (Habitat).
class FacilityScreen extends StatelessWidget {
  final String title;
  final Color accent;
  final CrewMember speaker;
  final IconData icon;
  final String? buildingKey;
  final String unitLabel;
  final List<String> Function(Game g) infoLines;
  final String Function(Game g) tip;
  final GaugeData Function(Game g) gauge;
  final List<ActionSpec> Function(Game g) extraActions;

  const FacilityScreen({
    super.key,
    required this.title,
    required this.accent,
    required this.speaker,
    required this.icon,
    required this.buildingKey,
    required this.unitLabel,
    required this.infoLines,
    required this.tip,
    required this.gauge,
    required this.extraActions,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: gameController,
      builder: (context, _) {
        final g = gameController.game;
        final key = buildingKey;
        final count = key == null ? g.habitatLevel : (g.buildings[key] ?? 0);
        final slots = key == null ? 3 : (buildingMax[key] ?? 4);
        final canBuild = g.decisionPhase && g.actionPoints >= buildActionCost;
        final gd = gauge(g);
        final double ratio =
            gd.max <= 0 ? 0.0 : (gd.value / gd.max).clamp(0.0, 1.0).toDouble();

        Widget tile(int i) {
          final lit = i < count;
          return Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: lit ? accent.withValues(alpha: 0.18) : Colors.black26,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: lit ? accent : Colors.white24, width: 2),
            ),
            child: Icon(icon,
                size: 28, color: lit ? accent : Colors.white24),
          );
        }

        final actions = <ActionSpec>[
          if (key != null)
            ActionSpec(
              g.atMax(key)
                  ? 'MAX REACHED ($count / $slots)'
                  : 'BUILD $unitLabel — 2 AP',
              (canBuild && !g.atMax(key))
                  ? () => gameController.build(key)
                  : null,
              color: accent,
            )
          else
            ActionSpec(
              g.habitatLevel >= 3
                  ? 'SHIELDING AT MAX LEVEL'
                  : 'UPGRADE SHIELDING — 2 AP',
              (canBuild && g.habitatLevel < 3)
                  ? () => gameController.upgradeHabitat()
                  : null,
              color: accent,
            ),
          ...extraActions(g),
        ];

        return BuildingScaffold(
          title: title,
          accent: accent,
          speaker: speaker,
          background: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent.withValues(alpha: 0.18), const Color(0xFF070D18)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          visual: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(slots, tile),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: 280,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${gd.label}  ${gd.value.round()} / ${gd.max.round()}',
                            style: TextStyle(
                                color: gd.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 11),
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: ratio,
                              minHeight: 10,
                              backgroundColor: Colors.white12,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(gd.color),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          infoLines: infoLines(g),
          actions: actions,
          tip: tip(g),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------
// مولد الأكسجين (كريم المهندس)
// ---------------------------------------------------------------------
class OxygenGeneratorScreen extends StatelessWidget {
  const OxygenGeneratorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FacilityScreen(
      title: 'OXYGEN GENERATOR',
      accent: Colors.lightBlueAccent,
      speaker: karim,
      icon: Icons.air,
      buildingKey: 'Oxygen Generator',
      unitLabel: 'GENERATOR',
      gauge: (g) => GaugeData('OXYGEN', g.oxygen, 100, Colors.lightBlueAccent),
      infoLines: (g) {
        final n = g.buildings['Oxygen Generator']!;
        final make = n * buildingOutput['Oxygen Generator']!;
        final plants = g.activeGreenhouses() * plantOxygen * g.plantFactor;
        final need = g.crewCount * oxygenPerPerson;
        final net = make + plants - need;
        return [
          'Generators: $n (+20 oxygen / Sol, 6 energy each)',
          'Plants add +${plants.round()} oxygen / Sol (health ${g.plantHealth.round()}%)',
          'The crew breathes ${need.round()} oxygen / Sol',
          'Net per Sol: ${net >= 0 ? '+' : ''}${net.round()}',
          if (g.event == 'Life Support Leak' && !g.mitigated)
            'LIFE SUPPORT LEAK: oxygen use is doubled',
        ];
      },
      tip: (g) {
        final n = g.buildings['Oxygen Generator']!;
        final net = n * buildingOutput['Oxygen Generator']! +
            g.activeGreenhouses() * plantOxygen * g.plantFactor -
            g.crewCount * oxygenPerPerson;
        return net < 0
            ? 'We make less oxygen than we breathe. Build another generator or grow more plants!'
            : 'Oxygen is stable. Keep the energy flowing and the plants healthy.';
      },
      extraActions: (g) => [
        if (g.event == 'Life Support Leak')
          ActionSpec(
            'REPAIR LEAK — 1 AP',
            gameController.canRespond ? () => gameController.respond() : null,
            color: Colors.redAccent,
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// الوحدة النووية (نادية)
// ---------------------------------------------------------------------
class NuclearScreen extends StatelessWidget {
  const NuclearScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FacilityScreen(
      title: 'NUCLEAR UNIT',
      accent: Colors.deepOrangeAccent,
      speaker: nadia,
      icon: Icons.offline_bolt,
      buildingKey: 'Nuclear Unit',
      unitLabel: 'NUCLEAR UNIT',
      gauge: (g) {
        final income = _energyIncome(g);
        final demand = _energyDemand(g);
        final top = income > demand ? income : demand;
        return GaugeData('INCOME vs NEEDS', income, top <= 0 ? 1 : top,
            Colors.deepOrangeAccent);
      },
      infoLines: (g) {
        final n = g.buildings['Nuclear Unit']!;
        return [
          'Units: $n (+12 energy / Sol each)',
          'Works through dust storms, when the panels stop',
          'Total energy income: ${_energyIncome(g).round()} / Sol',
          'Systems need: ${_energyDemand(g).round()} / Sol',
        ];
      },
      tip: (g) => g.buildings['Nuclear Unit']! == 0
          ? 'No reactor yet! The long dust storm is coming and the panels will stop completely.'
          : 'Steady power, rain or dust. That is what I like to see!',
      extraActions: (g) => [
        if (g.event == 'Equipment Malfunction')
          ActionSpec(
            'REPAIR EQUIPMENT — 1 AP',
            gameController.canRespond ? () => gameController.respond() : null,
            color: Colors.redAccent,
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// حماية القبة من الإشعاع (يوسف الدكتور)
// ---------------------------------------------------------------------
class HabitatScreen extends StatelessWidget {
  const HabitatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FacilityScreen(
      title: 'HABITAT SHIELDING',
      accent: Colors.orange,
      speaker: youssef,
      icon: Icons.shield_outlined,
      buildingKey: null,
      unitLabel: '',
      gauge: (g) => GaugeData('RADIATION', g.radiation, 100, Colors.orange),
      infoLines: (g) {
        final perSol = radiationPerSol * habitatMultipliers[g.habitatLevel - 1];
        return [
          'Shielding level: ${g.habitatLevel} / 3',
          'Radiation builds up by ${perSol.toStringAsFixed(1)} per Sol',
          'Radiation reaches 100 in about ${((100 - g.radiation) / perSol).floor()} Sols at this rate',
          'If it reaches 100 the mission fails',
          if (g.event == 'Solar Flare')
            'SOLAR FLARE: +25 radiation (only +5 if you shelter)',
        ];
      },
      tip: (g) => g.habitatLevel >= 3
          ? 'Maximum shielding. The habitat is as safe as we can make it.'
          : 'Higher shielding slows the radiation. It pays off over 20 Sols.',
      extraActions: (g) => [
        if (g.event == 'Solar Flare')
          ActionSpec(
            'SHELTER IN HABITAT — 1 AP',
            gameController.canRespond ? () => gameController.respond() : null,
            color: Colors.redAccent,
          ),
      ],
    );
  }
}


// ---------------------------------------------------------------------
// البطارية (كريم المهندس): الألواح بتشحنها، واللاعب بيسحب منها الطاقة
// ---------------------------------------------------------------------
class BatteryScreen extends StatefulWidget {
  const BatteryScreen({super.key});

  @override
  State<BatteryScreen> createState() => _BatteryScreenState();
}

class _BatteryScreenState extends State<BatteryScreen> {
  String? msg; // رد مؤقت بعد الضغط

  void _collect() {
    final got = gameController.collectEnergy();
    final g = gameController.game;
    setState(() {
      msg = got > 0
          ? 'Collected ${got.round()} energy! It is in your energy counter now.'
          : (g.battery <= 0
              ? 'The battery is empty. Solar panels charge it at the end of each Sol.'
              : 'Your energy counter is full (${energyLimit.round()}).');
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: gameController,
      builder: (context, _) {
        final g = gameController.game;
        final ratio = g.batteryMax <= 0
            ? 0.0
            : (g.battery / g.batteryMax).clamp(0.0, 1.0).toDouble();
        final production = g.expectedProduction();
        final canCollect = g.decisionPhase &&
            g.battery > 0 &&
            g.energy < energyLimit;

        final String tip;
        if (msg != null) {
          tip = msg!;
        } else if (g.energy < 15 && g.battery >= 10) {
          tip = 'The energy counter is low! Tap the battery to collect its charge.';
        } else if (g.battery <= 0) {
          tip = 'The battery is empty. The panels fill it at the end of each Sol.';
        } else {
          tip = 'Tap the battery every Sol to move its charge to your energy counter.';
        }

        return BuildingScaffold(
          title: 'BATTERY',
          accent: Colors.orangeAccent,
          speaker: karim,
          background: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orangeAccent.withValues(alpha: 0.18),
                  const Color(0xFF070D18),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          visual: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _collect,
                      child: Opacity(
                        opacity: (0.45 + 0.55 * ratio).clamp(0.0, 1.0),
                        child: SmartImage.one(
                          kSolar,
                          'Battery-Cabinet',
                          height: 110,
                          fallback: const Icon(Icons.battery_charging_full,
                              size: 90, color: Colors.orangeAccent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text('TAP TO COLLECT',
                        style: TextStyle(
                            color: Colors.amber,
                            fontSize: 9,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 280,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CHARGE  ${g.battery.round()} / ${g.batteryMax.round()}',
                            style: const TextStyle(
                                color: Colors.orangeAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 11),
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: ratio,
                              minHeight: 10,
                              backgroundColor: Colors.white12,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.orangeAccent),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          infoLines: [
            'Stored charge: ${g.battery.round()} / ${g.batteryMax.round()}',
            'Energy counter: ${g.energy.round()} / ${energyLimit.round()}',
            'Panels and reactors add about ${production.round()} to the battery each Sol',
            'The base runs on the energy counter, not on the battery directly',
          ],
          actions: [
            ActionSpec(
              g.battery <= 0 ? 'BATTERY EMPTY' : 'COLLECT ENERGY',
              canCollect ? _collect : null,
              color: Colors.orangeAccent,
            ),
          ],
          tip: tip,
        );
      },
    );
  }
}
