import 'package:flutter/material.dart' hide Text;
import '../widgets/game_text.dart';
import '../audio/audio_service.dart';
import '../game/crew.dart';
import '../game/game_controller.dart';
import '../game/game_engine.dart';
import '../localization/game_localization.dart';
import '../widgets/pixel_ui.dart';
import '../widgets/screen_frame.dart';
import '../widgets/smart_asset.dart';

/// حقل الألواح الشمسية: الألواح بتشحن البطارية، واللاعب بيدوس على البطارية
/// يسحب الطاقة لعداد الطاقة. ميل الألواح بيأثر على الإنتاج فعلاً.
class SolarFieldScreen extends StatefulWidget {
  const SolarFieldScreen({super.key});

  @override
  State<SolarFieldScreen> createState() => _SolarFieldScreenState();
}

class _SolarFieldScreenState extends State<SolarFieldScreen> {
  int selected = 0;
  String? msg; // رسالة مؤقتة بعد أي ضغطة

  SmartImage _img(String name, {double? height, double? width}) =>
      SmartImage.one(kSolar, name, height: height, width: width);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: gameController,
      builder: (context, _) {
        final g = gameController.game;
        final panels = g.buildings['Solar Panels']!;
        final maxPanels = buildingMax['Solar Panels']!;
        final fx = g.eventEffects();
        final dust = g.event == 'Dust Storm';
        final stowed = dust && g.mitigated;
        final broken = g.event == 'Equipment Malfunction' && !g.mitigated;
        final canBuild =
            g.decisionPhase &&
            g.actionPoints >= buildActionCost &&
            !g.atMax('Solar Panels');
        final canRespond = gameController.canRespond;
        final brokenIndex = panels - 1;
        final production = g.expectedProduction();
        final needs = g.autoDemand();
        final balance = production - needs;
        final eff = g.tiltEfficiency;

        String panelFile(int i) {
          if (i >= panels) return 'Solar-Panel-Back';
          if (i == selected) return 'Solar-Panel-Selected';
          if (broken && i == brokenIndex) return 'Solar-Panel-Damaged';
          if (dust && !stowed) return 'Solar-Panel-Dusty';
          return 'Solar-Panel-Front';
        }

        Widget panel(int i, double ph) {
          final built = i < panels;
          return GestureDetector(
            onTap: () => setState(() {
              audio.sfx('ui_hover_select');
              selected = i;
              msg = null;
            }),
            child: Opacity(
              opacity: built ? 1 : 0.25,
              child: _img(panelFile(i), height: ph),
            ),
          );
        }

        // معلومات اللوح المختار
        final sel = selected;
        final selBuilt = sel < panels;
        final selBroken = broken && sel == brokenIndex;
        final output = selBuilt && !selBroken
            ? (buildingOutput['Solar Panels']! *
                      fx[0] *
                      fx[1] *
                      eff *
                      (g.solarBreaker ? 1 : 0))
                  .round()
            : 0;

        String message;
        if (msg != null) {
          message = msg!;
        } else if (g.energy < 15 && g.battery >= 10) {
          message =
              'Your energy counter is low! Tap the battery to collect its energy.';
        } else if (!g.solarBreaker) {
          message = 'The breaker is OFF! The panels are not feeding the base.';
        } else if (dust) {
          message =
              'Dust storm! The panels barely work. Stow them, and a nuclear unit would help a lot.';
        } else if (broken) {
          message = 'One panel is damaged. Repair it to get the energy back.';
        } else if ((g.solarTilt - g.optimalTilt).abs() > 15) {
          message =
              'The sun is at ${g.optimalTilt.round()}% today. Move the TILT slider close to it for more energy.';
        } else if (balance < 0) {
          message =
              'We use ${needs.round()} energy a Sol but make only ${production.round()}. We need more panels!';
        } else {
          message =
              'The panels are glowing! Tap the battery every Sol to collect the energy.';
        }

        return ScreenFrame(
          accent: Colors.cyan,
          infoTitle: 'SOLAR FIELD',
          infoLines: [
            'Panels: $panels / $maxPanels${broken ? ' (1 damaged)' : ''}',
            'Making now: ${production.round()} / Sol',
            'Systems need: ${needs.round()} / Sol',
            'Balance: ${balance >= 0 ? '+' : ''}${balance.round()} / Sol',
            'Energy counter: ${g.energy.round()} / ${energyLimit.round()}',
            if (dust) 'DUST STORM: panels at ${(fx[0] * 100).round()}% output',
          ],
          background: SmartImage.one(
            kSolar,
            'backgraund',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            fallback: Container(color: const Color(0xFF130B09)),
          ),
          scene: Directionality(
            textDirection: TextDirection.ltr,
            child: LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth;
                final h = c.maxHeight;
                final ph = (h * 0.26).clamp(40.0, 78.0).toDouble();
                return Stack(
                  children: [
                    // الشمس
                    Positioned(
                      top: h * 0.04,
                      right: w * 0.27,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFFE6A8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withValues(alpha: 0.6),
                              blurRadius: 24,
                              spreadRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // الألواح: صفين × 3
                    Positioned(
                      left: w * 0.20,
                      right: w * 0.24,
                      top: h * 0.12,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              for (var i = 0; i < 3; i++) panel(i, ph),
                            ],
                          ),
                          SizedBox(height: h * 0.05),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              for (var i = 3; i < 6; i++) panel(i, ph),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // سلايدر الميل (بيأثر على الإنتاج فعلاً)
                    Positioned(
                      left: w * 0.18,
                      right: w * 0.24,
                      bottom: 2,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${gameText('TILT')} ${g.solarTilt.round()}%   ${gameText('SUN ANGLE')} ${g.optimalTilt.round()}%   ${gameText('OUTPUT')} ${(eff * 100).round()}%',
                            style: TextStyle(
                              color: eff >= 1.05
                                  ? Colors.greenAccent
                                  : (eff < 0.95
                                        ? Colors.redAccent
                                        : Colors.white70),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 5,
                              activeTrackColor: Colors.amber,
                              inactiveTrackColor: Colors.white24,
                              thumbColor: Colors.cyanAccent,
                              overlayShape: SliderComponentShape.noOverlay,
                            ),
                            child: Slider(
                              value: g.solarTilt,
                              min: 0,
                              max: 100,
                              onChanged: (v) => gameController.setTilt(v),
                              onChangeEnd: (v) {
                                audio.sfx('ui_tap');
                                setState(
                                  () => msg =
                                      'Tilt set to ${v.round()}%. The sun is at ${g.optimalTilt.round()}% today.',
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    // عمود اليمين: Stow + Breaker + Battery
                    Positioned(
                      right: 8,
                      top: 4,
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (dust && canRespond) {
                                gameController.respond();
                                setState(
                                  () => msg =
                                      'Panels stowed! We keep 10% output through the storm.',
                                );
                              } else {
                                setState(
                                  () => msg = dust
                                      ? 'Already handled, or no Action Points left.'
                                      : 'Stow the panels only during a dust storm.',
                                );
                              }
                            },
                            child: _img('Switch-Stow-Panels', height: 34),
                          ),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () {
                              gameController.toggleBreaker();
                              setState(
                                () => msg = gameController.game.solarBreaker
                                    ? 'Breaker ON. The panels feed the base again.'
                                    : 'Breaker OFF. No solar energy reaches the base!',
                              );
                            },
                            child: g.solarBreaker
                                ? _img('Breaker-ON', height: 48)
                                : SmartImage.any(kSolar, const [
                                    'Breaker-OFF',
                                    'Breaker-OF',
                                  ], height: 48),
                          ),
                          const SizedBox(height: 4),
                          // البطارية: اضغطي عليها عشان تفضيها وتاخدي الطاقة لعداد الطاقة
                          GestureDetector(
                            onTap: () {
                              final got = gameController.collectEnergy();
                              setState(
                                () => msg = got > 0
                                    ? 'Collected ${got.round()} energy! It is in your energy counter now.'
                                    : (gameController.game.battery <= 0
                                          ? 'The battery is empty. Panels charge it at the end of each Sol.'
                                          : 'Your energy counter is full (${energyLimit.round()}).'),
                              );
                            },
                            child: Opacity(
                              opacity:
                                  (0.45 + 0.55 * (g.battery / g.batteryMax))
                                      .clamp(0.0, 1.0)
                                      .toDouble(),
                              child: _img('Battery-Cabinet', height: 62),
                            ),
                          ),
                          Text(
                            '${gameText('TAP TO COLLECT')}\n${g.battery.round()}/${g.batteryMax.round()}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          dialogue: DialogueBox(
            speaker: nadia,
            mood: commanderMood(g),
            text: message,
          ),
          detail: DetailPanel(
            lines: [
              detailLine(
                'PANEL ${(sel + 1).toString().padLeft(2, '0')}',
                color: Colors.amber,
                bold: true,
              ),
              if (selBuilt) ...[
                detailLine('Output: $output Energy/Sol'),
                detailLine(
                  'Dust: ${dust && !stowed ? 'HIGH' : 'LOW'}   '
                  'Health: ${selBroken ? 'DAMAGED' : 'OK'}',
                ),
                detailLine('Tilt: ${g.solarTilt.round()}%'),
              ] else
                detailLine(
                  g.atMax('Solar Panels')
                      ? 'Maximum $maxPanels panels reached.'
                      : 'Empty slot. Build a panel (2 AP).',
                ),
            ],
            buttons: [
              PixelButton(
                label: g.atMax('Solar Panels') ? 'MAX' : 'BUILD',
                assetNames: const ['Button-Build-Panel'],
                color: Colors.greenAccent,
                height: 22,
                onTap: canBuild
                    ? () {
                        gameController.build('Solar Panels');
                        setState(() => msg = 'New panel online. More energy!');
                      }
                    : null,
              ),
              PixelButton(
                label: 'CLEAN',
                assetNames: const ['Button-Action-Clean'],
                height: 22,
                onTap: (dust && canRespond)
                    ? () {
                        gameController.respond();
                        setState(() => msg = 'Cleaned and stowed!');
                      }
                    : null,
              ),
              PixelButton(
                label: 'REPAIR',
                assetNames: const ['Button-Action-Repair', 'Button-Repair'],
                color: Colors.amber,
                height: 22,
                onTap: (g.event == 'Equipment Malfunction' && canRespond)
                    ? () {
                        gameController.respond();
                        setState(() => msg = 'Repaired! Output is back.');
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
