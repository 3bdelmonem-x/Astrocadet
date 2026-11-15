import 'package:flutter/material.dart' hide Text;
import 'game_text.dart';
import '../game/game_controller.dart';
import '../game/game_engine.dart';
import '../localization/game_localization.dart';
import 'pixel_ui.dart';

class _BuildItem {
  final String name;
  final String info;
  final IconData icon;
  const _BuildItem(this.name, this.info, this.icon);
}

const List<_BuildItem> _items = [
  _BuildItem(
    'Solar Panels',
    '+15 energy / Sol (3% in dust storms)',
    Icons.wb_sunny_outlined,
  ),
  _BuildItem('Nuclear Unit', '+12 energy / Sol, storm-proof', Icons.bolt),
  _BuildItem('Oxygen Generator', '+20 oxygen / Sol, uses 6 energy', Icons.air),
  _BuildItem(
    'Water Recycler',
    '+15 water / Sol (auto cycle), 5 energy per cycle',
    Icons.water_drop_outlined,
  ),
  _BuildItem(
    'Greenhouse',
    '+10 food per watered Sol, +6 oxygen once grown ($greenhouseGrowTime Sols)',
    Icons.eco_outlined,
  ),
];

class BuildDialog extends StatelessWidget {
  const BuildDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.9;

    return ListenableBuilder(
      listenable: gameController,
      builder: (context, _) {
        final g = gameController.game;
        final canAp = g.decisionPhase && g.actionPoints >= buildActionCost;
        final canSmall = g.decisionPhase && g.actionPoints >= 1;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(12),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 600, maxHeight: maxHeight),
            child: PixelPanel(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          gameText('BASE ACTIONS'),
                          style: TextStyle(
                            color: Colors.cyanAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      _chip(
                        'AP ${g.actionPoints}/$actionPointCap',
                        Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      _chip('ENERGY ${g.energy.round()}', Colors.cyanAccent),
                      const SizedBox(width: 4),
                      _chip('WATER ${g.water.round()}', Colors.lightBlueAccent),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final item in _items)
                          _row(context, item, g, canAp),
                        _habitatRow(g, canAp),
                        _adviceRow(context, g, canSmall),
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

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        gameText(text),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _row(BuildContext context, _BuildItem item, Game g, bool canAp) {
    final owned = g.buildings[item.name] ?? 0;
    final isGreenhouse = item.name == 'Greenhouse';
    final isRecycler = item.name == 'Water Recycler';

    // الزرع بيخصم مية، والباقي Action Points
    final maxed = g.atMax(item.name);
    final maxCount = buildingMax[item.name] ?? 99;
    final canBuild =
        !maxed &&
        (isGreenhouse ? (g.decisionPhase && g.water >= plantWaterCost) : canAp);
    final buildLabel = maxed
        ? 'MAX'
        : (isGreenhouse
              ? 'PLANT · ${plantWaterCost.round()} WATER'
              : 'BUILD · 2 AP');
    final canDemolish =
        owned > 0 && g.decisionPhase && g.actionPoints >= demolishActionCost;

    // الصيانة: معالج المياه بالطاقة، والصوبة بالمية
    final canMaintain = (isGreenhouse || isRecycler) && owned > 0;
    final canPayMaintain = isGreenhouse
        ? (g.decisionPhase &&
              !g.irrigated &&
              g.water >= greenhouseMaintainWater)
        : (g.decisionPhase && g.energy >= recyclerMaintainEnergy);
    final maintainLabel = isGreenhouse
        ? (g.irrigated
              ? 'WATERED TODAY'
              : 'WATER BEDS · ${greenhouseMaintainWater.round()} WATER')
        : 'FILTERS · ${recyclerMaintainEnergy.round()} ENERGY';

    String ownedText = 'Owned: $owned / $maxCount';
    if (isGreenhouse) {
      ownedText += '  (ripe: ${g.activeGreenhouses()})';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1E36),
        borderRadius: BorderRadius.circular(8),
        border: const Border(left: BorderSide(color: Colors.cyan, width: 4)),
      ),
      child: Row(
        children: [
          Icon(item.icon, color: Colors.white70, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gameText(item.name),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${gameText(item.info)}\n${gameText(ownedText)}',
                  style: const TextStyle(color: Colors.white60, fontSize: 10),
                ),
              ],
            ),
          ),
          if (canMaintain) ...[
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.amber),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
              ),
              onPressed: canPayMaintain
                  ? () => gameController.maintain(item.name)
                  : null,
              child: Text(
                gameText(maintainLabel),
                style: const TextStyle(color: Colors.amber, fontSize: 9),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Tooltip(
            message: gameText('Demolish one (1 AP)'),
            child: IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(
                Icons.delete_outline,
                color: canDemolish ? Colors.redAccent : Colors.white24,
                size: 20,
              ),
              onPressed: canDemolish
                  ? () => _confirmDemolish(context, item.name)
                  : null,
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isGreenhouse ? Colors.greenAccent : Colors.cyan,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
            ),
            onPressed: canBuild ? () => gameController.build(item.name) : null,
            child: Text(
              gameText(buildLabel),
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// تأكيد الهدم (1 AP) عشان مفيش حد يهدم بالغلط
  Future<void> _confirmDemolish(BuildContext context, String name) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0D131E),
        title: Text(
          gameText('Demolish $name?'),
          style: const TextStyle(color: Colors.redAccent),
        ),
        content: Text(
          gameText(
            'One $name will be removed. This costs $demolishActionCost AP and you do not get anything back.',
          ),
          style: const TextStyle(color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              gameText('CANCEL'),
              style: TextStyle(color: Colors.cyanAccent),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              gameText('DEMOLISH'),
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (yes == true) gameController.demolish(name);
  }

  Widget _habitatRow(Game g, bool canAp) {
    final maxed = g.habitatLevel >= 3;
    final perSol = radiationPerSol * habitatMultipliers[g.habitatLevel - 1];
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1E36),
        borderRadius: BorderRadius.circular(8),
        border: const Border(left: BorderSide(color: Colors.orange, width: 4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, color: Colors.white70, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gameText('Habitat shielding'),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  gameText(
                    'Level ${g.habitatLevel} / 3: radiation +${perSol.toStringAsFixed(1)} per Sol',
                  ),
                  style: const TextStyle(color: Colors.white60, fontSize: 10),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
            ),
            onPressed: (canAp && !maxed)
                ? () => gameController.upgradeHabitat()
                : null,
            child: Text(
              gameText(maxed ? 'MAX' : 'UPGRADE · 2 AP'),
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _adviceRow(BuildContext context, Game g, bool canSmall) {
    final blackout = g.conjunction;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1E36),
        borderRadius: BorderRadius.circular(8),
        border: const Border(left: BorderSide(color: Colors.amber, width: 4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.support_agent, color: Colors.white70, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gameText('Ask Mission Control'),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  gameText(
                    blackout
                        ? 'No contact during the blackout.'
                        : 'Get advice on what to fix next.',
                  ),
                  style: const TextStyle(color: Colors.white60, fontSize: 10),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
            ),
            onPressed: (canSmall && !blackout)
                ? () {
                    final msg = gameController.askAdvice();
                    if (msg == null) return;
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        backgroundColor: const Color(0xFF0D131E),
                        title: Text(
                          gameText('Mission Control'),
                          style: TextStyle(color: Colors.amber),
                        ),
                        content: Text(
                          msg,
                          style: const TextStyle(
                            color: Colors.white70,
                            height: 1.4,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: Text(
                              gameText('OK'),
                              style: TextStyle(color: Colors.cyanAccent),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                : null,
            child: Text(
              gameText('ASK · 1 AP'),
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
