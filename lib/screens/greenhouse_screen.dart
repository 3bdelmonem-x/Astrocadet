import 'package:flutter/material.dart' hide Text;
import '../widgets/game_text.dart';
import '../audio/audio_service.dart';
import '../game/crew.dart';
import '../game/game_controller.dart';
import '../game/game_engine.dart';
import '../widgets/pixel_ui.dart';
import '../widgets/screen_frame.dart';
import '../widgets/smart_asset.dart';

/// الصوبة الزراعية: MAINTAIN يروي الأحواض ويجهز محصولاً للحصاد في كل حوض.
class GreenhouseScreen extends StatefulWidget {
  const GreenhouseScreen({super.key});

  @override
  State<GreenhouseScreen> createState() => _GreenhouseScreenState();
}

class _GreenhouseScreenState extends State<GreenhouseScreen> {
  int selected = 0;
  bool lightsOn = true;
  String? msg;

  // مقاس المشهد الأصلي (زي باقي الخلفيات 885x459)
  static const double stageW = 885;
  static const double stageH = 459;

  // مكان كل حوض في المشهد + عرضه
  static const List<Offset> _bedPos = [
    Offset(141, 150),
    Offset(354, 141),
    Offset(569, 150),
    Offset(74, 215),
    Offset(326, 225),
    Offset(578, 205),
  ];
  static const List<double> _bedW = [176, 176, 176, 231, 231, 231];

  SmartImage _img(String name, {double? height, double? width, BoxFit? fit}) =>
      SmartImage.one(
        kGreen,
        name,
        height: height,
        width: width,
        fit: fit ?? BoxFit.contain,
      );

  Widget _layer(String name, double x, double y) => Positioned(
    left: x,
    top: y,
    child: SmartImage.one(kGreen, name, fallback: const SizedBox.shrink()),
  );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: gameController,
      builder: (context, _) {
        final g = gameController.game;
        final built = g.greenhouseBuildSols;
        final ripeCount = g.activeGreenhouses();
        final canPlant =
            g.decisionPhase &&
            g.water >= plantWaterCost &&
            !g.atMax('Greenhouse');
        final canMaintain =
            built.isNotEmpty &&
            g.decisionPhase &&
            !g.irrigated &&
            g.water >= greenhouseMaintainWater;
        final contaminated = g.event == 'Crop Contamination' && !g.mitigated;

        bool isRipe(int i) =>
            i < built.length && g.sol - built[i] >= greenhouseGrowTime;
        double stored(int i) => i < g.crops.length ? g.crops[i] : 0;
        bool ready(int i) => stored(i) >= cropMinHarvest;
        int growth(int i) {
          if (i >= built.length) return 0;
          if (ready(i)) return 100;
          return ((g.sol - built[i]) / greenhouseGrowTime * 100)
              .clamp(0.0, 100.0)
              .round();
        }

        String bedArt(int i) {
          if (i < 3) {
            if (ready(i)) return 'Bed-02';
            return i == 1 ? 'Bed-03' : 'Bed-01';
          }
          return ready(i) ? 'Bed-04' : 'Bed-05';
        }

        void tapBed(int i) {
          audio.sfx('ui_tap');
          setState(() {
            selected = i;
            if (i >= built.length) {
              msg =
                  'Empty bed. Plant a greenhouse here (${plantWaterCost.round()} water).';
            } else if (ready(i)) {
              final got = gameController.harvest(i);
              msg = got > 0
                  ? 'Harvested +${got.round()} food from bed ${i + 1}!'
                  : 'The food counter is full, nothing to add.';
            } else if (!isRipe(i)) {
              msg =
                  'Bed ${i + 1} is still growing (${growth(i)}%). Be patient, Cadet.';
            } else {
              msg = g.irrigated
                  ? 'Nothing to harvest yet. Tomorrow this bed gives ${bedYield.round()} food.'
                  : 'Nothing to harvest yet. Press MAINTAIN to water the beds, and tomorrow each ripe bed gives ${bedYield.round()} food.';
            }
          });
        }

        Widget bed(int i) {
          final isBuilt = i < built.length;
          final pos = _bedPos[i];
          final w = _bedW[i];
          return Positioned(
            left: pos.dx,
            top: pos.dy,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => tapBed(i),
              child: SizedBox(
                width: w,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (isBuilt)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: SizedBox(
                          key: ValueKey<String>(bedArt(i)),
                          child: _img(bedArt(i), width: w),
                        ),
                      )
                    else
                      Container(
                        width: w,
                        height: 62,
                        margin: const EdgeInsets.only(top: 14),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          border: Border.all(color: Colors.white24, width: 2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.add,
                            color: Colors.white38,
                            size: 28,
                          ),
                        ),
                      ),
                    if (i == selected)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.cyanAccent,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (isBuilt && stored(i) >= 1)
                      Positioned(
                        right: 4,
                        bottom: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          color: Colors.black87,
                          child: Text(
                            '+${stored(i).round()}',
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
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

        // المشهد كله بمقاس ثابت ويتكبر/يتصغر على الشاشة
        final hasSceneBackground =
            AssetFinder.find(const [kGreen], const ['Greenhouse-Background']) !=
            null;
        final stage = RepaintBoundary(
          child: ClipRect(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: stageW,
                height: stageH,
                child: Stack(
                  children: [
                    if (hasSceneBackground)
                      Positioned.fill(
                        child: SmartImage.one(
                          kGreen,
                          'Greenhouse-Background',
                          width: stageW,
                          height: stageH,
                          fit: BoxFit.fill,
                          fallback: const SizedBox.shrink(),
                        ),
                      )
                    else ...[
                      _layer('Interior-Wall', 0, 0),
                      _layer('Floor', 0, 254),
                      Positioned(
                        left: 56,
                        top: 49,
                        child: ShaderMask(
                          blendMode: BlendMode.srcIn,
                          shaderCallback: (rect) => const LinearGradient(
                            colors: [Color(0xFF7A3636), Color(0xFFF2A65A)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ).createShader(rect),
                          child: SmartImage.one(
                            kGreen,
                            'Dome-Glass-Sky',
                            fallback: const SizedBox.shrink(),
                          ),
                        ),
                      ),
                      _layer('Sun', 640, 100),
                      Positioned(
                        left: 176,
                        top: 60,
                        child: Opacity(
                          opacity: lightsOn ? 1 : 0.15,
                          child: SmartImage.one(
                            kGreen,
                            'Grow-Lights',
                            fallback: const SizedBox.shrink(),
                          ),
                        ),
                      ),
                      _layer('Dome-Ribs', 89, 49),
                      _layer('Dome-Frame', 41, 44),
                    ],
                    for (var i = 0; i < 6; i++) bed(i),
                  ],
                ),
              ),
            ),
          ),
        );

        // رسالة القائدة
        String message;
        if (msg != null) {
          message = msg!;
        } else if (built.isEmpty) {
          message =
              'No greenhouse yet, Cadet! Plant one. It costs ${plantWaterCost.round()} water from the tank and the crops take $greenhouseGrowTime Sols to grow.';
        } else if (contaminated) {
          message =
              'The crops are contaminated! Use FIX before the plants die.';
        } else if (g.storedCrops >= cropMinHarvest) {
          message =
              'The crops are ready! Tap the beds with the golden box to harvest and raise our food.';
        } else if (g.plantHealth < 50) {
          message =
              'The plants look sick. Maintain them, they give us our oxygen too!';
        } else {
          message = g.irrigated
              ? 'The beds are ready! Tap each bed to harvest up to ${greenhouseHarvestYield.round()} food.'
              : 'Press MAINTAIN (${greenhouseMaintainWater.round()} water) to grow the plants. Tap each ripe bed to harvest ${greenhouseHarvestYield.round()} food.';
        }

        final sel = selected;
        final selBuilt = sel < built.length;
        final selState = !selBuilt
            ? 'EMPTY'
            : (ready(sel) ? 'RIPE' : (isRipe(sel) ? 'REGROWING' : 'GROWING'));
        final o2FromPlants = ripeCount * plantOxygen * g.plantFactor;

        return ScreenFrame(
          accent: Colors.greenAccent,
          infoTitle: 'GREENHOUSE 01',
          infoLines: [
            'Status: ${built.isEmpty ? 'NONE' : (ripeCount > 0 ? 'ACTIVE' : 'GROWING')}',
            'Plant health: ${g.plantHealth.round()}%',
            'Oxygen from plants: +${o2FromPlants.round()} / Sol',
            'Stored crops: ${g.storedCrops.round()} food',
          ],
          background: Container(color: const Color(0xFF09120E)),
          scene: Stack(
            children: [
              Positioned.fill(child: stage),
              // أدوات التحكم (يمين)
              Positioned(
                right: 6,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF070B14).withValues(alpha: 0.9),
                    border: Border.all(color: Colors.cyan, width: 2),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() {
                          lightsOn = !lightsOn;
                          msg = lightsOn
                              ? 'Grow lights ON. The plants love it!'
                              : 'Grow lights OFF. Plants need light to grow.';
                        }),
                        child: Opacity(
                          opacity: lightsOn ? 1 : 0.45,
                          child: _img('Switch-Grow-Lights', height: 30),
                        ),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () => setState(
                          () => msg =
                              'Climate is stable: 22 degrees inside the dome.',
                        ),
                        child: _img('Dial-Climate', height: 40),
                      ),
                      const SizedBox(height: 6),
                      PixelButton(
                        label: 'FIX ${cropTreatWater.round()}💧',
                        assetNames: const ['Button-Action-2'],
                        height: 24,
                        color: Colors.amber,
                        onTap: contaminated && gameController.canRespond
                            ? () {
                                gameController.respond();
                                setState(
                                  () => msg =
                                      'Contamination treated. Crops are safe.',
                                );
                              }
                            : () => setState(
                                () => msg = contaminated
                                    ? 'Not enough water to treat the crops.'
                                    : 'Nothing to fix. The crops are healthy.',
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          dialogue: DialogueBox(
            speaker: nadia,
            mood: contaminated ? 'Worried' : commanderMood(g),
            text: message,
          ),
          detail: DetailPanel(
            lines: [
              detailLine(
                'BED ${(sel + 1).toString().padLeft(2, '0')} - $selState',
                color: Colors.amber,
                bold: true,
              ),
              if (selBuilt) ...[
                detailLine(
                  'Growth: ${growth(sel)}%   Health: ${g.plantHealth.round()}%',
                ),
                detailLine(
                  'Stored: ${stored(sel).round()} food',
                  color: Colors.greenAccent,
                  bold: true,
                ),
                detailLine(
                  'Watered today: ${g.irrigated ? 'YES' : 'NO'}   Water: ${g.water.round()}',
                ),
              ] else
                detailLine(
                  g.atMax('Greenhouse')
                      ? 'Maximum ${buildingMax['Greenhouse']} beds reached.'
                      : 'Empty bed. Plant it for ${plantWaterCost.round()} water.',
                ),
            ],
            buttons: [
              PixelButton(
                label: 'HARVEST ALL',
                assetNames: const ['Button-Harvest'],
                color: Colors.greenAccent,
                height: 22,
                onTap: g.storedCrops >= 1
                    ? () {
                        final got = gameController.harvestAll();
                        setState(
                          () => msg = got > 0
                              ? 'Harvested +${got.round()} food in total!'
                              : 'The food counter is full.',
                        );
                      }
                    : null,
              ),
              PixelButton(
                label: g.irrigated
                    ? 'WATERED'
                    : 'MAINTAIN ${greenhouseMaintainWater.round()}💧',
                assetNames: const ['Button-Maintain'],
                height: 22,
                onTap: canMaintain
                    ? () {
                        gameController.maintain('Greenhouse');
                        setState(
                          () => msg =
                              'Plants grown! Tap each bed to harvest ${greenhouseHarvestYield.round()} food.',
                        );
                      }
                    : null,
              ),
              PixelButton(
                label: 'PLANT ${plantWaterCost.round()}💧',
                assetNames: const ['Button-Build-Greenhouse'],
                color: Colors.greenAccent,
                height: 22,
                onTap: canPlant
                    ? () {
                        gameController.build('Greenhouse');
                        setState(
                          () => msg =
                              'New bed planted for ${plantWaterCost.round()} water! Ripe in $greenhouseGrowTime Sols.',
                        );
                      }
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }
}
