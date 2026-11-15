import 'package:flutter/material.dart' hide Text;
import 'game_text.dart';
import '../game/crew.dart';
import '../game/game_controller.dart';
import '../game/game_engine.dart';
import '../screens/facility_screens.dart';
import '../screens/greenhouse_screen.dart';
import '../screens/solar_field_screen.dart';
import '../screens/water_tank_screen.dart';
import 'event_card.dart';
import 'game_route.dart';
import 'pixel_ui.dart';

// مين بيبلغ عن الحدث (كل واحد في تخصصه)
CrewMember _reporterFor(String event) {
  switch (event) {
    case 'Dust Storm':
    case 'Equipment Malfunction':
      return karim;
    case 'Life Support Leak':
    case 'Crop Contamination':
    case 'Water System Strain':
      return amara;
    case 'Solar Flare':
      return youssef;
    default:
      return nadia;
  }
}

class _Note {
  final Color color;
  final String title;
  final String level;
  final String text;
  const _Note(this.color, this.title, this.level, this.text);
}

List<_Note> _buildNotes() {
  final g = gameController.game;
  final notes = <_Note>[];

  if (g.event != 'None') {
    final who = _reporterFor(g.event);
    final info = eventInfo[g.event];
    notes.add(_Note(
      Colors.redAccent,
      g.event,
      'HIGH',
      '${who.title} reports: ${info == null ? 'Something is wrong at the outpost.' : info[0]}',
    ));
  }

  for (final w in g.warnings()) {
    switch (w) {
      case 'Collect energy':
        notes.add(const _Note(Colors.amber, 'Energy Counter Low', 'MEDIUM',
            'Karim: The counter is almost empty but the battery has charge. Open the Battery and tap it to collect it.'));
        break;
      case 'Low energy':
        notes.add(const _Note(Colors.amber, 'Out of Energy', 'HIGH',
            'Karim: No energy left anywhere. Build solar panels or a nuclear unit.'));
        break;
      case 'Low oxygen':
        notes.add(const _Note(Colors.amber, 'Oxygen Running Low', 'MEDIUM',
            'Amara: Oxygen is low. The generators and plants must keep up with the crew.'));
        break;
      case 'Low water':
        notes.add(const _Note(Colors.amber, 'Water Running Low', 'MEDIUM',
            'Amara: Water is low. The recycler runs by itself each Sol, so keep energy available.'));
        break;
      case 'Low food':
        notes.add(const _Note(Colors.amber, 'Food Running Low', 'MEDIUM',
            'Amara: Food is low. Harvest the greenhouse crops.'));
        break;
      case 'Harvest crops':
        notes.add(const _Note(Colors.amber, 'Crops Ready', 'MEDIUM',
            'Amara: Crops are waiting. Tap the ripe beds in the greenhouse to harvest.'));
        break;
      case 'High radiation':
        notes.add(const _Note(Colors.redAccent, 'Radiation Rising', 'HIGH',
            'Youssef: Radiation is dangerous. Upgrade the habitat shielding now.'));
        break;
    }
  }

  if (g.sol >= 8 && g.sol <= 9) {
    notes.add(const _Note(Colors.amber, 'Blackout Approaching', 'MEDIUM',
        'Dr. Reyes: Earth contact drops at Sol 10. Stock up before then.'));
  }

  if (notes.isEmpty) {
    final hasHouses = g.buildings['Greenhouse']! > 0;
    notes.add(_Note(
      Colors.greenAccent,
      hasHouses ? 'Crop Check Complete' : 'Systems Check Complete',
      'NORMAL',
      hasHouses
          ? 'Amara reports the greenhouse is stable. Crop production is normal.'
          : 'Nadia reports the base is stable. No problems detected.',
    ));
  }
  return notes;
}

/// الإشعارات
void showNotificationsDialog(BuildContext parent) {
  final notes = _buildNotes();
  showDialog(
    context: parent,
    builder: (dialogContext) {
      final maxH = MediaQuery.of(dialogContext).size.height * 0.9;
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 560, maxHeight: maxH),
          child: PixelPanel(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.notifications, color: Colors.amber),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Notifications',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 1)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ],
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final n in notes)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D1E36),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: n.color, width: 2),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  border: Border.all(color: n.color, width: 2),
                                ),
                                child: Icon(Icons.priority_high,
                                    color: n.color, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(n.title,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12)),
                                    Text(n.level,
                                        style: TextStyle(
                                            color: n.color,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 9)),
                                    Text(n.text,
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 10,
                                            height: 1.25)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              PixelButton(
                                label: 'View Task',
                                color: n.color,
                                onTap: () {
                                  Navigator.pop(dialogContext);
                                  showTodoDialog(parent);
                                },
                              ),
                            ],
                          ),
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
}

class _Task {
  final String title;
  final String priority; // HIGH / MEDIUM / LOW
  final String text;
  final bool done;
  final void Function(BuildContext parent) action;
  const _Task(this.title, this.priority, this.text, this.done, this.action);
}

Color _priorityColor(String p) {
  switch (p) {
    case 'HIGH':
      return Colors.redAccent;
    case 'MEDIUM':
      return Colors.amber;
    default:
      return Colors.greenAccent;
  }
}

void _push(BuildContext parent, Widget screen) {
  Navigator.push(parent, gameRoute(screen));
}

List<_Task> _buildTasks() {
  final g = gameController.game;
  final tasks = <_Task>[];

  if (g.event != 'None' && g.event != 'Mars Solar Conjunction') {
    tasks.add(_Task(
      'Respond to ${g.event}',
      'HIGH',
      'Decide how to handle it before you end the Sol.',
      g.mitigated,
      (parent) => showEventCard(parent),
    ));
  }
  tasks.add(_Task(
    'Upgrade Habitat Shielding',
    'HIGH',
    'Radiation grows ${radiationPerSol.round()} per Sol. Reach shield level 2 early, or the mission fails.',
    g.habitatLevel >= 2,
    (parent) => _push(parent, const HabitatScreen()),
  ));
  tasks.add(_Task(
    'Collect Energy',
    g.energy < 20 ? 'HIGH' : 'MEDIUM',
    'Open the Battery and tap it to collect. Buildings run on your energy counter.',
    g.battery < 10,
    (parent) => _push(parent, const BatteryScreen()),
  ));
  tasks.add(_Task(
    'Harvest Crops',
    'MEDIUM',
    'Water the greenhouse (MAINTAIN), and tomorrow tap each ripe bed to add its food.',
    g.storedCrops < cropMinHarvest,
    (parent) => _push(parent, const GreenhouseScreen()),
  ));
  tasks.add(_Task(
    'Secure Oxygen Supply',
    'HIGH',
    'Build a 2nd Oxygen Generator. Four crew breathe 32 oxygen a Sol.',
    g.buildings['Oxygen Generator']! >= 2,
    (parent) => _push(parent, const OxygenGeneratorScreen()),
  ));
  tasks.add(_Task(
    'Secure Water Supply',
    'HIGH',
    'Build a 2nd Water Recycler. It runs by itself each Sol. Four crew need 20 water a Sol.',
    g.buildings['Water Recycler']! >= 2,
    (parent) => _push(parent, const WaterTankScreen()),
  ));
  tasks.add(_Task(
    'Grow Food',
    'HIGH',
    'Plant 2 Greenhouses (${plantWaterCost.round()} water each). Four crew eat 16 food a Sol.',
    g.buildings['Greenhouse']! >= 2,
    (parent) => _push(parent, const GreenhouseScreen()),
  ));
  tasks.add(_Task(
    'Add a Nuclear Unit',
    'HIGH',
    'A big dust storm hits around Sol $stormSol and the panels almost stop. The nuclear unit keeps producing.',
    g.buildings['Nuclear Unit']! >= 1,
    (parent) => _push(parent, const NuclearScreen()),
  ));
  tasks.add(_Task(
    'Match the Panel Tilt',
    'MEDIUM',
    'Move the TILT slider close to the sun angle. A good tilt gives up to 15% more energy.',
    (g.solarTilt - g.optimalTilt).abs() <= 15,
    (parent) => _push(parent, const SolarFieldScreen()),
  ));

  // المهام الناقصة الأول
  tasks.sort((a, b) {
    if (a.done != b.done) return a.done ? 1 : -1;
    return 0;
  });
  return tasks;
}

/// قايمة المهام (To-do list)
void showTodoDialog(BuildContext parent) {
  final g = gameController.game;
  final tasks = _buildTasks();
  showDialog(
    context: parent,
    builder: (dialogContext) {
      final maxH = MediaQuery.of(dialogContext).size.height * 0.92;
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 580, maxHeight: maxH),
          child: PixelPanel(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.assignment, color: Colors.cyanAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'To-do list    sol ${g.sol}/$missionLength',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ],
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final t in tasks)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D1E36),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: t.done ? Colors.greenAccent : Colors.cyan,
                                width: 2),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.list_alt,
                                  color: Colors.cyanAccent, size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(t.title,
                                        style: TextStyle(
                                            color: t.done
                                                ? Colors.white54
                                                : Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            decoration: t.done
                                                ? TextDecoration.lineThrough
                                                : TextDecoration.none)),
                                    Text(t.priority,
                                        style: TextStyle(
                                            color: _priorityColor(t.priority),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 9)),
                                    Text(t.text,
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 10,
                                            height: 1.25)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (t.done)
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.greenAccent, width: 2),
                                  ),
                                  child: const Icon(Icons.check,
                                      color: Colors.greenAccent, size: 26),
                                )
                              else
                                PixelButton(
                                  label: 'Do it now !',
                                  onTap: () {
                                    Navigator.pop(dialogContext);
                                    t.action(parent);
                                  },
                                ),
                            ],
                          ),
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
}
