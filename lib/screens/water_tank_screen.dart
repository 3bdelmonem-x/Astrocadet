import 'package:flutter/material.dart' hide Text;
import '../widgets/game_text.dart';
import '../audio/audio_service.dart';
import '../game/crew.dart';
import '../game/game_controller.dart';
import '../game/game_engine.dart';
import '../widgets/game_route.dart';
import '../widgets/pixel_ui.dart';
import '../widgets/screen_frame.dart';
import '../widgets/smart_asset.dart';
import 'solar_field_screen.dart';

/// خزان المياه ووحدات إعادة التدوير.
/// دورة المياه: اللاعب بيدوس RUN CYCLE فالطاقة بتتخصم من العداد في نفس اللحظة
/// والمية بتزيد على طول. الفلتر بيقل مع كل دورة وبيتصلح بالطاقة.
class WaterTankScreen extends StatefulWidget {
  const WaterTankScreen({super.key});

  @override
  State<WaterTankScreen> createState() => _WaterTankScreenState();
}

class _WaterTankScreenState extends State<WaterTankScreen> {
  int selected = 0;
  bool pumpOn = true;
  bool valveHabitat = true;
  bool valveGreenhouse = true;
  String? msg;

  SmartImage _img(String name, {double? height, double? width, BoxFit? fit}) =>
      SmartImage.one(kWater, name,
          height: height, width: width, fit: fit ?? BoxFit.contain);

  /// صورة الخزان (Water-Tank-Cutaway) والمية بتنزل حسب المستوى
  Widget _tank(double w, double h, double water) {
    final double level = (water / 100).clamp(0.0, 1.0).toDouble();
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: const Color(0xFF0B1A2E),
        border: Border.all(color: const Color(0xFF8FA3B8), width: 3),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: ClipRect(
              child: Align(
                alignment: Alignment.bottomCenter,
                heightFactor: level,
                child: SizedBox(
                  width: w - 6,
                  height: h - 6,
                  child: _img('Water-Tank-Cutaway', fit: BoxFit.fill),
                ),
              ),
            ),
          ),
          Center(
            child: Text(
              '${water.round()}%',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  shadows: [Shadow(color: Colors.black, blurRadius: 6)]),
            ),
          ),
        ],
      ),
    );
  }

  /// عداد المستوى (Level-Gauge) مع تغطية الجزء الفاضي
  Widget _gauge(double h, double water) {
    final double level = (water / 100).clamp(0.0, 1.0).toDouble();
    return SizedBox(
      width: 30,
      height: h,
      child: Stack(
        children: [
          _img('Level-Gauge', height: h, width: 30, fit: BoxFit.fill),
          Positioned(
            left: 4,
            right: 8,
            top: h * 0.10,
            height: (h * 0.80) * (1 - level),
            child: Container(color: const Color(0xFF0B1A2E)),
          ),
        ],
      ),
    );
  }

  Widget _unit(int i, bool built, bool selectedUnit, bool strain, double uh) {
    final Color c = !built
        ? Colors.white24
        : (strain ? Colors.redAccent : Colors.lightBlueAccent);
    return GestureDetector(
      onTap: () => setState(() {
        audio.sfx('ui_hover_select');
        selected = i;
        msg = null;
      }),
      child: Container(
        width: uh * 1.5,
        height: uh,
        decoration: BoxDecoration(
          color: built ? const Color(0xFF16263C) : Colors.black26,
          border: Border.all(
              color: selectedUnit ? Colors.cyanAccent : c, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.water_drop, color: c, size: uh * 0.38),
            Text('RECYCLER ${i + 1}',
                style: TextStyle(
                    color: c, fontSize: 8, fontWeight: FontWeight.bold)),
            Text(built ? (strain ? 'STRAIN' : 'AUTO') : 'EMPTY',
                style: TextStyle(color: c, fontSize: 8)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: gameController,
      builder: (context, _) {
        final g = gameController.game;
        final recyclers = g.buildings['Water Recycler']!;
        final canBuild = g.decisionPhase &&
            g.actionPoints >= buildActionCost &&
            !g.atMax('Water Recycler');
        final strain = g.event == 'Water System Strain' && !g.mitigated;
        final int filter = g.filterHealth.round();
        final sel = selected;
        final selBuilt = sel < recyclers;
        final need = (g.crewCount * waterPerPerson).round();
        final cycleCost = g.waterCycleCost.round();
        final cycleYield = g.waterCycleYield.round();
        final enoughEnergy = g.energy >= cycleCost;
        final canRepair = recyclers > 0 &&
            (strain
                ? gameController.canRespond
                : g.decisionPhase && g.energy >= recyclerMaintainEnergy);

        String message;
        if (msg != null) {
          message = msg!;
        } else if (recyclers == 0) {
          message = 'No recycler, Cadet! Without it the water runs out fast.';
        } else if (!enoughEnergy) {
          message =
              'Not enough energy for the auto water cycle! Go to the Solar Field and tap the battery to collect energy.';
        } else if (strain) {
          message =
              'The recycler is under strain! Repair it before the filters fail.';
        } else {
          message =
              'Four crew drink $need Water a Sol. The recycler runs by itself at the end of the Sol: it spends $cycleCost energy and gives +$cycleYield water.';
        }

        return ScreenFrame(
          accent: Colors.blueAccent,
          infoTitle: 'WATER TANK',
          infoLines: [
            'Level: ${g.water.round()} / 100',
            'Ops: $need / Sol (${g.crewCount} crew)',
            'Auto cycle: +$cycleYield water',
            'Auto cost: $cycleCost energy / Sol',
            'Filter: $filter%',
          ],
          background: Stack(
            fit: StackFit.expand,
            children: [
              Container(color: const Color(0xFF070D18)),
              SmartImage.one(kWater, 'Interior-Wall',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  fallback: const SizedBox.shrink()),
            ],
          ),
          scene: LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              final h = c.maxHeight;
              final tankH = (h - 14) * 0.78;
              final tankW = (w * 0.20).clamp(80.0, tankH * 0.9).toDouble();
              final tankL = w * 0.27;
              final gaugeL = tankL + tankW + 8;
              final pipeL = gaugeL + 38;
              final unitsL = pipeL + w * 0.09;
              final uh = (h * 0.27).clamp(44.0, 68.0).toDouble();

              Widget pipe(double top) => Positioned(
                    left: pipeL,
                    top: top,
                    width: w * 0.09 + 12,
                    child: Container(height: 6, color: const Color(0xFF6C7A8C)),
                  );

              return Stack(
                children: [
                  // الخزان
                  Positioned(
                      left: tankL,
                      top: 7 + (h - 14 - tankH) / 2,
                      child: _tank(tankW, tankH, g.water)),
                  // عداد المستوى
                  Positioned(
                      left: gaugeL,
                      top: 10 + (h - 14 - tankH) / 2,
                      child: _gauge(tankH - 6, g.water)),
                  // مواسير وصمامات
                  pipe(h * 0.20),
                  pipe(h * 0.60),
                  Positioned(
                    left: pipeL + 6,
                    top: h * 0.20 - 24,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        valveHabitat = !valveHabitat;
                        msg = valveHabitat
                            ? 'Valve to the habitat is OPEN. The crew has water.'
                            : 'Valve to the habitat is CLOSED. The crew gets no water!';
                      }),
                      child: _valve('HABITAT', valveHabitat),
                    ),
                  ),
                  Positioned(
                    left: pipeL + 6,
                    top: h * 0.60 - 24,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        valveGreenhouse = !valveGreenhouse;
                        msg = valveGreenhouse
                            ? 'Valve to the greenhouse is OPEN. The crops are watered.'
                            : 'Valve to the greenhouse is CLOSED. The crops are dry!';
                      }),
                      child: _valve('GREENHOUSE', valveGreenhouse),
                    ),
                  ),
                  // المضخة
                  Positioned(
                    left: pipeL + 6,
                    bottom: 8,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        pumpOn = !pumpOn;
                        msg = pumpOn
                            ? 'Pump ON. Water is moving through the system.'
                            : 'Pump OFF. Nothing is circulating!';
                      }),
                      child: _valve('PUMP', pumpOn),
                    ),
                  ),
                  // وحدات إعادة التدوير
                  Positioned(
                    left: unitsL + 8,
                    top: 6,
                    child: Column(
                      children: [
                        _unit(0, 0 < recyclers, sel == 0, strain, uh),
                        const SizedBox(height: 6),
                        _unit(1, 1 < recyclers, sel == 1, strain, uh),
                        if (recyclers > 2)
                          Text('+${recyclers - 2} more units',
                              style: const TextStyle(
                                  color: Colors.cyanAccent, fontSize: 9)),
                      ],
                    ),
                  ),
                  // زرار الاختبار + الذهاب للألواح
                  Positioned(
                    right: 8,
                    bottom: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        PixelButton(
                          label: '☀ SOLAR FIELD',
                          color: Colors.amber,
                          height: 26,
                          onTap: () => Navigator.push(
                            context,
                            gameRoute(const SolarFieldScreen()),
                          ),
                        ),
                        const SizedBox(height: 4),
                        PixelButton(
                          label: 'TEST',
                          assetNames: const ['Button-Test-Meter'],
                          height: 26,
                          onTap: () => showDialog(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              backgroundColor: const Color(0xFF0D131E),
                              title: const Text('Water Test',
                                  style: TextStyle(color: Colors.cyanAccent)),
                              content: Text(
                                'Tank level: ${g.water.round()} / 100\n'
                                'Recyclers: $recyclers\n'
                                'Auto cycle costs: $cycleCost energy (you have ${g.energy.round()})\n'
                'Auto cycle gives: +$cycleYield water\n'
                                'Filter condition: $filter%\n'
                                'Quality: ${filter >= 60 ? 'GOOD' : 'POOR, maintain the recycler'}',
                                style: const TextStyle(
                                    color: Colors.white70, height: 1.5),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext),
                                  child: const Text('OK',
                                      style:
                                          TextStyle(color: Colors.cyanAccent)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          dialogue: DialogueBox(
            speaker: nadia,
            mood: !enoughEnergy ? 'Worried' : commanderMood(g),
            text: message,
          ),
          detail: DetailPanel(
            lines: [
              detailLine('RECYCLER ${(sel + 1).toString().padLeft(2, '0')}',
                  color: Colors.amber, bold: true),
              if (selBuilt) ...[
                detailLine('Auto: +${waterCycleOutput.round()} Water / Sol'),
                detailLine(
                    !enoughEnergy
                        ? 'Status: NO POWER'
                        : (strain ? 'Status: DEGRADED' : 'Status: AUTO'),
                    color: (!enoughEnergy || strain)
                        ? Colors.redAccent
                        : Colors.greenAccent,
                    bold: true),
                detailLine('Filter: $filter%   Energy: ${g.energy.round()}'),
              ] else
                detailLine(g.atMax('Water Recycler')
                    ? 'Maximum ${buildingMax['Water Recycler']} units reached.'
                    : 'Not built yet. Add a unit (2 AP).'),
            ],
            buttons: [
              PixelButton(
                label: 'ADD UNIT',
                assetNames: const ['Button-Action-AddUnit'],
                color: Colors.greenAccent,
                height: 22,
                onTap: canBuild
                    ? () {
                        gameController.build('Water Recycler');
                        setState(() => msg =
                            'New recycler online! Each auto cycle now gives more water and costs ${waterCycleEnergy.round()} more energy.');
                      }
                    : null,
              ),
              PixelButton(
                label: 'REPAIR  ${recyclerMaintainEnergy.round()}⚡',
                assetNames: const ['Button-Action-Repair'],
                color: Colors.amber,
                height: 22,
                onTap: canRepair
                    ? () {
                        if (strain) {
                          gameController.respond();
                        } else {
                          gameController.maintain('Water Recycler');
                        }
                        setState(() => msg =
                            'Filters serviced for ${recyclerMaintainEnergy.round()} energy. Full output again.');
                      }
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _valve(String label, bool open) {
    final Color c = open ? Colors.greenAccent : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1E36),
        border: Border.all(color: c, width: 2),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text('$label ${open ? 'ON' : 'OFF'}',
          style:
              TextStyle(color: c, fontSize: 8, fontWeight: FontWeight.bold)),
    );
  }
}
