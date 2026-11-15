import 'package:flutter/material.dart' hide Text;
import 'game_text.dart';
import '../game/game_controller.dart';
import '../game/game_engine.dart';
import '../audio/audio_service.dart';
import 'hud_dialogs.dart';
import 'pixel_ui.dart';
import 'settings_panel.dart';
import 'smart_asset.dart';
import '../localization/game_localization.dart';

/// شريط الموارد العلوي (حسب تصميم الـ Figma): SOL، 6 موارد بأشرطة، الجرس، القايمة.
class TopHudBar extends StatelessWidget {
  final VoidCallback onNotificationsTap;
  final VoidCallback onTodoListTap;

  const TopHudBar({
    super.key,
    required this.onNotificationsTap,
    required this.onTodoListTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: gameController,
      builder: (context, _) {
        final g = gameController.game;
        // التوقع: لو معملتش حاجة تاني، إيه اللي هيحصل في آخر الـ Sol
        final d = g.forecast();
        final solText = g.sol.toString().padLeft(2, '0');
        final hasAlert =
            (g.event != 'None' && g.decisionPhase) || g.warnings().isNotEmpty;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF070B12).withValues(alpha: 0.92),
            border: const Border(
              bottom: BorderSide(color: Colors.cyan, width: 1.5),
            ),
          ),
          child: Row(
            children: [
              // SOL
              PixelPanel(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.public,
                      color: Colors.deepOrangeAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          gameText('MARS OUTPOST'),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 8,
                          ),
                        ),
                        Text(
                          'SOL $solText/$missionLength',
                          style: const TextStyle(
                            color: Colors.cyanAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _Tile(
                  icon: Icons.air,
                  label: 'O²',
                  value: g.oxygen,
                  delta: d['oxygen']!,
                  color: Colors.cyan,
                ),
              ),
              Expanded(
                child: _Tile(
                  icon: Icons.bolt,
                  label: gameText('Energy'),
                  value: g.energy,
                  max: energyLimit,
                  delta: d['energy']!,
                  battery: g.battery,
                  color: Colors.amber,
                ),
              ),
              Expanded(
                child: _Tile(
                  icon: Icons.water_drop,
                  label: gameText('Water'),
                  value: g.water,
                  delta: d['water']!,
                  color: Colors.blue,
                ),
              ),
              Expanded(
                child: _Tile(
                  icon: Icons.eco,
                  label: gameText('Food'),
                  value: g.food,
                  delta: d['food']!,
                  color: Colors.green,
                ),
              ),
              Expanded(
                child: _Tile(
                  icon: Icons.radar,
                  label: gameText('Radiation'),
                  value: g.radiation,
                  delta: d['radiation']!,
                  color: Colors.orange,
                  badWhenUp: true,
                ),
              ),
              Expanded(
                child: _Tile(
                  icon: Icons.favorite,
                  label: gameText('Crew Health'),
                  value: g.health,
                  delta: d['health']!,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(width: 6),
              _IconButtonBox(
                names: const ['Button-Bell'],
                icon: Icons.notifications,
                color: Colors.amber,
                alert: hasAlert,
                onTap: () {
                  onNotificationsTap();
                  showNotificationsDialog(context);
                },
              ),
              const SizedBox(width: 6),
              _IconButtonBox(
                names: const ['Button-Clipboard'],
                icon: Icons.assignment,
                color: Colors.cyanAccent,
                onTap: () {
                  onTodoListTap();
                  showTodoDialog(context);
                },
              ),
              const SizedBox(width: 6),
              _GearButton(onTap: () => showSettingsPanel(context)),
            ],
          ),
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final double max;
  final double delta;
  final Color color;
  final bool badWhenUp;
  final double? battery; // شحنة البطارية بتظهر جنب عداد الطاقة

  const _Tile({
    required this.icon,
    required this.label,
    required this.value,
    required this.delta,
    required this.color,
    this.max = 100,
    this.badWhenUp = false,
    this.battery,
  });

  @override
  Widget build(BuildContext context) {
    final up = delta >= 0.5;
    final down = delta <= -0.5;
    final deltaText = '${delta > 0 ? '+' : ''}${delta.round()}';
    final good = badWhenUp ? down : up;
    final double progress = max <= 0
        ? 0.0
        : (value / max).clamp(0.0, 1.0).toDouble();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1E36),
        border: Border.all(color: color.withValues(alpha: 0.8), width: 1.5),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 3),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$label ',
                        style: TextStyle(
                          color: color,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        value.round().toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (up || down)
                        Text(
                          up ? ' ▲$deltaText' : ' ▼$deltaText',
                          style: TextStyle(
                            color: good ? Colors.greenAccent : Colors.redAccent,
                            fontSize: 8,
                          ),
                        ),
                      if (battery != null) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.battery_charging_full,
                          size: 9,
                          color: Colors.orangeAccent,
                        ),
                        Text(
                          '${battery!.round()}',
                          style: const TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconButtonBox extends StatelessWidget {
  final List<String> names;
  final IconData icon;
  final Color color;
  final bool alert;
  final VoidCallback onTap;

  const _IconButtonBox({
    required this.names,
    required this.icon,
    required this.color,
    required this.onTap,
    this.alert = false,
  });

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1E36),
        border: Border.all(color: Colors.cyan, width: 2),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Icon(icon, color: color, size: 18),
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SmartImage.any(kBase, names, height: 34, width: 34, fallback: box),
          if (alert)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// "Current Event" البوكس اللي تحت الشريط في شاشة القاعدة
class CurrentEventBox extends StatelessWidget {
  final VoidCallback? onTap;
  const CurrentEventBox({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: gameController,
      builder: (context, _) {
        final g = gameController.game;
        final active = g.event != 'None';
        final color = active ? Colors.redAccent : Colors.cyan;
        return GestureDetector(
          onTap: active ? onTap : null,
          child: InfoBox(
            title: 'Current Event',
            color: color,
            lines: [
              active ? g.event : 'No active event',
              active
                  ? (g.mitigated ? 'Handled this Sol.' : 'Tap to decide.')
                  : 'The base is stable for now.',
              'Action Points: ${g.actionPoints}',
            ],
          ),
        );
      },
    );
  }
}

/// زرار الإعدادات: بيفتح النافذة الصغيرة (كتم الصوت والمزيكا، حجم الخط، شرح اللعبة)
class _GearButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GearButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        audio.sfx('ui_panel_open');
        onTap();
      },
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFF0D1E36),
          border: Border.all(color: Colors.cyan, width: 2),
          borderRadius: BorderRadius.circular(3),
        ),
        child: const Icon(Icons.settings, size: 18, color: Colors.cyanAccent),
      ),
    );
  }
}
