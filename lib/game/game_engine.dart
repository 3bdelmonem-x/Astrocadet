import 'dart:math';

// محرك اللعبة (Simulation) - مبني على ملف astrocadet.dart بتاع التيم.
// كل الأرقام هنا "Game Values" مش قياسات حقيقية لرواد الفضاء.
// عدّلي أي رقم من هنا وهيتغير في اللعبة كلها.

const int missionLength = 20;

// ---- نقاط الأكشن (AP): 3 كل Sol، ومفيش تراكم (الحد الأقصى 3 بس) ----
const int dailyActionPoints = 3;
const int actionPointCap = 3;
const int buildActionCost = 2;
const int demolishActionCost = 1;
const int responseActionCost = 1;

const int greenhouseGrowTime = 2; // عدد الـ Sols لحد ما الزرع الجديد يطلع
const double oxygenPerPerson = 8;
const double waterPerPerson = 5;
const double foodPerPerson = 4;
const double resourceLimit = 100;
const double healthLoss = 10;
const List<double> habitatMultipliers = [1, 0.6, 0.3];

// الإشعاع: من غير الدرع (Shield) بيوصل 100 في حوالي Sol 17 واللاعب بيخسر.
const double radiationPerSol = 6;

// ---- اقتصاد الطاقة والمية والزرع ----
const double startEnergy = 40; // عداد الطاقة في أول اللعبة
const double energyLimit = 100; // أقصى عداد طاقة
const double batteryCapacity = 150; // سعة البطارية (ثابتة، مش مبنى)
const double plantWaterCost = 20; // زرع صوبة جديدة = مية
const double greenhouseMaintainWater =
    10; // ري/صيانة كل الأحواض مرة واحدة = مية
const double greenhouseHarvestYield = 15; // محصول جاهز لكل حوض بعد الصيانة
const double cropTreatWater = 10; // علاج تلوث المحصول = مية
const double plantOxygen = 6; // أكسجين من كل صوبة ناضجة (× صحة النباتات)
const double bedYield = 10; // محصول كل حوض ناضج في كل Sol اتروى فيه
const double cropStorageMax = 30; // أقصى محصول متخزن في الحوض الواحد
const double cropMinHarvest = 5; // أقل كمية تظهر كجاهزة للحصاد
const double habitatBaseLoad = 10; // طاقة القبة الأساسية كل Sol

// دورة المياه أوتوماتيك: في آخر كل Sol الـ Recycler بيشتغل لوحده لو في طاقة
const double waterCycleEnergy = 5; // طاقة لكل وحدة تدوير في كل دورة
const double waterCycleOutput = 15; // مية لكل وحدة تدوير في كل دورة
const double filterWearPerCycle = 4; // الفلتر بيقل كام % كل دورة
const double recyclerMaintainEnergy = 8; // صيانة الفلاتر = طاقة
const double strainRepairEnergy = 8; // إصلاح ضغط نظام المياه = طاقة

// ---- أحداث مجدولة (بتحصل في أيام معينة عشان اللعبة متفضلش ثابتة) ----
const bool scheduledEventsEnabled = true;
const int stormSol = 14; // عاصفة ترابية كبيرة
const int stormLength = 4;
const int flareSol = 18; // انفجار شمسي

// ---- العشبة (الصورة اللي في القاعدة): اللاعب بيدوس عليها تزود الأكل ----
const double grassFoodBonus = 5; // كام أكل في كل ضغطة
const int grassTapsPerSol = 1; // كام ضغطة مسموحة في الـ Sol الواحد

// ---- أيام خلفية العاصفة الرملية في القاعدة (غيّري الأرقام دي براحتك) ----
const List<int> sandstormSols = [12, 13];

const Map<String, double> buildingOutput = {
  'Solar Panels': 15,
  'Nuclear Unit': 12,
  'Oxygen Generator': 20,
  'Water Recycler': waterCycleOutput,
  'Greenhouse': bedYield,
};

// أقصى عدد لكل مبنى (مبقاش في تشييد لا نهائي)
const Map<String, int> buildingMax = {
  'Solar Panels': 6,
  'Nuclear Unit': 3,
  'Oxygen Generator': 4,
  'Water Recycler': 4,
  'Greenhouse': 6,
};

// الطاقة اللي بتتخصم أوتوماتيك في آخر كل Sol
const Map<String, double> operatingEnergy = {'Oxygen Generator': 6};

const List<String> eventNames = [
  'None',
  'Dust Storm',
  'Solar Flare',
  'Mars Solar Conjunction',
  'Life Support Leak',
  'Equipment Malfunction',
  'Crop Contamination',
  'Water System Strain',
];

double limit(double amount, double maximum) {
  return amount.clamp(0, maximum).toDouble();
}

/// تكلفة التصرف مع الحدث (مش دايماً Action Point)
String eventCostLabel(String event) {
  if (event == 'Water System Strain') {
    return '${strainRepairEnergy.round()} energy';
  }
  if (event == 'Crop Contamination') return '${cropTreatWater.round()} water';
  return '1 AP';
}

class Game {
  final int crewCount;
  final Random random;

  // seed فاضي = أحداث عشوائية مختلفة في كل لعبة
  Game({this.crewCount = 4, int? seed}) : random = Random(seed) {
    if (crewCount < 1) throw ArgumentError('Crew count must be positive.');
  }

  int sol = 1;
  int actionPoints = 0;
  int habitatLevel = 1;
  double oxygen = 100, water = 100, food = 100;
  double radiation = 0, health = 100;

  // الطاقة: الألواح بتشحن البطارية، واللاعب بيجمّع من البطارية لعداد الطاقة،
  // والتشغيل التلقائي (القبة، مولد الأكسجين) بيتخصم من العداد.
  double energy = startEnergy; // عداد الطاقة (اللي بيظهر في الـ HUD)
  double battery = 0; // الشحنة المخزنة في البطارية

  // ميل الألواح (بيتحفظ هنا عشان ميرجعش 60% لما اللاعب يخرج ويدخل)
  double solarTilt = 60;
  double optimalTilt = 60; // زاوية الشمس النهاردة

  double plantHealth = 100; // صحة النباتات 0-100
  final List<double> crops = []; // محصول متخزن في كل حوض
  bool irrigated = false; // الأحواض اتروت النهاردة؟ (بيتصفر كل Sol)

  double filterHealth = 100; // حالة فلتر معالج المياه 0-100
  int waterCycles = 0; // عدد الدورات في الـ Sol الحالي

  int grassTaps = 0; // عدد مرات الضغط على العشبة النهاردة (بيتصفر كل Sol)

  String status = 'OK';
  String failureReason = '';
  bool decisionPhase = false;
  String event = 'None';
  int eventDaysLeft = 0; // -1 = لحد ما اللاعب يتصرف
  bool mitigated = false;
  bool postStorm = false;
  bool solarBreaker = true; // مفتاح الألواح: لو OFF الألواح مبتنتجش
  int cropAge = 0;
  double energyProduced = 0, energyDemand = 0, energyUsed = 0;
  int oxygenRunning = 0;

  // للواجهة: آخر حدث انتهى + التغيير في كل مورد في آخر Sol
  String lastEvent = 'None';
  Map<String, double> delta = {
    'oxygen': 0,
    'energy': 0,
    'battery': 0,
    'water': 0,
    'food': 0,
    'radiation': 0,
    'health': 0,
  };

  final Map<String, int> buildings = {
    'Solar Panels': 2,
    'Nuclear Unit': 0,
    'Oxygen Generator': 1,
    'Water Recycler': 1,
    'Greenhouse': 0,
  };
  final List<int> greenhouseBuildSols = [];
  final List<String> history = [];

  // ------------------------------------------------------------------
  // حفظ واسترجاع اللعبة (عشان اللاعب يكمل مكان ما وقف)
  // ------------------------------------------------------------------
  Map<String, dynamic> toJson() => {
    'v': 1,
    'crewCount': crewCount,
    'sol': sol,
    'actionPoints': actionPoints,
    'habitatLevel': habitatLevel,
    'oxygen': oxygen,
    'water': water,
    'food': food,
    'radiation': radiation,
    'health': health,
    'energy': energy,
    'battery': battery,
    'solarTilt': solarTilt,
    'optimalTilt': optimalTilt,
    'plantHealth': plantHealth,
    'crops': crops,
    'irrigated': irrigated,
    'filterHealth': filterHealth,
    'waterCycles': waterCycles,
    'grassTaps': grassTaps,
    'status': status,
    'failureReason': failureReason,
    'decisionPhase': decisionPhase,
    'event': event,
    'eventDaysLeft': eventDaysLeft,
    'mitigated': mitigated,
    'postStorm': postStorm,
    'solarBreaker': solarBreaker,
    'cropAge': cropAge,
    'energyProduced': energyProduced,
    'energyDemand': energyDemand,
    'energyUsed': energyUsed,
    'oxygenRunning': oxygenRunning,
    'lastEvent': lastEvent,
    'delta': delta,
    'buildings': buildings,
    'greenhouseBuildSols': greenhouseBuildSols,
    'history': history,
  };

  static double _d(Object? v, double fallback) =>
      v is num ? v.toDouble() : fallback;
  static int _i(Object? v, int fallback) => v is num ? v.round() : fallback;

  /// بيرجّع لعبة من البيانات المحفوظة (بيرمي استثناء لو البيانات بايظة)
  factory Game.fromJson(Map<String, dynamic> j) {
    final g = Game(crewCount: _i(j['crewCount'], 4));
    g.sol = _i(j['sol'], 1);
    g.actionPoints = _i(j['actionPoints'], 0);
    g.habitatLevel = _i(j['habitatLevel'], 1).clamp(1, 3);
    g.oxygen = _d(j['oxygen'], 100);
    g.water = _d(j['water'], 100);
    g.food = _d(j['food'], 100);
    g.radiation = _d(j['radiation'], 0);
    g.health = _d(j['health'], 100);
    g.energy = _d(j['energy'], startEnergy);
    g.battery = _d(j['battery'], 0);
    g.solarTilt = _d(j['solarTilt'], 60);
    g.optimalTilt = _d(j['optimalTilt'], 60);
    g.plantHealth = _d(j['plantHealth'], 100);
    g.crops
      ..clear()
      ..addAll((j['crops'] as List? ?? []).map((e) => _d(e, 0)));
    g.irrigated = j['irrigated'] == true;
    g.filterHealth = _d(j['filterHealth'], 100);
    g.waterCycles = _i(j['waterCycles'], 0);
    g.grassTaps = _i(j['grassTaps'], 0);
    g.status = (j['status'] as String?) ?? 'OK';
    g.failureReason = (j['failureReason'] as String?) ?? '';
    g.decisionPhase = j['decisionPhase'] == true;
    g.event = (j['event'] as String?) ?? 'None';
    if (!eventNames.contains(g.event)) g.event = 'None';
    g.eventDaysLeft = _i(j['eventDaysLeft'], 0);
    g.mitigated = j['mitigated'] == true;
    g.postStorm = j['postStorm'] == true;
    g.solarBreaker = j['solarBreaker'] != false;
    g.cropAge = _i(j['cropAge'], 0);
    g.energyProduced = _d(j['energyProduced'], 0);
    g.energyDemand = _d(j['energyDemand'], 0);
    g.energyUsed = _d(j['energyUsed'], 0);
    g.oxygenRunning = _i(j['oxygenRunning'], 0);
    g.lastEvent = (j['lastEvent'] as String?) ?? 'None';
    final delta = j['delta'];
    if (delta is Map) {
      for (final k in g.delta.keys.toList()) {
        g.delta[k] = _d(delta[k], 0);
      }
    }
    final b = j['buildings'];
    if (b is Map) {
      for (final k in g.buildings.keys.toList()) {
        g.buildings[k] = _i(b[k], g.buildings[k]!);
      }
    }
    g.greenhouseBuildSols
      ..clear()
      ..addAll((j['greenhouseBuildSols'] as List? ?? []).map((e) => _i(e, 1)));
    // لازم عدد الأحواض يساوي عدد الصوبات
    while (g.crops.length < g.greenhouseBuildSols.length) {
      g.crops.add(0);
    }
    if (g.crops.length > g.greenhouseBuildSols.length) {
      g.crops.removeRange(g.greenhouseBuildSols.length, g.crops.length);
    }
    g.history
      ..clear()
      ..addAll((j['history'] as List? ?? []).map((e) => e.toString()));
    return g;
  }

  bool get conjunction => sol >= 10 && sol <= 12;

  /// خلفية العاصفة الرملية بتظهر في الأيام دي
  bool get sandstormBackdrop => sandstormSols.contains(sol);

  /// تراب متحرك فوق القاعدة: أثناء عاصفة الغبار أو أيام العاصفة الرملية
  bool get dustVisible => event == 'Dust Storm' || sandstormBackdrop;

  /// العشبة جاهزة للضغط؟
  bool get grassReady => _canAct && grassTaps < grassTapsPerSol;

  /// بيزود الأكل من العشبة. بيرجّع الكمية (0 لو مينفعش أو الأكل مليان).
  double gatherGrass() {
    if (!grassReady) return 0;
    final take = min(grassFoodBonus, resourceLimit - food);
    if (take <= 0) return 0;
    food = limit(food + take, resourceLimit);
    grassTaps++;
    history.add('Sol $sol: Gather grass (+${take.round()} food)');
    return take;
  }

  bool get isOver => status != 'OK';
  double get batteryMax => batteryCapacity;
  double get storedCrops => crops.fold(0.0, (a, b) => a + b);
  double get plantFactor => plantHealth / 100;

  String get rank {
    if (status == 'MISSION WIN') return 'Commander';
    if (sol > 10) return 'Pilot';
    return 'Cadet';
  }

  bool atMax(String name) =>
      (buildings[name] ?? 0) >= (buildingMax[name] ?? 99);

  int activeGreenhouses() {
    int count = 0;
    for (int builtSol in greenhouseBuildSols) {
      if (sol - builtSol >= greenhouseGrowTime) count++;
    }
    return count;
  }

  // ------------------------------------------------------------------
  // الطاقة: ميل الألواح بيأثر على الإنتاج فعلاً
  // ------------------------------------------------------------------

  /// كفاءة الألواح حسب قرب الميل من زاوية الشمس (من 0.5 لـ 1.15)
  double get tiltEfficiency {
    final diff = (solarTilt - optimalTilt).abs();
    return (1.15 - diff / 100 * 1.1).clamp(0.5, 1.15).toDouble();
  }

  void setTilt(double v) {
    solarTilt = v.clamp(0, 100).toDouble();
  }

  /// الإنتاج المتوقع في آخر الـ Sol بعد الأحداث والميل والمفتاح
  double expectedProduction() {
    final fx = eventEffects();
    return (buildings['Solar Panels']! *
                buildingOutput['Solar Panels']! *
                fx[0] *
                tiltEfficiency *
                (solarBreaker ? 1 : 0) +
            buildings['Nuclear Unit']! * buildingOutput['Nuclear Unit']!) *
        fx[1];
  }

  /// الطاقة اللي بتتخصم أوتوماتيك كل Sol (القبة + مولدات الأكسجين)
  double autoDemand() {
    return habitatBaseLoad +
        buildings['Oxygen Generator']! * operatingEnergy['Oxygen Generator']!;
  }

  // ------------------------------------------------------------------
  // الأحداث
  // ------------------------------------------------------------------

  /// أحداث بتحصل في أيام ثابتة
  String? scheduledEvent() {
    if (!scheduledEventsEnabled) return null;
    if (sol == stormSol) return 'Dust Storm';
    if (sol == flareSol) return 'Solar Flare';
    return null;
  }

  String rollEvent() {
    if (conjunction) return 'Mars Solar Conjunction';
    if (buildings['Water Recycler']! > 0 && filterHealth < 25) {
      return 'Water System Strain';
    }
    int roll = random.nextInt(100);
    int cutoff = 0;
    final Map<String, int> chances = {
      'Dust Storm': sol > 5 ? 8 : 0,
      'Solar Flare': 5,
      'Life Support Leak': sol > 3 ? 6 : 0,
      'Equipment Malfunction': postStorm ? 10 : 5,
      'Crop Contamination': activeGreenhouses() > 0 && cropAge >= 3 ? 10 : 0,
    };
    for (String name in chances.keys) {
      cutoff += chances[name]!;
      if (roll < cutoff) return name;
    }
    return 'None';
  }

  void beginSol({String? forcedEvent, int? forcedDuration}) {
    if (decisionPhase || status != 'OK') {
      throw StateError('Finish the current Sol, or start a new game.');
    }
    checkResult(false);
    if (status != 'OK') return;
    if (forcedEvent != null && !eventNames.contains(forcedEvent)) {
      throw ArgumentError('Unknown event: $forcedEvent');
    }
    if (forcedDuration != null && forcedDuration < 1) {
      throw ArgumentError('Event duration must be positive.');
    }
    // الـ AP: 3 جداد كل Sol (الحد الأقصى 3)
    actionPoints = min(actionPoints + dailyActionPoints, actionPointCap);
    mitigated = false;
    irrigated = false;
    waterCycles = 0;
    grassTaps = 0;
    // زاوية الشمس بتتغير كل يوم (أول يوم 60 زي الوضع الافتراضي)
    optimalTilt = sol == 1 ? 60.0 : (25 + random.nextInt(61)).toDouble();
    if (forcedEvent != null || event == 'None') {
      event = forcedEvent ?? scheduledEvent() ?? rollEvent();
      eventDaysLeft = 1;
      if (event == 'Dust Storm') {
        eventDaysLeft = (forcedEvent == null && sol == stormSol)
            ? stormLength
            : random.nextInt(3) + 2;
      }
      if (eventNames.indexOf(event) >= 4) eventDaysLeft = -1;
      if (forcedEvent != null) eventDaysLeft = forcedDuration ?? 1;
    }
    decisionPhase = true;
    history.add('Sol $sol: $event; blackout=$conjunction');
  }

  bool spendActionPoints(int cost, String description) {
    if (cost < 1) return false;
    if (!decisionPhase || status != 'OK' || actionPoints < cost) return false;
    actionPoints -= cost;
    history.add('Sol $sol: $description ($cost AP)');
    return true;
  }

  bool get _canAct => decisionPhase && status == 'OK';

  bool build(String name) {
    if (!buildings.containsKey(name)) return false;
    if (atMax(name)) return false;
    if (name == 'Greenhouse') {
      // الزرع بيخصم مية من الخزان بدل Action Points
      if (!_canAct || water < plantWaterCost) return false;
      water -= plantWaterCost;
      buildings[name] = buildings[name]! + 1;
      greenhouseBuildSols.add(sol);
      crops.add(0);
      history.add(
        'Sol $sol: Plant Greenhouse (-${plantWaterCost.round()} water)',
      );
      return true;
    }
    if (!spendActionPoints(buildActionCost, 'Build $name')) return false;
    buildings[name] = buildings[name]! + 1;
    return true;
  }

  /// هدم مبنى واحد (1 AP). المحصول المتخزن في الحوض بيضيع.
  bool demolish(String name) {
    if (!buildings.containsKey(name)) return false;
    if ((buildings[name] ?? 0) <= 0) return false;
    if (!spendActionPoints(demolishActionCost, 'Demolish $name')) return false;
    buildings[name] = buildings[name]! - 1;
    if (name == 'Greenhouse' && greenhouseBuildSols.isNotEmpty) {
      greenhouseBuildSols.removeLast();
      crops.removeLast();
      if (greenhouseBuildSols.isEmpty) plantHealth = 100;
    }
    return true;
  }

  bool upgradeHabitat() {
    if (habitatLevel == 3) return false;
    if (!spendActionPoints(buildActionCost, 'Upgrade habitat')) return false;
    habitatLevel++;
    return true;
  }

  /// هل اللاعب يقدر يتصرف مع الحدث الحالي (وعنده الموارد)؟
  bool get canRespondNow {
    if (!_canAct) return false;
    if (event == 'None' || event == 'Mars Solar Conjunction' || mitigated) {
      return false;
    }
    final repair =
        event == 'Life Support Leak' || event == 'Equipment Malfunction';
    if (repair && conjunction) return false;
    if (event == 'Water System Strain') return energy >= strainRepairEnergy;
    if (event == 'Crop Contamination') return water >= cropTreatWater;
    return actionPoints >= responseActionCost;
  }

  bool respondToEvent() {
    if (!canRespondNow) return false;
    if (event == 'Water System Strain') {
      energy -= strainRepairEnergy;
      history.add(
        'Sol $sol: Respond to $event (-${strainRepairEnergy.round()} energy)',
      );
    } else if (event == 'Crop Contamination') {
      water -= cropTreatWater;
      history.add(
        'Sol $sol: Respond to $event (-${cropTreatWater.round()} water)',
      );
    } else {
      if (!spendActionPoints(responseActionCost, 'Respond to $event')) {
        return false;
      }
    }
    mitigated = true;
    if (event == 'Water System Strain') filterHealth = 100;
    if (event == 'Crop Contamination') cropAge = 0;
    if (eventDaysLeft == -1) eventDaysLeft = 1;
    return true;
  }

  // ------------------------------------------------------------------
  // المياه: دورة يدوية، الطاقة بتتخصم أول ما اللاعب يدوس
  // ------------------------------------------------------------------

  /// تكلفة الدورة الواحدة بالطاقة
  double get waterCycleCost => buildings['Water Recycler']! * waterCycleEnergy;

  /// المية اللي هتطلع من الدورة الواحدة (حسب حالة الفلتر وأي حدث)
  double get waterCycleYield {
    final fx = eventEffects();
    final quality = 0.5 + 0.5 * filterHealth / 100;
    return buildings['Water Recycler']! * waterCycleOutput * quality * fx[4];
  }

  /// صيانة الفلاتر بالطاقة
  bool maintainRecycler() {
    if (buildings['Water Recycler']! == 0 || !_canAct) return false;
    if (energy < recyclerMaintainEnergy) return false;
    energy -= recyclerMaintainEnergy;
    filterHealth = 100;
    history.add(
      'Sol $sol: Maintain Water Recycler (-${recyclerMaintainEnergy.round()} energy)',
    );
    if (event == 'Water System Strain') {
      mitigated = true;
      eventDaysLeft = 1;
    }
    return true;
  }

  // ------------------------------------------------------------------
  // الصوبة: ري مرة واحدة لكل الأحواض، والأحواض الناضجة بتطلع 10 أكل في الـ Sol
  // ------------------------------------------------------------------
  bool maintain(String name) {
    if (name == 'Water Recycler') return maintainRecycler();
    if (name != 'Greenhouse') return false;
    if (buildings['Greenhouse']! == 0 || !_canAct) return false;
    if (irrigated) return false; // اتروت النهاردة
    if (water < greenhouseMaintainWater) return false;
    water -= greenhouseMaintainWater;
    irrigated = true;
    cropAge = 0;
    plantHealth = limit(plantHealth + 20, 100);
    for (var i = 0; i < crops.length; i++) {
      crops[i] = max(crops[i], min(greenhouseHarvestYield, cropStorageMax));
    }
    history.add(
      'Sol $sol: Water the greenhouse (-${greenhouseMaintainWater.round()} water)',
    );
    if (event == 'Crop Contamination') {
      mitigated = true;
      eventDaysLeft = 1;
    }
    return true;
  }

  /// بيسحب كل شحنة البطارية (على قد ما عداد الطاقة يستحمل) لعداد الطاقة
  double collectEnergy() {
    if (!_canAct) return 0;
    final amount = min(battery, energyLimit - energy);
    if (amount <= 0) return 0;
    battery -= amount;
    energy += amount;
    history.add('Sol $sol: Collect ${amount.round()} energy from the battery');
    return amount;
  }

  /// بيحصد المحصول الجاهز في حوض واحد وبيضيفه للأكل
  double harvest(int index, {double maxAmount = greenhouseHarvestYield}) {
    if (!_canAct || index < 0 || index >= crops.length) return 0;
    final take = min(min(crops[index], maxAmount), resourceLimit - food);
    if (take <= 0) return 0;
    crops[index] -= take;
    food = limit(food + take, resourceLimit);
    history.add('Sol $sol: Harvest bed ${index + 1} (+${take.round()} food)');
    return take;
  }

  double harvestAll() {
    double total = 0;
    for (var i = 0; i < crops.length; i++) {
      total += harvest(i, maxAmount: cropStorageMax);
    }
    return total;
  }

  bool callForHelp() {
    if (conjunction) return false;
    return spendActionPoints(1, 'Ask Mission Control for advice');
  }

  // [solar, all-power, oxygen-use, radiation-add, water-eff, food-output]
  List<double> eventEffects() {
    // العاصفة: 3% من غير تأمين، 10% لو اللاعب أمّن الألواح (Stow)
    if (event == 'Dust Storm') return [mitigated ? 0.10 : 0.03, 1, 1, 0, 1, 1];
    if (event == 'Solar Flare') return [1, 1, 1, mitigated ? 5 : 25, 1, 1];
    if (!mitigated) {
      if (event == 'Life Support Leak') return [1, 1, 2, 0, 1, 1];
      if (event == 'Equipment Malfunction') return [1, 0.85, 1, 0, 1, 1];
      if (event == 'Crop Contamination') return [1, 1, 1, 0, 1, 0.6];
      if (event == 'Water System Strain') return [1, 1, 1, 0, 0.85, 1];
    }
    return [1, 1, 1, 0, 1, 1];
  }

  // ------------------------------------------------------------------
  // حساب نهاية الـ Sol (بنفس المعادلة للتوقع اللي في الـ HUD)
  // ------------------------------------------------------------------

  /// بيحسب نتيجة الـ Sol من غير ما يغير أي حاجة
  Map<String, double> _plan(List<double> fx) {
    final produced = expectedProduction();
    final newBattery = limit(battery + produced, batteryMax);

    // الطاقة التلقائية: القبة الأول، وبعدين مولدات الأكسجين
    final habitatUsed = min(energy, habitatBaseLoad);
    final perGen = operatingEnergy['Oxygen Generator']!;
    final gens = buildings['Oxygen Generator']!;
    final running = min(gens, ((energy - habitatUsed) / perGen).floor());
    final genRun = running < 0 ? 0 : running;
    // دورة المياه أوتوماتيك: بتشتغل بعد القبة ومولدات الأكسجين لو فاضل طاقة
    final cycleCost = waterCycleCost;
    final leftover = energy - habitatUsed - genRun * perGen;
    final cycleRun =
        buildings['Water Recycler']! > 0 &&
        leftover >= cycleCost &&
        water - crewCount * waterPerPerson < resourceLimit;
    final cycleWater = cycleRun ? waterCycleYield : 0.0;
    final used = habitatUsed + genRun * perGen + (cycleRun ? cycleCost : 0.0);

    final ripe = activeGreenhouses();
    final plantO2 = ripe * plantOxygen * plantFactor;
    final newOxygen = limit(
      oxygen +
          genRun * buildingOutput['Oxygen Generator']! +
          plantO2 -
          crewCount * oxygenPerPerson * fx[2],
      resourceLimit,
    );
    final newWater = limit(
      water - crewCount * waterPerPerson + cycleWater,
      resourceLimit,
    );
    final newFood = limit(food - crewCount * foodPerPerson, resourceLimit);
    final newRad = limit(
      radiation +
          radiationPerSol * habitatMultipliers[habitatLevel - 1] +
          fx[3],
      resourceLimit,
    );
    final newHealth = (newWater <= 0 || newFood <= 0)
        ? limit(health - healthLoss, resourceLimit)
        : health;

    return {
      'produced': produced,
      'battery': newBattery,
      'used': used,
      'genRun': genRun.toDouble(),
      'cycleRun': cycleRun ? 1.0 : 0.0,
      'cycleWater': cycleWater,
      'energy': limit(energy - used, energyLimit),
      'oxygen': newOxygen,
      'water': newWater,
      'food': newFood,
      'radiation': newRad,
      'health': newHealth,
    };
  }

  /// "لو معملتش حاجة تاني": التغيير المتوقع في كل مورد في آخر الـ Sol.
  /// ده اللي بيظهر في الأسهم والأرقام فوق (مثلاً ▼-12).
  Map<String, double> forecast() {
    if (!decisionPhase || status != 'OK') {
      return {
        'oxygen': 0,
        'energy': 0,
        'battery': 0,
        'water': 0,
        'food': 0,
        'radiation': 0,
        'health': 0,
      };
    }
    final p = _plan(eventEffects());
    return {
      'oxygen': p['oxygen']! - oxygen,
      'energy': p['energy']! - energy,
      'battery': p['battery']! - battery,
      'water': p['water']! - water,
      'food': p['food']! - food,
      'radiation': p['radiation']! - radiation,
      'health': p['health']! - health,
    };
  }

  /// صحة النباتات: بتقع لو الأحواض مترواش أو في تلوث، وبتتعافى لو اتروت
  void _updatePlants() {
    if (greenhouseBuildSols.isEmpty) return;
    double change = irrigated ? 5 : -8;
    if (event == 'Crop Contamination' && !mitigated) change -= 15;
    plantHealth = limit(plantHealth + change, 100);
  }

  void checkResult(bool completedSol) {
    final List<String> reasons = [];
    if (oxygen <= 0) reasons.add('Oxygen reached zero');
    if (health <= 0) reasons.add('Crew health reached zero');
    if (radiation >= resourceLimit) reasons.add('Radiation reached 100');
    if (reasons.isNotEmpty) {
      status = 'GAME OVER';
      failureReason = reasons.join('; ');
    } else if (completedSol && sol >= missionLength) {
      status = 'MISSION WIN';
    }
  }

  String finishSol() {
    if (!decisionPhase || status != 'OK') {
      throw StateError('Call beginSol first.');
    }
    final double oldOxygen = oxygen,
        oldWater = water,
        oldFood = food,
        oldEnergy = energy,
        oldBattery = battery,
        oldRadiation = radiation,
        oldHealth = health;
    final List<double> fx = eventEffects();
    final p = _plan(fx);

    energyProduced = p['produced']!;
    energyDemand = autoDemand();
    energyUsed = p['used']!;
    oxygenRunning = p['genRun']!.round();
    battery = p['battery']!;
    if (p['cycleRun']! > 0) {
      waterCycles = 1;
      filterHealth = limit(filterHealth - filterWearPerCycle, 100);
      history.add(
        'Sol $sol: Auto water cycle (-${waterCycleCost.round()} energy, +${p['cycleWater']!.round()} water)',
      );
    } else {
      waterCycles = 0;
    }
    energy = p['energy']!;
    oxygen = p['oxygen']!;
    water = p['water']!;
    food = p['food']!;
    radiation = p['radiation']!;
    health = p['health']!;

    // المحصول: كل حوض ناضج اتروى النهاردة بيطلع 10 أكل متخزن (يحصده اللاعب)
    if (irrigated) {
      for (int i = 0; i < greenhouseBuildSols.length; i++) {
        if (sol - greenhouseBuildSols[i] >= greenhouseGrowTime) {
          crops[i] = limit(
            crops[i] + bedYield * fx[5] * plantFactor,
            cropStorageMax,
          );
        }
      }
    }
    _updatePlants();
    if (activeGreenhouses() > 0) cropAge++;
    checkResult(true);

    delta = {
      'oxygen': oxygen - oldOxygen,
      'energy': energy - oldEnergy,
      'battery': battery - oldBattery,
      'water': water - oldWater,
      'food': food - oldFood,
      'radiation': radiation - oldRadiation,
      'health': health - oldHealth,
    };
    lastEvent = event;

    final String report =
        'Sol $sol | $event | O2=$oxygen (${oxygen - oldOxygen}) '
        '| Water=$water (${water - oldWater}) | Food=$food (${food - oldFood}) '
        '| Energy=$energy | Battery=$battery | Radiation=$radiation '
        '| Health=$health | $status';
    history.add(report);
    postStorm = false;
    if (eventDaysLeft > 0) eventDaysLeft--;
    if (eventDaysLeft == 0) {
      postStorm = event == 'Dust Storm';
      event = 'None';
    }
    decisionPhase = false;
    if (status == 'OK') sol++;
    return report;
  }

  List<String> warnings() {
    final List<String> result = [];
    if (oxygen <= 25) result.add('Low oxygen');
    if (water <= 20) result.add('Low water');
    if (food <= 20) result.add('Low food');
    if (sol > 1 && energy <= 15) {
      result.add(battery >= 10 ? 'Collect energy' : 'Low energy');
    }
    if (storedCrops >= 20 && food <= 60) result.add('Harvest crops');
    if (radiation >= 60) result.add('High radiation');
    return result;
  }

  String debrief() {
    return '$status. Rank: $rank. $failureReason\n'
        'Decision history:\n${history.join('\n')}\n'
        'Science context: astronauts need reliable life support.\n'
        'https://www.nasa.gov/reference/environmental-control-and-life-support-systems-eclss/\n'
        'The simulation rates and event penalties are invented game values.';
  }
}
