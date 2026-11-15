import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../audio/audio_service.dart';
import '../localization/game_localization.dart';
import 'game_engine.dart';

/// الوسيط بين محرك اللعبة (Game) والشاشات.
/// أي شاشة تسمع له بـ ListenableBuilder وتتحدث لوحدها لما الأرقام تتغير.
class GameController extends ChangeNotifier {
  static const String _saveKey = 'astrocadet_save_v1';

  Game game = Game();
  String cadetName = 'Cadet';
  String? lastAdvice; // آخر نصيحة من Mission Control
  bool tutorialShown = false; // شرح اللعبة بيظهر أول مرة بس في كل تشغيل

  /// رقم الـ Sol اللي تقرير الصبح بتاعه اتعرض خلاص (عشان مايتعرضش تاني
  /// لما اللاعب يرجع من شاشة داخلية أو يكمل لعبة محفوظة)
  int? morningShownSol;

  // الحفظ
  SharedPreferences? _prefs;
  bool hasSave = false; // في لعبة محفوظة يقدر يكملها؟
  bool _saveEnabled = false; // مبنحفظش إلا بعد ما اللاعب يدخل القاعدة
  Timer? _saveTimer;

  GameController() {
    game.beginSol();
    gameArabic.addListener(_onLocaleChanged);
  }

  void _onLocaleChanged() {
    super.notifyListeners();
  }

  /// بيتنادى مرة واحدة في main() قبل ما اللعبة تفتح
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      hasSave = _readSave() != null;
    } catch (e) {
      debugPrint('[save] init failed: $e');
    }
  }

  Map<String, dynamic>? _readSave() {
    final raw = _prefs?.getString(_saveKey);
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw);
      if (data is! Map<String, dynamic>) return null;
      final g = data['game'];
      if (g is! Map<String, dynamic>) return null;
      // نتأكد إن اللعبة تتقرا من غير أخطاء ومش خلصت
      final test = Game.fromJson(g);
      if (test.isOver) return null;
      return data;
    } catch (e) {
      debugPrint('[save] corrupt save ignored: $e');
      return null;
    }
  }

  /// بيحمّل اللعبة المحفوظة. بيرجّع false لو مفيش أو بايظة.
  bool continueGame() {
    final data = _readSave();
    if (data == null) {
      hasSave = false;
      return false;
    }
    final loaded = Game.fromJson(data['game'] as Map<String, dynamic>);
    game = loaded;
    cadetName = (data['name'] as String?) ?? 'Cadet';
    lastAdvice = data['advice'] as String?;
    tutorialShown = true;
    if (game.decisionPhase) {
      // وقف في نص اليوم: نكمل من غير تقرير الصبح
      morningShownSol = game.sol;
    } else {
      // وقف بين يومين: نبدأ اليوم الجديد بتقريره
      morningShownSol = null;
      game.beginSol();
    }
    _saveEnabled = true;
    notifyListeners();
    return true;
  }

  void markStarted() {
    if (_saveEnabled) return;
    _saveEnabled = true;
    _scheduleSave();
  }

  void _scheduleSave() {
    if (!_saveEnabled || _prefs == null) return;
    if (game.isOver) {
      clearSave();
      return;
    }
    // لو الـ Slider بيتحرك مبنكتبش على الدسك كل لحظة
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 600), saveNow);
  }

  /// حفظ فوري (بيتنادى لما اللاعب يخرج من اللعبة)
  Future<void> saveNow() async {
    _saveTimer?.cancel();
    final prefs = _prefs;
    if (!_saveEnabled || prefs == null || game.isOver) return;
    try {
      final ok = await prefs.setString(
        _saveKey,
        jsonEncode({
          'game': game.toJson(),
          'name': cadetName,
          'advice': lastAdvice,
        }),
      );
      if (ok) hasSave = true;
    } catch (e) {
      debugPrint('[save] failed: $e');
    }
  }

  Future<void> clearSave() async {
    _saveTimer?.cancel();
    hasSave = false;
    try {
      await _prefs?.remove(_saveKey);
    } catch (e) {
      debugPrint('[save] clear failed: $e');
    }
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
    _scheduleSave();
  }

  /// لعبة جديدة من الأول (Sol 1). بتمسح أي لعبة محفوظة.
  void newGame() {
    _saveEnabled = false;
    clearSave();
    game = Game();
    lastAdvice = null;
    morningShownSol = null;
    tutorialShown = false;
    game.beginSol();
    notifyListeners();
  }

  void setCadetName(String name) {
    cadetName = name;
    notifyListeners();
  }

  bool build(String name) {
    final apBefore = game.actionPoints;
    final ok = game.build(name);
    notifyListeners();
    if (!ok) {
      audio.sfx('ui_denied', volume: 0.6);
      return false;
    }
    if (game.actionPoints < apBefore) audio.sfx('ap_spend');
    audio.sfx('build_start');
    audio.sfxLater('build_done', 800);
    return true;
  }

  bool upgradeHabitat() {
    final apBefore = game.actionPoints;
    final ok = game.upgradeHabitat();
    notifyListeners();
    if (!ok) {
      audio.sfx('ui_denied', volume: 0.6);
      return false;
    }
    if (game.actionPoints < apBefore) audio.sfx('ap_spend');
    audio.sfx('habitat_upgrade');
    return true;
  }

  /// هدم مبنى واحد (1 AP)
  bool demolish(String name) {
    final apBefore = game.actionPoints;
    final ok = game.demolish(name);
    notifyListeners();
    if (!ok) {
      audio.sfx('ui_denied', volume: 0.6);
      return false;
    }
    if (game.actionPoints < apBefore) audio.sfx('ap_spend');
    audio.sfx('ui_undo');
    return true;
  }

  /// ميل الألواح (بيتحفظ في اللعبة ومبيرجعش 60% لما تخرج وتدخل)
  void setTilt(double v) {
    game.setTilt(v);
    notifyListeners();
  }

  bool maintain(String name) {
    final ok = game.maintain(name);
    notifyListeners();
    final successSfx = name == 'Water Recycler' ? 'repair' : 'maintain';
    audio.sfx(ok ? successSfx : 'ui_denied', volume: ok ? 0.7 : 0.6);
    return ok;
  }

  void toggleBreaker() {
    game.solarBreaker = !game.solarBreaker;
    notifyListeners();
    audio.sfx('stow_panels', volume: 0.6);
  }

  bool respond() {
    final event = game.event;
    final apBefore = game.actionPoints;
    final ok = game.respondToEvent();
    notifyListeners();
    if (!ok) {
      audio.sfx('ui_denied', volume: 0.6);
      return false;
    }
    if (game.actionPoints < apBefore) audio.sfx('ap_spend');
    // صوت التصرف حسب نوع الحدث، وبعده صوت "تم التخفيف"
    switch (event) {
      case 'Dust Storm':
      case 'Solar Flare':
        audio.sfx('stow_panels');
        break;
      case 'Equipment Malfunction':
      case 'Life Support Leak':
        audio.sfx('repair');
        break;
      default:
        audio.sfx('maintain');
    }
    audio.sfxLater('event_mitigated', 450);
    return true;
  }

  /// بيجمّع شحنة البطارية لعداد الطاقة. بيرجّع الكمية اللي اتجمعت.
  double collectEnergy() {
    final amount = game.collectEnergy();
    notifyListeners();
    audio.sfx(
      amount > 0 ? 'mine' : 'ui_denied',
      volume: amount > 0 ? 0.7 : 0.6,
    );
    return amount;
  }

  /// العشبة في القاعدة: بتزود الأكل. بيرجّع الكمية اللي اتزادت.
  double gatherGrass() {
    final amount = game.gatherGrass();
    notifyListeners();
    audio.sfx(
      amount > 0 ? 'materials_gain' : 'ui_denied',
      volume: amount > 0 ? 0.7 : 0.6,
    );
    return amount;
  }

  /// بيحصد صوبة واحدة (رقمها من 0)
  double harvest(int index) {
    final amount = game.harvest(index);
    notifyListeners();
    audio.sfx(
      amount > 0 ? 'materials_gain' : 'ui_denied',
      volume: amount > 0 ? 0.7 : 0.6,
    );
    return amount;
  }

  double harvestAll() {
    final amount = game.harvestAll();
    notifyListeners();
    audio.sfx(
      amount > 0 ? 'materials_gain' : 'ui_denied',
      volume: amount > 0 ? 0.7 : 0.6,
    );
    return amount;
  }

  /// هل اللاعب يقدر يتصرف مع الحدث الحالي؟
  bool get canRespond => game.canRespondNow;

  /// يسأل Mission Control (1 AP). بيرجّع النصيحة، أو null لو مينفعش.
  String? askAdvice() {
    final apBefore = game.actionPoints;
    final ok = game.callForHelp();
    notifyListeners();
    if (!ok) {
      audio.sfx('ui_denied', volume: 0.6);
      return null;
    }
    if (game.actionPoints < apBefore) audio.sfx('ap_spend');
    audio.sfx('ui_notification');
    lastAdvice = _advice();
    notifyListeners();
    return lastAdvice;
  }

  String _advice() {
    final g = game;
    final crew = g.crewCount;
    final gens = g.buildings['Oxygen Generator']!;
    final recs = g.buildings['Water Recycler']!;
    final houses = g.buildings['Greenhouse']!;
    final nuclear = g.buildings['Nuclear Unit']!;

    final o2Make =
        gens * buildingOutput['Oxygen Generator']! +
        g.activeGreenhouses() * plantOxygen * g.plantFactor;
    final o2Need = crew * oxygenPerPerson;
    final waterNeed = crew * waterPerPerson;
    final foodNeed = crew * foodPerPerson;
    final power = g.expectedProduction();
    final demand = g.autoDemand();

    if (g.radiation >= 50 || (g.habitatLevel < 2 && g.sol >= 4)) {
      return 'Radiation builds fast on Mars. Upgrade the habitat shielding now, before it reaches 100.';
    }
    if (g.energy < demand && g.battery >= 10) {
      return 'Your energy counter is lower than what the base needs. Open the Battery module and tap it to collect energy.';
    }
    if (o2Make < o2Need) {
      return 'Oxygen is the most urgent problem: you make ${o2Make.round()} per Sol but the crew breathes ${o2Need.round()}. Build another Oxygen Generator.';
    }
    if (recs == 0) {
      return 'There is no Water Recycler. Build one: it runs a water cycle by itself at the end of every Sol, using energy.';
    }
    if (g.water < waterNeed * 2) {
      return 'Water is low. The recycler runs on its own at the end of each Sol, so keep some energy in the counter (collect it from the battery) and add another recycler.';
    }
    if (power < demand) {
      return 'Energy is short: the panels make ${power.round()} per Sol but the base needs ${demand.round()}. Match the TILT to the sun angle, or add Solar Panels or a Nuclear Unit.';
    }
    if (g.storedCrops >= cropMinHarvest) {
      return 'There are crops waiting in the greenhouse. Harvest them to raise your food.';
    }
    if (houses == 0) {
      return 'There is no food production. Plant a Greenhouse now (it costs ${plantWaterCost.round()} water); new beds are ripe in $greenhouseGrowTime Sols.';
    }
    if (g.activeGreenhouses() > 0 && !g.irrigated) {
      return 'Maintain the greenhouse (${greenhouseMaintainWater.round()} water) to ripen its beds, then harvest +${greenhouseHarvestYield.round()} food from each one.';
    }
    if (houses * bedYield < foodNeed) {
      return 'Food will run short: your beds make ${(houses * bedYield).round()} per Sol but the crew eats ${foodNeed.round()}. Plant another bed.';
    }
    if (g.sol < stormSol && nuclear == 0) {
      return 'A big dust storm is coming around Sol $stormSol, and the Sol 10 to 12 blackout too. Build a Nuclear Unit and bank energy in the battery before then.';
    }
    return 'Everything looks stable. Collect energy, water and harvest the greenhouse, then end the Sol.';
  }

  /// يخلص اليوم الحالي ويحسب النتيجة
  void endSol() {
    audio.sfx('sol_end');
    game.finishSol();
    notifyListeners();
  }

  /// يبدأ Sol جديد (بعد ما اللاعب يقفل شاشة Feedback)
  void startNextSol() {
    if (!game.isOver) game.beginSol();
    notifyListeners();
  }
}

/// نسخة واحدة مشتركة بين كل الشاشات
final GameController gameController = GameController();
