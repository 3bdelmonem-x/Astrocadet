import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart' hide Text;
import '../widgets/game_text.dart';
import '../audio/audio_service.dart';
import '../game/crew.dart';
import '../game/game_controller.dart';
import '../game/game_engine.dart';
import '../localization/game_localization.dart';
import '../widgets/build_dialog.dart';
import '../widgets/crew_avatar.dart';
import '../widgets/dust_overlay.dart';
import '../widgets/event_card.dart';
import '../widgets/game_route.dart';
import '../widgets/game_image.dart';
import '../widgets/morning_report_dialog.dart';
import '../widgets/pixel_ui.dart';
import '../widgets/smart_asset.dart';
import '../widgets/sol_feedback_dialog.dart';
import '../widgets/tutorial_dialog.dart';
import '../widgets/top_hud_bar.dart';
import 'facility_screens.dart';
import 'greenhouse_screen.dart';
import 'main_menu_screen.dart';
import 'mission_control_screen.dart';
import 'mission_debrief_screen.dart';
import 'solar_field_screen.dart';
import 'water_tank_screen.dart';

class BaseViewScreen extends StatefulWidget {
  const BaseViewScreen({super.key});

  @override
  State<BaseViewScreen> createState() => _BaseViewScreenState();
}

class _BaseViewScreenState extends State<BaseViewScreen> {
  String? _grassMsg; // كلمة صغيرة تحت العشبة بعد الضغط
  Timer? _grassTimer;

  @override
  void dispose() {
    _grassTimer?.cancel();
    super.dispose();
  }

  void _tapGrass() {
    final got = gameController.gatherGrass();
    final g = gameController.game;
    setState(() {
      _grassMsg = got > 0
          ? '+${got.round()} FOOD'
          : (g.grassTaps >= grassTapsPerSol ? 'NEXT SOL' : 'FOOD FULL');
    });
    _grassTimer?.cancel();
    _grassTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _grassMsg = null);
    });
  }

  @override
  void initState() {
    super.initState();
    // أول مرة: شرح اللعبة، وبعده تقرير الصبح وبعده الحدث (لو في)
    WidgetsBinding.instance.addPostFrameCallback((_) => _firstRun());
  }

  Future<void> _firstRun() async {
    if (!mounted) return;
    final c = gameController;
    // من هنا ورايح أي تقدم بيتحفظ تلقائي (عشان زرار CONTINUE)
    c.markStarted();
    if (c.game.sol == 1 && !c.tutorialShown) {
      c.tutorialShown = true;
      await showTutorial(context);
    }
    // رجعنا من شاشة داخلية أو بنكمل لعبة محفوظة: تقرير الصبح اتعرض خلاص
    if (c.morningShownSol == c.game.sol && c.game.decisionPhase) {
      audio.onResumeGame(c.game);
      return;
    }
    _showMorning();
  }

  void _open(Widget screen) {
    audio.sfx('ui_hover_select');
    Navigator.push(context, gameRoute(screen));
  }

  void _showMorning() {
    if (!mounted) return;
    gameController.morningShownSol = gameController.game.sol;
    audio.onMorning(gameController.game);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => MorningReportDialog(onBegin: _showEventIfAny),
    );
  }

  void _showEventIfAny() {
    if (!mounted) return;
    final g = gameController.game;
    if (g.event == 'None' || !g.decisionPhase) return;
    showEventCard(context);
  }

  void _endSol() {
    gameController.endSol();
    final g = gameController.game;

    if (g.isOver) {
      final won = g.status == 'MISSION WIN';
      final message = won
          ? 'Congratulations ${gameController.cadetName}! You kept the Theta-9 training outpost alive for all $missionLength Sols.'
          : 'Life support failure! ${g.failureReason}.';
      audio.playJingle(
        won ? 'jingle_win' : 'jingle_lose',
        maxSeconds: won ? 9 : 6,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MissionDebriefScreen(won: won, message: message),
        ),
      );
      return;
    }
    audio.afterSol(g);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SolFeedbackDialog(
        onNextSol: () {
          gameController.startNextSol();
          WidgetsBinding.instance.addPostFrameCallback((_) => _showMorning());
        },
      ),
    );
  }

  Future<void> _confirmAbort() async {
    audio.sfx('ui_back');
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0D131E),
        title: const Text(
          'Leave the outpost?',
          style: TextStyle(color: Colors.amber),
        ),
        content: const Text(
          'Your progress is saved. Press CONTINUE in the main menu to pick up where you left off.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              audio.sfx('ui_back');
              Navigator.pop(dialogContext, false);
            },
            child: const Text(
              'Keep playing',
              style: TextStyle(color: Colors.cyanAccent),
            ),
          ),
          TextButton(
            onPressed: () {
              audio.sfx('ui_confirm');
              Navigator.pop(dialogContext, true);
            },
            child: const Text(
              'Save & exit',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (leave == true && mounted) {
      await gameController.saveNow();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainMenuScreen()),
        (route) => false,
      );
    }
  }

  // مين بيتكلم ويقول إيه، حسب الموقف (كل واحد في تخصصه)
  (CrewMember, String) _speak(Game g) {
    final warnings = g.warnings();
    if (warnings.contains('High radiation')) {
      return (
        youssef,
        'Radiation is getting dangerous! Upgrade the habitat shielding now.',
      );
    }
    if (warnings.contains('Collect energy')) {
      return (
        karim,
        'Our energy counter is low! Tap the Battery module to collect its charge.',
      );
    }
    if (warnings.contains('Low energy')) {
      return (
        karim,
        'We are out of energy! Build solar panels or a nuclear unit.',
      );
    }
    final life = warnings
        .where((w) => w == 'Low oxygen' || w == 'Low water' || w == 'Low food')
        .toList();
    if (life.isNotEmpty) {
      return (
        amara,
        'Careful: ${life.join(', ').toLowerCase()}. Keep energy for the auto water cycle, water the greenhouse, and check the generators.',
      );
    }
    if (warnings.contains('Harvest crops')) {
      return (amara, 'The crops are ready! Harvest them in the greenhouse.');
    }
    if (g.sol == 9 && g.event == 'None') {
      return (
        missionControl,
        'Last clear transmission, Cadet. Contact drops tomorrow. Stock up!',
      );
    }
    if (g.sol == 13 && g.event == 'None') {
      return (
        missionControl,
        'Contact restored! Good to hear from you, Cadet.',
      );
    }
    switch (g.event) {
      case 'Dust Storm':
      case 'Equipment Malfunction':
        return (karim, '${g.event}! Tap the Current Event box to decide.');
      case 'Life Support Leak':
      case 'Crop Contamination':
      case 'Water System Strain':
        return (amara, '${g.event}! Tap the Current Event box to decide.');
      case 'Solar Flare':
        return (
          youssef,
          'Solar flare! Radiation is rising. Tap the Current Event box.',
        );
      case 'Mars Solar Conjunction':
        return (
          nadia,
          'Earth contact is dark. We are on our own until Sol 12.',
        );
    }
    return (
      nadia,
      'Welcome to Mars, ${gameController.cadetName}. This is your base. Keep an eye on the resources, handle any events, and make the right decisions. Your crew is counting on you.',
    );
  }

  // لما اللاعب يضغط على رائد: الشخصية تقول جملة من شخصيتها
  void _talk(CrewMember member) {
    final line = member.lines[DateTime.now().millisecond % member.lines.length];
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: PixelPanel(
            borderColor: member.color,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CrewAvatar(member: member, size: 56),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.label,
                        style: TextStyle(
                          color: member.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '"${gameText(line)}"',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text(
                            'OK',
                            style: TextStyle(color: Colors.cyanAccent),
                          ),
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
    );
  }

  // رقم صغير فوق صورة المبنى لو في أكتر من واحد
  Widget _badge(Widget child, String? label) {
    if (label == null) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.cyan),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _miniChip(IconData icon, String label, int count, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.cyan.withValues(alpha: 0.7)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Colors.cyanAccent),
            const SizedBox(width: 4),
            Text(
              '$label x$count',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmAbort();
      },
      child: Scaffold(
        // الكيبورد مبيصغرش الشاشة ولا بيقص الخلفية
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xFF130B09),
        body: SafeArea(
          child: Stack(
            children: [
              // 1. الخلفية: baseline (أو العاصفة الرملية في أيامها). لو الصورة
              // الجديدة مش موجودة بيرجع للقديمة backgraund.
              Positioned.fill(
                child: RepaintBoundary(
                  child: ListenableBuilder(
                    listenable: gameController,
                    builder: (context, _) {
                      final g = gameController.game;
                      final String name;
                      if (g.sandstormBackdrop &&
                          AssetFinder.find(
                                const [kBase],
                                const ['sandstorm'],
                              ) !=
                              null) {
                        name = 'sandstorm';
                      } else if (AssetFinder.find(
                            const [kBase],
                            const ['baseline'],
                          ) !=
                          null) {
                        name = 'baseline';
                      } else {
                        name = 'backgraund';
                      }
                      return SmartImage.one(
                        kBase,
                        name,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        fallback: Container(color: const Color(0xFF130B09)),
                      );
                    },
                  ),
                ),
              ),

              // 2. المباني على الأرض: نفس شكل وحجم وترتيب الصورة المرجعية.
              // السبرايتات اتقصّت من الصورة كلها بنفس الارتفاع (274) فالنسب
              // بين المباني محفوظة، وبتتلزق جنب بعض زي الصورة بالظبط.
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, c) {
                    final h = c.maxHeight;
                    final base = h * 0.36;

                    return ListenableBuilder(
                      listenable: gameController,
                      builder: (context, _) {
                        final g = gameController.game;
                        final solar = g.buildings['Solar Panels']!;
                        final tanks = g.buildings['Water Recycler']!;
                        final greenhouses = g.buildings['Greenhouse']!;
                        final nuclear = g.buildings['Nuclear Unit']!;
                        final gens = g.buildings['Oxygen Generator']!;

                        // 0 ألواح | 1 وحدة نووية | 2 القبة + البطارية | 3 البرج
                        // 4 الصوبة | 5 خزان المياه | 6 مولد الأكسجين
                        const spriteH = 274.0;
                        const spriteW = [280.0, 121.0, 350.0, 109.0, 275.0, 145.0, 101.0];
                        const linkWidth = 14.0;
                        final visible = [
                          if (solar > 0) 0,
                          if (nuclear > 0) 1,
                          2,
                          3,
                          if (greenhouses > 0) 4,
                          if (tanks > 0) 5,
                          if (gens > 0) 6,
                        ];
                        var naturalRowWidth = 0.0;
                        for (var i = 0; i < visible.length; i++) {
                          naturalRowWidth += spriteW[visible[i]];
                          if (i > 0 && visible[i] - visible[i - 1] > 1) {
                            naturalRowWidth += linkWidth; // مبنى ناقص بينهم
                          }
                        }
                        final availableWidth = (c.maxWidth - 16).clamp(
                          1.0,
                          double.infinity,
                        );
                        final double sc = math.min(
                          1.0,
                          math.min(availableWidth / naturalRowWidth, base / spriteH),
                        );
                        final rowWidth = naturalRowWidth * sc;

                        Widget art(int i, String name) => SmartImage.one(
                          kBase,
                          name,
                          height: spriteH * sc,
                          width: spriteW[i] * sc,
                          fit: BoxFit.fill,
                        );

                        Widget tap(VoidCallback onTap, Widget child) =>
                            GestureDetector(onTap: onTap, child: child);

                        Widget itemFor(int i) {
                          switch (i) {
                            case 0:
                              return tap(
                                () => _open(const SolarFieldScreen()),
                                _badge(art(0, 'Ref-solar'), solar > 1 ? 'x$solar' : null),
                              );
                            case 1:
                              return tap(
                                () => _open(const NuclearScreen()),
                                _badge(art(1, 'Ref-nuclear'), nuclear > 1 ? 'x$nuclear' : null),
                              );
                            case 2:
                              // الجزء الشمال (فيه الكريستالة الزرقا) = البطارية،
                              // والباقي = القبة
                              return SizedBox(
                                width: spriteW[2] * sc,
                                height: spriteH * sc,
                                child: Stack(
                                  children: [
                                    art(2, 'Ref-habitat'),
                                    Positioned.fill(
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 80,
                                            child: GestureDetector(
                                              behavior: HitTestBehavior.opaque,
                                              onTap: () => _open(const BatteryScreen()),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 270,
                                            child: GestureDetector(
                                              behavior: HitTestBehavior.opaque,
                                              onTap: () => _open(const HabitatScreen()),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            case 3:
                              return tap(
                                () => _open(const MissionControlScreen()),
                                art(3, 'Ref-tower'),
                              );
                            case 4:
                              return tap(
                                () => _open(const GreenhouseScreen()),
                                Opacity(
                                  opacity: g.activeGreenhouses() > 0 ? 1 : 0.6,
                                  child: _badge(
                                    art(4, 'Ref-greenhouse'),
                                    greenhouses > 1 ? 'x$greenhouses' : null,
                                  ),
                                ),
                              );
                            case 5:
                              return tap(
                                () => _open(const WaterTankScreen()),
                                _badge(art(5, 'Ref-tank'), tanks > 1 ? 'x$tanks' : null),
                              );
                            default:
                              return tap(
                                () => _open(const OxygenGeneratorScreen()),
                                _badge(art(6, 'Ref-oxygen'), gens > 1 ? 'x$gens' : null),
                              );
                          }
                        }

                        // ظل المباني: ورا المباني، واتجاهه وطوله حسب زاوية الشمس
                        // النهاردة (optimalTilt من 25 لـ 85). الشمس يمين = الظل شمال.
                        final sunSide = ((g.optimalTilt - 55) / 30)
                            .clamp(-1.0, 1.0)
                            .toDouble();
                        final double shadowW =
                            (rowWidth * 1.1)
                                .clamp(200.0, c.maxWidth)
                                .toDouble() *
                            (1 + 0.25 * sunSide.abs());
                        final shadowH = shadowW / 3; // نسبة الصورة 3:1
                        final shadowShift = -sunSide * 18 * sc;
                        final shadowOpacity = g.dustVisible ? 0.25 : 0.65;

                        final rowChildren = <Widget>[];
                        for (var i = 0; i < visible.length; i++) {
                          if (i > 0 && visible[i] - visible[i - 1] > 1) {
                            rowChildren.add(
                              Padding(
                                padding: EdgeInsets.only(bottom: 38 * sc),
                                child: _OutpostLink(scale: sc),
                              ),
                            );
                          }
                          rowChildren.add(itemFor(visible[i]));
                        }

                        return Stack(
                          children: [
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: base - shadowH * 0.5 - 3 * sc,
                              child: IgnorePointer(
                                child: Center(
                                  child: Transform.translate(
                                    offset: Offset(shadowShift, 0),
                                    child: Opacity(
                                      opacity: shadowOpacity,
                                      child: SmartImage.one(
                                        kBase,
                                        'shadow',
                                        width: shadowW,
                                        fit: BoxFit.fill,
                                        fallback: const SizedBox.shrink(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // صف المباني
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: base,
                              child: Center(
                                child: RepaintBoundary(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: rowChildren,
                                  ),
                                ),
                              ),
                            ),
                            // COMMS (يمين فوق)
                            Positioned(
                              top: 54,
                              right: 8,
                              child: PixelButton(
                                label: g.conjunction
                                    ? 'COMMS OFFLINE'
                                    : 'COMMS',
                                color: g.conjunction
                                    ? Colors.redAccent
                                    : Colors.purpleAccent,
                                height: 26,
                                onTap: () =>
                                    _open(const MissionControlScreen()),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),

              // 3. الطاقم والروفر بيتحركوا (اضغطي على رائد يتكلم)
              Positioned(
                bottom: 104,
                left: 100,
                right: 100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _Wander(
                      distance: 50,
                      seconds: 5,
                      child: GestureDetector(
                        onTap: () => _talk(nadia),
                        child: const GameImage(
                          'assets/images/BaseViewScreen/Astronaut-01.png',
                          height: 28,
                        ),
                      ),
                    ),
                    const _Wander(
                      distance: 110,
                      seconds: 8,
                      child: GameImage(
                        'assets/images/BaseViewScreen/Rover.png',
                        height: 22,
                      ),
                    ),
                    _Wander(
                      distance: 36,
                      seconds: 6,
                      child: GestureDetector(
                        onTap: () => _talk(karim),
                        child: const GameImage(
                          'assets/images/BaseViewScreen/Astronaut-02.png',
                          height: 28,
                        ),
                      ),
                    ),
                    _Wander(
                      distance: 44,
                      seconds: 9,
                      child: GestureDetector(
                        onTap: () => _talk(youssef),
                        child: const GameImage(
                          'assets/images/BaseViewScreen/Astronaut-01.png',
                          height: 28,
                        ),
                      ),
                    ),
                    _Wander(
                      distance: 60,
                      seconds: 7,
                      child: GestureDetector(
                        onTap: () => _talk(amara),
                        child: const GameImage(
                          'assets/images/BaseViewScreen/Astronaut-03.png',
                          height: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // تراب متحرك فوق القاعدة أثناء العاصفة (dust1.png)
              Positioned.fill(
                child: ListenableBuilder(
                  listenable: gameController,
                  builder: (context, _) => gameController.game.dustVisible
                      ? const DustOverlay()
                      : const SizedBox.shrink(),
                ),
              ),

              // العشبة: دوسي عليها تزود الأكل (مرة كل Sol)
              Positioned(
                left: 14,
                bottom: 106,
                child: ListenableBuilder(
                  listenable: gameController,
                  builder: (context, _) {
                    final ready = gameController.game.grassReady;
                    final label =
                        _grassMsg ??
                        (ready ? 'TAP +${grassFoodBonus.round()} FOOD' : '');
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _tapGrass,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Opacity(
                              opacity: ready ? 1 : 0.4,
                              child: SmartImage.one(
                                kBase,
                                'Grass-Food',
                                height: 44,
                                fallback: const Icon(
                                  Icons.eco,
                                  color: Colors.greenAccent,
                                  size: 36,
                                ),
                              ),
                            ),
                            if (label.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  gameText(label),
                                  style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 4. شريط الموارد العلوي (حي)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: TopHudBar(
                  onNotificationsTap: () {},
                  onTodoListTap: () {},
                ),
              ),

              // 5. Current Event (يسار فوق)
              Positioned(
                top: 54,
                left: 8,
                child: CurrentEventBox(onTap: _showEventIfAny),
              ),

              // 6. صندوق الحوار + الأزرار
              Positioned(
                bottom: 6,
                left: 8,
                right: 8,
                height: 92,
                child: ListenableBuilder(
                  listenable: gameController,
                  builder: (context, _) {
                    final g = gameController.game;
                    final speaker = _speak(g);

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: DialogueBox(
                            speaker: speaker.$1,
                            mood: commanderMood(g),
                            text: speaker.$2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 130,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              PixelButton(
                                label: 'BUILD  /  ACTIONS',
                                height: 34,
                                onTap: () => showDialog(
                                  context: context,
                                  builder: (_) => const BuildDialog(),
                                ),
                              ),
                              const SizedBox(height: 8),
                              PixelButton(
                                label: 'END SOL',
                                color: Colors.amber,
                                height: 34,
                                onTap: g.decisionPhase ? _endSol : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Connects the core modules only after the complete outpost is available.
List<Widget> _withLinks(List<Widget> items, double sc) {
  final out = <Widget>[];
  for (var i = 0; i < items.length; i++) {
    out.add(items[i]);
    if (i < items.length - 1) {
      out.add(_OutpostLink(scale: sc));
    }
  }
  return out;
}

class _OutpostLink extends StatelessWidget {
  const _OutpostLink({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 18 * scale,
    height: 22 * scale,
    child: Center(
      child: Container(
        height: 8 * scale,
        decoration: BoxDecoration(
          color: const Color(0xFF58616A),
          border: Border.all(color: const Color(0xFF252D36), width: 2 * scale),
        ),
        child: Center(
          child: Container(height: 2 * scale, color: const Color(0xFFE5A34B)),
        ),
      ),
    ),
  );
}

/// بيحرك العنصر يمين وشمال بشكل ناعم (للرواد والروفر)
class _Wander extends StatefulWidget {
  final Widget child;
  final double distance;
  final int seconds;

  const _Wander({
    required this.child,
    required this.distance,
    required this.seconds,
  });

  @override
  State<_Wander> createState() => _WanderState();
}

class _WanderState extends State<_Wander> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(seconds: widget.seconds),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // RepaintBoundary: الحركة بترسم نفسها بس، مش الشاشة كلها كل فريم
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = Curves.easeInOut.transform(_controller.value);
          return Transform.translate(
            offset: Offset((t - 0.5) * widget.distance, 0),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}
