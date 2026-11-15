import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

final ValueNotifier<bool> gameArabic = ValueNotifier(false);

Future<void> initGameLocale() async {
  final preferences = await SharedPreferences.getInstance();
  gameArabic.value = preferences.getBool('game_arabic') ?? false;
}

Future<void> setGameArabic(bool value) async {
  gameArabic.value = value;
  final preferences = await SharedPreferences.getInstance();
  await preferences.setBool('game_arabic', value);
}

final RegExp _sunAnglePattern = RegExp(
  r'^The sun is at (\d+)% today\. Move the TILT slider close to it for more energy\.$',
);
final RegExp _balancePattern = RegExp(
  r'^We use (\d+) energy a Sol but make only (\d+)\. We need more panels!$',
);
final RegExp _collectedPattern = RegExp(
  r'^Collected (\d+) energy! It is in your energy counter now\.$',
);
final RegExp _tiltSetPattern = RegExp(
  r'^Tilt set to (\d+)%. The sun is at (\d+)% today\.$',
);
final RegExp _costPattern = RegExp(r'^(\d+) (energy|water)$');
final RegExp _ownedPattern = RegExp(r'^Owned: (\d+) / (\d+)(.*)$');
final RegExp _levelPattern = RegExp(
  r'^Level (\d+) / 3: radiation \+([\d.]+) per Sol$',
);
final RegExp _actionChipPattern = RegExp(r'^(AP|ENERGY|WATER) (.+)$');
final RegExp _buildCostPattern = RegExp(r'^(PLANT|WATER BEDS|FILTERS) · (.+)$');
final RegExp _crewWelcomePattern = RegExp(
  r'^Welcome to the crew, (.+)! Let me introduce the rest of the team\.$',
);
final RegExp _karimIntroPattern = RegExp(
  r'^"Hey, (.+)! I manage our Solar Panels, Nuclear Reactor, and Batteries\. Keep power flowing!"$',
);
final RegExp _eventPromptPattern = RegExp(
  r'^(.+)! Tap the Current Event box to decide\.$',
);
final RegExp _foodNoticePattern = RegExp(r'^([+]?\d+) FOOD$');

String gameText(String text) {
  if (!gameArabic.value) return text;
  final exact = _arabic[text] ?? _arabicExtra[text];
  if (exact != null) return exact;
  final tilt = _sunAnglePattern.firstMatch(text);
  if (tilt != null) {
    return 'زاوية الشمس اليوم ${tilt[1]}٪. قرّب مؤشر الميل منها لزيادة الطاقة.';
  }
  final balance = _balancePattern.firstMatch(text);
  if (balance != null) {
    return 'نستهلك ${balance[1]} طاقة في اليوم الشمسي وننتج ${balance[2]} فقط. نحتاج ألواحًا إضافية!';
  }
  final collected = _collectedPattern.firstMatch(text);
  if (collected != null) {
    return 'تم تحصيل ${collected[1]} من الطاقة وإضافتها إلى المخزون.';
  }
  final tiltSet = _tiltSetPattern.firstMatch(text);
  if (tiltSet != null) {
    return 'تم ضبط الميل على ${tiltSet[1]}٪. زاوية الشمس اليوم ${tiltSet[2]}٪.';
  }
  final cost = _costPattern.firstMatch(text);
  if (cost != null) {
    final unit = cost[2] == 'energy' ? 'طاقة' : 'ماء';
    return '${cost[1]} $unit';
  }
  final owned = _ownedPattern.firstMatch(text);
  if (owned != null) {
    final ripe = owned[3]!.replaceFirst('(ripe: ', '(ناضج: ');
    return 'المبني: ${owned[1]} / ${owned[2]}$ripe';
  }
  final level = _levelPattern.firstMatch(text);
  if (level != null) {
    return 'المستوى ${level[1]} / 3: زيادة الإشعاع +${level[2]} يوميًا';
  }
  final actionChip = _actionChipPattern.firstMatch(text);
  if (actionChip != null) {
    final label = switch (actionChip[1]) {
      'AP' => 'الإجراءات',
      'ENERGY' => 'الطاقة',
      _ => 'الماء',
    };
    return '$label ${actionChip[2]}';
  }
  final buildCost = _buildCostPattern.firstMatch(text);
  if (buildCost != null) {
    final label = switch (buildCost[1]) {
      'PLANT' => 'زراعة',
      'WATER BEDS' => 'ري الأحواض',
      _ => 'الفلاتر',
    };
    return '$label · ${gameText(buildCost[2]!)}';
  }
  final crewWelcome = _crewWelcomePattern.firstMatch(text);
  if (crewWelcome != null) {
    return 'مرحبًا بك في الطاقم يا ${crewWelcome[1]}! دعني أعرّفك ببقية الفريق.';
  }
  final karimIntro = _karimIntroPattern.firstMatch(text);
  if (karimIntro != null) {
    return '"مرحبًا ${karimIntro[1]}! أتولى إدارة الألواح الشمسية والمفاعل النووي والبطاريات. حافظ على تدفق الطاقة!"';
  }
  final eventPrompt = _eventPromptPattern.firstMatch(text);
  if (eventPrompt != null) {
    return 'حدث ${gameText(eventPrompt[1]!)}! اضغط على صندوق الحدث الحالي للاستجابة.';
  }
  final foodNotice = _foodNoticePattern.firstMatch(text);
  if (foodNotice != null) return '${foodNotice[1]} طعام';
  for (final t in _templates) {
    final m = t.re.firstMatch(text);
    if (m == null) continue;
    var out = t.ar;
    for (var i = 1; i <= m.groupCount; i++) {
      out = out.replaceAll('{$i}', _tr(m[i]!));
    }
    return out;
  }
  for (final entry in _prefixArabic.entries) {
    if (text.startsWith(entry.key)) {
      return '${entry.value}${text.substring(entry.key.length)}';
    }
  }
  return text;
}

const Map<String, String> _arabic = {
  'SETTINGS': 'الإعدادات',
  'MUSIC': 'الموسيقى',
  'SFX': 'المؤثرات',
  'ON': 'يعمل',
  'OFF': 'متوقف',
  'SOUND': 'الصوت',
  'TEXT SIZE': 'حجم النص',
  'LANGUAGE': 'اللغة',
  'ENGLISH': 'الإنجليزية',
  'ARABIC': 'العربية',
  'HOW TO PLAY': 'طريقة اللعب',
  'SOURCES': 'المصادر',
  'START GAME': 'ابدأ اللعبة',
  'CONTINUE': 'متابعة',
  'BACK': 'رجوع',
  'OK': 'حسنًا',
  'CANCEL': 'إلغاء',
  'NEW GAME': 'لعبة جديدة',
  'New game': 'لعبة جديدة',
  'Cancel': 'إلغاء',
  'Start a new game?': 'بدء لعبة جديدة؟',
  'Your saved mission will be deleted. Use CONTINUE if you want to keep it.':
      'سيتم حذف المهمة المحفوظة. اختر «متابعة» للاحتفاظ بها.',
  'MARS OUTPOST': 'قاعدة المريخ',
  'SOL': 'اليوم الشمسي',
  'Oxygen': 'الأكسجين',
  'Battery': 'البطارية',
  'Action Points': 'نقاط الإجراءات',
  'every Sol': 'كل يوم شمسي',
  'Morning report !': 'تقرير الصباح',
  'Feed back of sol': 'تقرير اليوم الشمسي',
  'Event': 'الحدث',
  'HIGH!!': 'مرتفع!!',
  'LOW!!': 'منخفض!!',
  'BASE ACTIONS': 'إجراءات القاعدة',
  'MAX': 'الحد الأقصى',
  'DEMOLISH': 'هدم',
  'Demolish one (1 AP)': 'هدم مبنى (نقطة إجراءات واحدة)',
  'Habitat shielding': 'درع الموطن',
  'UPGRADE · 2 AP': 'ترقية · نقطتا إجراءات',
  'Ask Mission Control': 'طلب المشورة من مركز التحكم',
  'No contact during the blackout.': 'لا يوجد اتصال أثناء انقطاع الاتصالات.',
  'Get advice on what to fix next.': 'احصل على نصيحة بشأن ما يجب إصلاحه.',
  'ASK · 1 AP': 'اسأل · نقطة إجراءات',
  'Mission Control': 'مركز التحكم',
  'Current Event': 'الحدث الحالي',
  'No active event': 'لا يوجد حدث نشط',
  'Handled this Sol.': 'تم التعامل معه اليوم.',
  'Tap to decide.': 'اضغط لاتخاذ قرار.',
  'The base is stable for now.': 'القاعدة مستقرة حاليًا.',
  'BUILD  /  ACTIONS': 'البناء / الإجراءات',
  'END SOL': 'إنهاء اليوم الشمسي',
  'Radiation is getting dangerous! Upgrade the habitat shielding now.':
      'الإشعاع أصبح خطيرًا! طوّر درع الموطن الآن.',
  'Our energy counter is low! Tap the Battery module to collect its charge.':
      'مخزون الطاقة منخفض! اضغط على وحدة البطارية لتحصيل الشحنة.',
  'We are out of energy! Build solar panels or a nuclear unit.':
      'نفدت الطاقة! ابنِ ألواحًا شمسية أو وحدة نووية.',
  'The crops are ready! Harvest them in the greenhouse.':
      'المحاصيل جاهزة! احصدها من الصوبة الزراعية.',
  'Solar flare! Radiation is rising. Tap the Current Event box.':
      'توهج شمسي! الإشعاع يرتفع. اضغط على صندوق الحدث الحالي.',
  'Earth contact is dark. We are on our own until Sol 12.':
      'انقطع الاتصال بالأرض. سنعتمد على أنفسنا حتى اليوم الشمسي 12.',
  'You are out of energy.': 'نفدت الطاقة.',
  'Dust Storm': 'عاصفة غبارية',
  'Solar Flare': 'توهج شمسي',
  'Mars Solar Conjunction': 'اقتران المريخ والشمس',
  'Life Support Leak': 'تسرب دعم الحياة',
  'Equipment Malfunction': 'عطل في المعدات',
  'Crop Contamination': 'تلوث المحاصيل',
  'Water System Strain': 'إجهاد نظام المياه',
  'Dust blocks the sun. Solar output falls to 3% (10% if you shelter). The storm lasts a few Sols.':
      'يحجب الغبار الشمس. ينخفض إنتاج الطاقة إلى 3٪ (10٪ عند الاحتماء). تستمر العاصفة عدة أيام شمسية.',
  'A radiation spike hits the base: +25 Radiation, or only +5 if you shelter.':
      'ضربة إشعاعية تصيب القاعدة: +25 إشعاعًا، أو +5 فقط عند الاحتماء.',
  'Earth contact is dark. No repairs and no help from Mission Control until Sol 12.':
      'انقطع الاتصال بالأرض. لا إصلاحات أو مساعدة من مركز التحكم حتى اليوم الشمسي 12.',
  'Oxygen use doubles until the leak is repaired.':
      'يتضاعف استهلاك الأكسجين حتى إصلاح التسرب.',
  'Energy output drops by 15% until the equipment is repaired.':
      'ينخفض إنتاج الطاقة بنسبة 15٪ حتى إصلاح المعدات.',
  'Food output drops by 40% until the greenhouse is treated.':
      'ينخفض إنتاج الغذاء بنسبة 40٪ حتى معالجة الصوبة الزراعية.',
  'Water recycler efficiency drops by 15% until it is maintained.':
      'تنخفض كفاءة جهاز تدوير المياه بنسبة 15٪ حتى صيانته.',
  'None': 'لا يوجد',
  'No events expected today.': 'لا توجد أحداث متوقعة اليوم.',
  'Solar Conjunction: Earth contact is dark.':
      'الاقتران الشمسي: انقطع الاتصال بالأرض.',
  'Already handled this Sol.': 'تم التعامل مع هذا الحدث اليوم.',
  'No repairs possible during the blackout.':
      'لا يمكن إجراء إصلاحات أثناء انقطاع الاتصالات.',
  'Something unusual is happening at the outpost.':
      'هناك أمر غير معتاد يحدث في القاعدة.',
  'Respond': 'استجب',
  'Shelter & reduce operations': 'احتمِ وقلل العمليات',
  'Shelter in habitat': 'احتمِ داخل الموطن',
  'Repair the leak': 'أصلح التسرب',
  'Repair equipment': 'أصلح المعدات',
  'Treat the greenhouse': 'عالج الصوبة الزراعية',
  'Maintain the recycler': 'صُن جهاز إعادة التدوير',
  '1 AP': 'نقطة إجراءات واحدة',
  'Understood — 0 AP': 'مفهوم · دون نقاط إجراءات',
  'Continue operations — 0 AP': 'تابع العمليات · دون نقاط إجراءات',
  'Oxygen drops to zero': 'انخفاض الأكسجين إلى الصفر',
  'Energy': 'الطاقة',
  'Water': 'الماء',
  'Food': 'الغذاء',
  'Radiation': 'الإشعاع',
  'Crew Health': 'صحة الطاقم',
  'SOLAR FIELD': 'حقل الطاقة الشمسية',
  'GREENHOUSE': 'الصوبة الزراعية',
  'WATER TANK': 'خزان المياه',
  'Solar Panels': 'ألواح شمسية',
  'Nuclear Unit': 'وحدة نووية',
  'Oxygen Generator': 'مولد أكسجين',
  'Water Recycler': 'جهاز تدوير المياه',
  'Greenhouse': 'صوبة زراعية',
  '+15 energy / Sol (3% in dust storms)':
      '+15 طاقة / يوم شمسي (3٪ أثناء العواصف الغبارية)',
  '+12 energy / Sol, storm-proof': '+12 طاقة / يوم شمسي، مقاومة للعواصف',
  '+20 oxygen / Sol, uses 6 energy': '+20 أكسجين / يوم شمسي، تستهلك 6 طاقة',
  '+15 water / Sol (auto cycle), 5 energy per cycle':
      '+15 ماء / يوم شمسي (دورة تلقائية)، 5 طاقة لكل دورة',
  'Owned:': 'المبني:',
  'BUILD · 2 AP': 'بناء · نقطتا إجراءات',
  'WATERED TODAY': 'تم الري اليوم',
  'UPGRADE ·': 'ترقية ·',
  'PLEASE': 'من فضلك',
  'Enter Outpost': 'ادخل القاعدة',
  'Mission Briefing': 'إحاطة المهمة',
  'Commander Nadia': 'القائدة نادية',
  'NEXT': 'التالي',
  'SKIP': 'تخطي',
  'START PLAYING': 'ابدأ اللعب',
  'YOUR MISSION': 'مهمتك',
  'YOUR ROUTINE EVERY SOL': 'روتينك كل يوم شمسي',
  'THE TOP BAR': 'الشريط العلوي',
  'ACTION POINTS (AP)': 'نقاط الإجراءات',
  'WHAT TO BUILD FIRST': 'ما الذي تبنيه أولًا؟',
  'EVENTS AND THE BLACKOUT': 'الأحداث وانقطاع الاتصالات',
  'Panels': 'الألواح',
  'Making now': 'الإنتاج الحالي',
  'Systems need': 'احتياج الأنظمة',
  'Balance': 'الرصيد',
  'Energy counter': 'مخزون الطاقة',
  'TILT': 'الميل',
  'SUN ANGLE': 'زاوية الشمس',
  'OUTPUT': 'الإنتاج',
  'TAP TO COLLECT': 'اضغط للتحصيل',
  'COMMS': 'الاتصالات',
  'COMMS OFFLINE': 'الاتصالات معطلة',
  'Commander': 'القائدة',
  'Output:': 'الإنتاج:',
  'Health:': 'الحالة:',
  'DAMAGED': 'متضرر',
  'HEALTHY': 'سليم',
  'Your energy counter is low! Tap the battery to collect its energy.':
      'مخزون الطاقة منخفض! اضغط على البطارية لتحصيل الطاقة.',
  'Dust storm! The panels barely work. Stow them, and a nuclear unit would help a lot.':
      'عاصفة غبارية! الألواح بالكاد تعمل. اطوِها، وستساعدك وحدة نووية كثيرًا.',
  'One panel is damaged. Repair it to get the energy back.':
      'أحد الألواح متضرر. أصلحه لاستعادة الطاقة.',
  'The breaker is OFF! The panels are not feeding the base.':
      'القاطع مغلق! الألواح لا تمد القاعدة بالطاقة.',
  'The panels are glowing! Tap the battery every Sol to collect the energy.':
      'الألواح تعمل! اضغط على البطارية كل يوم شمسي لتحصيل الطاقة.',
  'Breaker ON. The panels feed the base again.':
      'القاطع يعمل. الألواح تمد القاعدة بالطاقة مجددًا.',
  'Breaker OFF. No solar energy reaches the base!':
      'القاطع متوقف. لا تصل الطاقة الشمسية إلى القاعدة!',
  'Stow the panels only during a dust storm.':
      'لا تطوِ الألواح إلا أثناء العاصفة الغبارية.',
  'Panels stowed! We keep 10% output through the storm.':
      'طُويت الألواح! سيستمر الإنتاج بنسبة ١٠٪ أثناء العاصفة.',
  'Already handled, or no Action Points left.':
      'تم التعامل مع الأمر أو لا توجد نقاط إجراءات كافية.',
  'The battery is empty. Panels charge it at the end of each Sol.':
      'البطارية فارغة. تشحنها الألواح في نهاية كل يوم شمسي.',
  'A dust storm is approaching. Stow the panels to protect them.':
      'عاصفة غبارية تقترب. اطوِ الألواح لحمايتها.',
  'Next': 'التالي',
  'Meet the crew': 'تعرّف على الطاقم',
  'Next Crewmember': 'الفرد التالي من الطاقم',
  'ENTER YOUR CADET NAME:': 'أدخل اسم المتدرب:',
  'First things first. What should we call you?':
      'أولًا، ما الاسم الذي نستخدمه؟',
  'Type your name or callsign...': 'اكتب اسمك أو لقبك...',
  'Confirm Identity': 'تأكيد الهوية',
  'Please enter a name to continue.': 'أدخل اسمًا للمتابعة.',
  'The name must have at least 2 characters.': 'يجب ألا يقل الاسم عن حرفين.',
  'The name can have at most 16 characters.': 'يجب ألا يزيد الاسم عن 16 حرفًا.',
  'Use letters, numbers, spaces, - _ . only, and start with a letter or number.':
      'استخدم الحروف والأرقام والمسافات والرموز - _ . فقط، وابدأ بحرف أو رقم.',
  'The name must contain at least one letter.':
      'يجب أن يحتوي الاسم على حرف واحد على الأقل.',
  'No double spaces please.': 'تجنب تكرار المسافات.',
  'Over here, Cadet! I\'m Commander Nadia. I run Outpost Theta-9, our training base on Mars. I lead construction and operations, and I\'ll be guiding you.':
      'من هنا أيها المتدرب! أنا القائدة نادية، أدير قاعدة ثيتا-9 التدريبية على المريخ. أتولى البناء والعمليات وسأرشدك خلال المهمة.',
  'This is Mars. A day here is called a Sol, and it lasts about 24 hours 39 minutes. The air is 95% carbon dioxide, so we have to make our own oxygen, water and food.':
      'هذا هو المريخ. يُسمى اليوم هنا يومًا شمسيًا، ومدته نحو 24 ساعة و39 دقيقة. يتكون الهواء من 95٪ من ثاني أكسيد الكربون، لذا علينا إنتاج الأكسجين والماء والطعام بأنفسنا.',
  'Our training mission: keep the crew alive for 20 Sols. Every couple of years the Sun disrupts the radio link between Earth and Mars. In our scenario that blackout starts at Sol 10 and lasts three Sols, so we are on our own.':
      'مهمتنا التدريبية هي إبقاء الطاقم على قيد الحياة لمدة 20 يومًا شمسيًا. كل بضع سنوات تعطل الشمس الاتصال اللاسلكي بين الأرض والمريخ. في مهمتنا يبدأ الانقطاع في اليوم 10 ويستمر ثلاثة أيام، وسنعتمد على أنفسنا.',
  '"Welcome aboard! I oversee Oxygen generation, Water recycling, and Greenhouse crops."':
      '"مرحبًا بك! أشرف على إنتاج الأكسجين وتدوير المياه ومحاصيل الصوبة الزراعية."',
  'That makes four of us, counting you. Let\'s go over the plan before we start.':
      'أصبحنا أربعة أفراد معك. لنراجع الخطة قبل أن نبدأ.',
};

const Map<String, String> _prefixArabic = {
  'Panels:': 'الألواح:',
  'Making now:': 'الإنتاج الحالي:',
  'Systems need:': 'احتياج الأنظمة:',
  'Balance:': 'الرصيد:',
  'Energy counter:': 'مخزون الطاقة:',
  'DUST STORM:': 'عاصفة غبارية:',
  'Output:': 'الإنتاج:',
  'Dust:': 'الغبار:',
  'Health:': 'الحالة:',
  'Event:': 'الحدث:',
  'Action Points:': 'نقاط الإجراءات:',
};

// ---- ترجمات إضافية (شخصيات، حوارات، شاشات المنشآت، المهام...) ----
const Map<String, String> _arabicExtra = {
  'Karim':
      'كريم',
  'Amara':
      'أمارة',
  'Youssef':
      'يوسف',
  'Dr. Reyes':
      'د. رييس',
  'Base Commander & Lead Engineer':
      'قائدة القاعدة وكبيرة المهندسين',
  'Systems & Power Specialist':
      'أخصائي الأنظمة والطاقة',
  'Life Support & Biosphere Specialist':
      'أخصائية دعم الحياة والمحيط الحيوي',
  'Flight Doctor & Radiation Specialist':
      'طبيب الرحلة وأخصائي الإشعاع',
  'Mission Control (Earth)':
      'مركز التحكم (الأرض)',
  'Stay calm and keep every need balanced, Cadet.':
      'ابقَ هادئًا ووازن بين كل الاحتياجات أيها المتدرب.',
  'Think two Sols ahead. Today\'s choice is tomorrow\'s problem.':
      'فكّر بيومين شمسيين قادمين. قرار اليوم هو مشكلة الغد.',
  'Every decision costs something. Choose wisely.':
      'كل قرار له ثمن. اختر بحكمة.',
  'Power is life! More panels, more smiles!':
      'الطاقة هي الحياة! ألواح أكثر، وابتسامات أكثر!',
  'Dust storm? Pfft. That is what batteries are for!':
      'عاصفة غبارية؟ لا تقلق! لهذا وُجدت البطاريات!',
  'The sun always comes back. We just have to be ready!':
      'الشمس تعود دائمًا. علينا فقط أن نكون جاهزين!',
  'Every drop of water counts. Recycle, recycle, recycle.':
      'كل قطرة ماء لها قيمة. أعد التدوير، ثم أعد التدوير.',
  'Plants grow slowly. Plant early and check on them.':
      'النباتات تنمو ببطء. ازرع مبكرًا وتفقّدها باستمرار.',
  'Small problems get big fast. Maintain before it breaks.':
      'المشكلات الصغيرة تكبر بسرعة. قم بالصيانة قبل أن يتعطل الشيء.',
  'Radiation is invisible, but it adds up every Sol. Shield the habitat.':
      'الإشعاع غير مرئي لكنه يتراكم كل يوم شمسي. قوِّ درع الموطن.',
  'A healthy crew needs water, food and air. Skip one and I will see it.':
      'الطاقم السليم يحتاج إلى ماء وغذاء وهواء. إن أهملت واحدًا منها سألاحظ ذلك.',
  'Prevention is easier than treatment. Plan ahead, Cadet.':
      'الوقاية أسهل من العلاج. خطّط مسبقًا أيها المتدرب.',
  'Mission Control here. We are watching your telemetry, Cadet.':
      'هنا مركز التحكم. نراقب بياناتك أيها المتدرب.',
  'Remember: every Sol you survive is a win for the whole team.':
      'تذكّر: كل يوم شمسي تنجو فيه هو فوز للفريق كله.',
  'Earth is with you, even when the signal is not.':
      'الأرض معك، حتى حين تغيب الإشارة.',
  'Low oxygen':
      'نقص الأكسجين',
  'Low water':
      'نقص الماء',
  'Low food':
      'نقص الغذاء',
  'Low energy':
      'الطاقة منخفضة',
  'Collect energy':
      'حصّل الطاقة',
  'Harvest crops':
      'احصد المحاصيل',
  'High radiation':
      'إشعاع مرتفع',
  'low oxygen':
      'نقص الأكسجين',
  'low water':
      'نقص الماء',
  'low food':
      'نقص الغذاء',
  'energy':
      'الطاقة',
  'water':
      'الماء',
  'ENERGY':
      'الطاقة',
  'WATER':
      'الماء',
  'FOOD':
      'الغذاء',
  'OXYGEN':
      'الأكسجين',
  'RADIATION':
      'الإشعاع',
  'Last clear transmission, Cadet. Contact drops tomorrow. Stock up!':
      'آخر إرسال واضح أيها المتدرب. سينقطع الاتصال غدًا. خزّن ما تحتاجه!',
  'Contact restored! Good to hear from you, Cadet.':
      'عاد الاتصال! يسعدنا سماعك أيها المتدرب.',
  'NEXT SOL':
      'اليوم التالي',
  'FOOD FULL':
      'مخزون الغذاء ممتلئ',
  'Leave the outpost?':
      'مغادرة القاعدة؟',
  'Your progress is saved. Press CONTINUE in the main menu to pick up where you left off.':
      'تقدمك محفوظ. اضغط «متابعة» في القائمة الرئيسية لتكمل من حيث توقفت.',
  'Keep playing':
      'واصل اللعب',
  'Save & exit':
      'احفظ واخرج',
  'MISSION WIN':
      'نجحت المهمة',
  'GAME OVER':
      'انتهت اللعبة',
  'Oxygen reached zero':
      'وصل الأكسجين إلى الصفر',
  'Crew health reached zero':
      'وصلت صحة الطاقم إلى الصفر',
  'Radiation reached 100':
      'وصل الإشعاع إلى 100',
  'Pilot':
      'طيار',
  'Cadet':
      'متدرب',
  'MISSION COMPLETE':
      'اكتملت المهمة',
  'MISSION FAILED':
      'فشلت المهمة',
  'Your decisions':
      'قراراتك',
  'You made no decisions.':
      'لم تتخذ أي قرارات.',
  'MAIN MENU':
      'القائمة الرئيسية',
  'Made by Lumera':
      'من تطوير لوميرا',
  'NASA Fact: Mars atmosphere is 95% CO2. NASA\'s MOXIE on the Perseverance rover made oxygen from it, and the ISS now recovers about 98% of its water.\nThe mechanics are based on real NASA missions and research. Specific numbers (percentages, durations, costs) are game values chosen for balance, not NASA data.':
      'معلومة من ناسا: يتكون غلاف المريخ الجوي من 95٪ من ثاني أكسيد الكربون. وقد صنع جهاز «موكسي» التابع لناسا على المركبة «برسفيرنس» الأكسجين منه، وتستعيد محطة الفضاء الدولية الآن نحو 98٪ من مياهها.\nتستند آليات اللعبة إلى مهمات وأبحاث حقيقية لناسا. أما الأرقام المحددة (النسب والمدد والتكاليف) فهي قيم وضعناها لتوازن اللعبة وليست بيانات من ناسا.',
  'HIGH':
      'عالية',
  'MEDIUM':
      'متوسطة',
  'NORMAL':
      'عادية',
  'Something is wrong at the outpost.':
      'هناك خطب ما في القاعدة.',
  'Energy Counter Low':
      'مخزون الطاقة منخفض',
  'Out of Energy':
      'نفدت الطاقة',
  'Oxygen Running Low':
      'الأكسجين يقل',
  'Water Running Low':
      'الماء يقل',
  'Food Running Low':
      'الغذاء يقل',
  'Crops Ready':
      'المحاصيل جاهزة',
  'Radiation Rising':
      'الإشعاع يرتفع',
  'Blackout Approaching':
      'انقطاع الاتصال يقترب',
  'Crop Check Complete':
      'اكتمل فحص المحاصيل',
  'Systems Check Complete':
      'اكتمل فحص الأنظمة',
  'Karim: The counter is almost empty but the battery has charge. Open the Battery and tap it to collect it.':
      'كريم: المخزون شبه فارغ لكن البطارية مشحونة. افتح البطارية واضغط عليها لتحصيل الطاقة.',
  'Karim: No energy left anywhere. Build solar panels or a nuclear unit.':
      'كريم: لا توجد طاقة في أي مكان. ابنِ ألواحًا شمسية أو وحدة نووية.',
  'Amara: Oxygen is low. The generators and plants must keep up with the crew.':
      'أمارة: الأكسجين منخفض. يجب أن تواكب المولدات والنباتات احتياج الطاقم.',
  'Amara: Water is low. The recycler runs by itself each Sol, so keep energy available.':
      'أمارة: الماء منخفض. جهاز التدوير يعمل تلقائيًا كل يوم شمسي، فأبقِ الطاقة متاحة.',
  'Amara: Food is low. Harvest the greenhouse crops.':
      'أمارة: الغذاء منخفض. احصد محاصيل الصوبة.',
  'Amara: Crops are waiting. Tap the ripe beds in the greenhouse to harvest.':
      'أمارة: المحاصيل في الانتظار. اضغط على الأحواض الناضجة في الصوبة للحصاد.',
  'Youssef: Radiation is dangerous. Upgrade the habitat shielding now.':
      'يوسف: الإشعاع خطير. طوّر درع الموطن الآن.',
  'Dr. Reyes: Earth contact drops at Sol 10. Stock up before then.':
      'د. رييس: سينقطع الاتصال بالأرض في اليوم الشمسي 10. خزّن ما تحتاجه قبل ذلك.',
  'Amara reports the greenhouse is stable. Crop production is normal.':
      'أمارة تبلّغ بأن الصوبة مستقرة وإنتاج المحاصيل طبيعي.',
  'Nadia reports the base is stable. No problems detected.':
      'نادية تبلّغ بأن القاعدة مستقرة. لم تُكتشف أي مشكلات.',
  'Notifications':
      'الإشعارات',
  'View Task':
      'عرض المهمة',
  'Do it now !':
      'نفّذها الآن!',
  'Upgrade Habitat Shielding':
      'طوّر درع الموطن',
  'Collect Energy':
      'حصّل الطاقة',
  'Harvest Crops':
      'احصد المحاصيل',
  'Secure Oxygen Supply':
      'أمّن إمدادات الأكسجين',
  'Secure Water Supply':
      'أمّن إمدادات الماء',
  'Grow Food':
      'ازرع الغذاء',
  'Add a Nuclear Unit':
      'أضف وحدة نووية',
  'Match the Panel Tilt':
      'اضبط ميل الألواح',
  'Decide how to handle it before you end the Sol.':
      'قرّر كيف تتعامل معه قبل إنهاء اليوم الشمسي.',
  'Open the Battery and tap it to collect. Buildings run on your energy counter.':
      'افتح البطارية واضغط عليها للتحصيل. المباني تعمل بمخزون الطاقة لديك.',
  'Water the greenhouse (MAINTAIN), and tomorrow tap each ripe bed to add its food.':
      'اسقِ الصوبة (صيانة)، وغدًا اضغط على كل حوض ناضج لإضافة غذائه.',
  'Build a 2nd Oxygen Generator. Four crew breathe 32 oxygen a Sol.':
      'ابنِ مولد أكسجين ثانيًا. يتنفس أربعة أفراد 32 وحدة أكسجين في اليوم الشمسي.',
  'Build a 2nd Water Recycler. It runs by itself each Sol. Four crew need 20 water a Sol.':
      'ابنِ جهاز تدوير مياه ثانيًا. يعمل تلقائيًا كل يوم شمسي. يحتاج أربعة أفراد إلى 20 وحدة ماء في اليوم الشمسي.',
  'Move the TILT slider close to the sun angle. A good tilt gives up to 15% more energy.':
      'قرّب مؤشر الميل من زاوية الشمس. الميل الجيد يعطي طاقة أكثر بنسبة تصل إلى 15٪.',
  'Next sol !':
      'اليوم الشمسي التالي!',
  'Back to Base':
      'العودة إلى القاعدة',
  'MISSION CONTROL':
      'مركز التحكم',
  'LINK: DARK (Solar Conjunction)':
      'الرابط: مظلم (الاقتران الشمسي)',
  'LINK: ONLINE':
      'الرابط: متصل',
  'No signal from Earth until Sol 12. You are on your own.':
      'لا توجد إشارة من الأرض حتى اليوم الشمسي 12. أنت وحدك.',
  'Ask for advice and I will tell you what to fix next.':
      'اطلب المشورة وسأخبرك بما يجب إصلاحه تاليًا.',
  'OFFLINE':
      'غير متصل',
  'ONLINE':
      'متصل',
  'Asking for advice costs 1 AP':
      'طلب المشورة يكلف نقطة إجراءات واحدة',
  'Contact drops during Sol 10 to 12':
      'ينقطع الاتصال من اليوم الشمسي 10 إلى 12',
  'Advice is based on your base right now':
      'المشورة مبنية على حالة قاعدتك الآن',
  'NO CONTACT':
      'لا يوجد اتصال',
  'ASK FOR ADVICE — 1 AP':
      'اطلب المشورة — نقطة إجراءات',
  'Contact is dark. Trust your training, Cadet.':
      'الاتصال مقطوع. ثق بتدريبك أيها المتدرب.',
  'Mission Control sees the whole picture. Ask when you are unsure.':
      'مركز التحكم يرى الصورة كاملة. اسأل حين لا تكون متأكدًا.',
  'Radiation builds fast on Mars. Upgrade the habitat shielding now, before it reaches 100.':
      'الإشعاع يتراكم بسرعة على المريخ. طوّر درع الموطن الآن قبل أن يصل إلى 100.',
  'Your energy counter is lower than what the base needs. Open the Battery module and tap it to collect energy.':
      'مخزون الطاقة لديك أقل مما تحتاجه القاعدة. افتح وحدة البطارية واضغط عليها لتحصيل الطاقة.',
  'There is no Water Recycler. Build one: it runs a water cycle by itself at the end of every Sol, using energy.':
      'لا يوجد جهاز تدوير مياه. ابنِ واحدًا: يشغّل دورة مياه تلقائيًا في نهاية كل يوم شمسي مستهلكًا الطاقة.',
  'Water is low. The recycler runs on its own at the end of each Sol, so keep some energy in the counter (collect it from the battery) and add another recycler.':
      'الماء منخفض. يعمل جهاز التدوير تلقائيًا في نهاية كل يوم شمسي، فأبقِ بعض الطاقة في المخزون (حصّلها من البطارية) وأضف جهاز تدوير آخر.',
  'There are crops waiting in the greenhouse. Harvest them to raise your food.':
      'هناك محاصيل في انتظارك في الصوبة. احصدها لزيادة غذائك.',
  'Everything looks stable. Collect energy, water and harvest the greenhouse, then end the Sol.':
      'كل شيء يبدو مستقرًا. حصّل الطاقة، واسقِ الصوبة واحصدها، ثم أنهِ اليوم الشمسي.',
  'GENERATOR':
      'مولد',
  'UNIT':
      'وحدة',
  'PANEL':
      'لوح',
  'NUCLEAR UNIT':
      'وحدة نووية',
  'OXYGEN GENERATOR':
      'مولد الأكسجين',
  'LIFE SUPPORT LEAK: oxygen use is doubled':
      'تسرب دعم الحياة: استهلاك الأكسجين مضاعف',
  'We make less oxygen than we breathe. Build another generator or grow more plants!':
      'ننتج أكسجينًا أقل مما نتنفس. ابنِ مولدًا آخر أو ازرع نباتات أكثر!',
  'Oxygen is stable. Keep the energy flowing and the plants healthy.':
      'الأكسجين مستقر. حافظ على تدفق الطاقة وسلامة النباتات.',
  'REPAIR LEAK — 1 AP':
      'أصلح التسرب — نقطة إجراءات',
  'INCOME vs NEEDS':
      'الدخل مقابل الاحتياج',
  'Works through dust storms, when the panels stop':
      'تعمل أثناء العواصف الغبارية حين تتوقف الألواح',
  'No reactor yet! The long dust storm is coming and the panels will stop completely.':
      'لا يوجد مفاعل بعد! العاصفة الغبارية الطويلة قادمة وستتوقف الألواح تمامًا.',
  'Steady power, rain or dust. That is what I like to see!':
      'طاقة ثابتة في كل الظروف. هذا ما أحب رؤيته!',
  'REPAIR EQUIPMENT — 1 AP':
      'أصلح المعدات — نقطة إجراءات',
  'HABITAT SHIELDING':
      'درع الموطن',
  'If it reaches 100 the mission fails':
      'إذا وصل إلى 100 فشلت المهمة',
  'SOLAR FLARE: +25 radiation (only +5 if you shelter)':
      'توهج شمسي: +25 إشعاعًا (+5 فقط عند الاحتماء)',
  'Maximum shielding. The habitat is as safe as we can make it.':
      'أقصى درجة من الحماية. الموطن آمن قدر الإمكان.',
  'Higher shielding slows the radiation. It pays off over 20 Sols.':
      'الدرع الأقوى يبطئ الإشعاع. وتظهر فائدته على مدى 20 يومًا شمسيًا.',
  'SHELTER IN HABITAT — 1 AP':
      'احتمِ داخل الموطن — نقطة إجراءات',
  'SHIELDING AT MAX LEVEL':
      'الدرع في أعلى مستوى',
  'UPGRADE SHIELDING — 2 AP':
      'ترقية الدرع — نقطتا إجراءات',
  'The battery is empty. Solar panels charge it at the end of each Sol.':
      'البطارية فارغة. تشحنها الألواح الشمسية في نهاية كل يوم شمسي.',
  'The energy counter is low! Tap the battery to collect its charge.':
      'مخزون الطاقة منخفض! اضغط على البطارية لتحصيل شحنتها.',
  'The battery is empty. The panels fill it at the end of each Sol.':
      'البطارية فارغة. تملؤها الألواح في نهاية كل يوم شمسي.',
  'Tap the battery every Sol to move its charge to your energy counter.':
      'اضغط على البطارية كل يوم شمسي لنقل شحنتها إلى مخزون الطاقة.',
  'BATTERY':
      'البطارية',
  'The base runs on the energy counter, not on the battery directly':
      'القاعدة تعمل بمخزون الطاقة وليس بالبطارية مباشرة',
  'BATTERY EMPTY':
      'البطارية فارغة',
  'COLLECT ENERGY':
      'حصّل الطاقة',
  'EMPTY':
      'فارغ',
  'RIPE':
      'ناضج',
  'REGROWING':
      'يعاد نموه',
  'GROWING':
      'ينمو',
  'NONE':
      'لا شيء',
  'ACTIVE':
      'نشط',
  'YES':
      'نعم',
  'NO':
      'لا',
  'GREENHOUSE 01':
      'الصوبة 01',
  'The food counter is full, nothing to add.':
      'مخزون الغذاء ممتلئ، لا شيء لإضافته.',
  'The crops are contaminated! Use FIX before the plants die.':
      'المحاصيل ملوثة! استخدم «إصلاح» قبل أن تموت النباتات.',
  'The crops are ready! Tap the beds with the golden box to harvest and raise our food.':
      'المحاصيل جاهزة! اضغط على الأحواض ذات الصندوق الذهبي للحصاد وزيادة غذائنا.',
  'The plants look sick. Maintain them, they give us our oxygen too!':
      'النباتات تبدو مريضة. اعتنِ بها، فهي تمنحنا الأكسجين أيضًا!',
  'Grow lights ON. The plants love it!':
      'أضواء النمو تعمل. النباتات تحبها!',
  'Grow lights OFF. Plants need light to grow.':
      'أضواء النمو متوقفة. تحتاج النباتات إلى الضوء لتنمو.',
  'Climate is stable: 22 degrees inside the dome.':
      'المناخ مستقر: 22 درجة داخل القبة.',
  'Contamination treated. Crops are safe.':
      'تمت معالجة التلوث. المحاصيل آمنة.',
  'Not enough water to treat the crops.':
      'لا يوجد ماء كافٍ لمعالجة المحاصيل.',
  'Nothing to fix. The crops are healthy.':
      'لا شيء لإصلاحه. المحاصيل سليمة.',
  'HARVEST ALL':
      'احصد الكل',
  'The food counter is full.':
      'مخزون الغذاء ممتلئ.',
  'WATERED':
      'تم الري',
  'DAMAGED':
      'متضرر',
  'LOW':
      'منخفض',
  'BUILD':
      'بناء',
  'CLEAN':
      'تنظيف',
  'REPAIR':
      'إصلاح',
  'New panel online. More energy!':
      'لوح جديد يعمل. طاقة أكثر!',
  'Cleaned and stowed!':
      'تم التنظيف والطي!',
  'Repaired! Output is back.':
      'تم الإصلاح! عاد الإنتاج.',
  'Empty slot. Build a panel (2 AP).':
      'خانة فارغة. ابنِ لوحًا (نقطتا إجراءات).',
  'STRAIN':
      'إجهاد',
  'AUTO':
      'تلقائي',
  'No recycler, Cadet! Without it the water runs out fast.':
      'لا يوجد جهاز تدوير أيها المتدرب! بدونه ينفد الماء بسرعة.',
  'Not enough energy for the auto water cycle! Go to the Solar Field and tap the battery to collect energy.':
      'لا توجد طاقة كافية لدورة المياه التلقائية! اذهب إلى حقل الطاقة الشمسية واضغط على البطارية لتحصيل الطاقة.',
  'The recycler is under strain! Repair it before the filters fail.':
      'جهاز التدوير تحت إجهاد! أصلحه قبل أن تتعطل الفلاتر.',
  'Valve to the habitat is OPEN. The crew has water.':
      'صمام الموطن مفتوح. الطاقم لديه ماء.',
  'Valve to the habitat is CLOSED. The crew gets no water!':
      'صمام الموطن مغلق. الطاقم بلا ماء!',
  'Valve to the greenhouse is OPEN. The crops are watered.':
      'صمام الصوبة مفتوح. المحاصيل تُسقى.',
  'Valve to the greenhouse is CLOSED. The crops are dry!':
      'صمام الصوبة مغلق. المحاصيل جافة!',
  'Pump ON. Water is moving through the system.':
      'المضخة تعمل. الماء يتدفق في النظام.',
  'Pump OFF. Nothing is circulating!':
      'المضخة متوقفة. لا شيء يتدفق!',
  'HABITAT':
      'الموطن',
  'PUMP':
      'المضخة',
  '☀ SOLAR FIELD':
      '☀ حقل الطاقة الشمسية',
  'TEST':
      'اختبار',
  'Water Test':
      'اختبار المياه',
  'GOOD':
      'جيدة',
  'POOR, maintain the recycler':
      'ضعيفة، صُن جهاز التدوير',
  'Status: NO POWER':
      'الحالة: لا توجد طاقة',
  'Status: DEGRADED':
      'الحالة: متدهورة',
  'Status: AUTO':
      'الحالة: تلقائي',
  'Not built yet. Add a unit (2 AP).':
      'لم يُبنَ بعد. أضف وحدة (نقطتا إجراءات).',
  'ADD UNIT':
      'أضف وحدة',
  'Checking NASA space weather...':
      'جارٍ فحص طقس الفضاء من ناسا...',
  'Live NASA data is not available right now (offline or rate limit). The game still works with its own values.':
      'بيانات ناسا المباشرة غير متاحة الآن (لا يوجد اتصال أو تجاوزت الحد المسموح). تعمل اللعبة بقيمها الخاصة.',
  'REAL NASA DATA · DONKI (live)':
      'بيانات ناسا الحقيقية · DONKI (مباشر)',
  'Source: NASA CCMC, ccmc.gsfc.nasa.gov/tools/DONKI. The radiation numbers in the game are game values.':
      'المصدر: مركز ناسا CCMC، ccmc.gsfc.nasa.gov/tools/DONKI. أرقام الإشعاع في اللعبة هي قيم خاصة باللعبة.',
  'The mechanics are based on real NASA missions and research. Specific numbers (percentages, durations, costs) are game values chosen for balance, not NASA data.':
      'تستند آليات اللعبة إلى مهمات وأبحاث حقيقية لناسا. أما الأرقام المحددة (النسب والمدد والتكاليف) فهي قيم وضعناها لتوازن اللعبة وليست بيانات من ناسا.',
  'GOOD TO KNOW':
      'من المفيد أن تعرف',
  'Outpost Theta-9 is a fictional training base.':
      'قاعدة ثيتا-9 قاعدة تدريب خيالية.',
  'The 20-Sol mission is the length of the training scenario (a game value), not a real supply window.':
      'مدة المهمة 20 يومًا شمسيًا هي طول سيناريو التدريب (قيمة في اللعبة)، وليست نافذة إمداد حقيقية.',
  'The habitat shielding levels are a simplified game idea (think of layers of Martian soil). Real research says the Mars atmosphere already cuts most solar-storm doses, and that adding some metal shielding can even raise exposure.':
      'مستويات درع الموطن فكرة مبسطة في اللعبة (تخيّلها طبقات من تربة المريخ). تقول الأبحاث الحقيقية إن غلاف المريخ الجوي يخفف أغلب جرعات العواصف الشمسية، وإن إضافة بعض الدروع المعدنية قد ترفع التعرض.',
  'The 3-D printing story comes from a NASA design competition. It is an idea NASA encouraged, not a printing robot NASA built.':
      'قصة الطباعة ثلاثية الأبعاد مأخوذة من مسابقة تصميم أقامتها ناسا. هي فكرة شجعتها ناسا، وليست روبوت طباعة بنته ناسا.',
  'The water recycler wear and efficiency are game values. Real stations recover about 98% of water today.':
      'تآكل جهاز تدوير المياه وكفاءته قيم خاصة باللعبة. تستعيد المحطات الحقيقية اليوم نحو 98٪ من المياه.',
  'The mold in the crop story happened to flowers, not food crops.':
      'العفن في قصة المحاصيل أصاب الزهور وليس المحاصيل الغذائية.',
  'DUST STORM':
      'عاصفة غبارية',
  'SOLAR vs NUCLEAR POWER':
      'الطاقة الشمسية مقابل النووية',
  'SOLAR FLARE AND RADIATION':
      'التوهج الشمسي والإشعاع',
  'MARS SOLAR CONJUNCTION':
      'اقتران المريخ والشمس',
  'LIFE SUPPORT LEAK':
      'تسرب دعم الحياة',
  'EQUIPMENT MALFUNCTION':
      'عطل المعدات',
  'GREENHOUSE AND CROPS':
      'الصوبة والمحاصيل',
  'WATER RECYCLER':
      'جهاز تدوير المياه',
  'BUILDING THE BASE (STORY)':
      'بناء القاعدة (القصة)',
  'TIME ON MARS':
      'الوقت على المريخ',
  'SPACE WEATHER DATA':
      'بيانات طقس الفضاء',
  'A global dust storm blocked the sun and put the Opportunity rover to sleep. Thin dust left on panels can slow the recovery.':
      'حجبت عاصفة غبارية عالمية الشمس وأدخلت المركبة «أوبورتيونيتي» في سبات. والغبار الرقيق المتبقي على الألواح قد يبطئ التعافي.',
  'Confirms the dust storm event happened.':
      'يؤكد أن العاصفة الغبارية قد حدثت فعلًا.',
  'Nuclear power is more reliable during dust storms for a crewed mission, which is why the Nuclear Unit keeps working.':
      'الطاقة النووية أكثر موثوقية أثناء العواصف الغبارية في المهمات المأهولة، ولهذا تواصل الوحدة النووية العمل.',
  'Solar storms really do raise radiation on the surface of Mars.':
      'العواصف الشمسية ترفع فعلًا مستوى الإشعاع على سطح المريخ.',
  'The thin Mars atmosphere reduces most solar-storm doses. Long-term cosmic rays are the bigger problem.':
      'يقلل غلاف المريخ الرقيق أغلب جرعات العواصف الشمسية. أما الأشعة الكونية طويلة الأمد فهي المشكلة الأكبر.',
  'Earth and Mars end up on opposite sides of the Sun, so engineers pause commands for about two weeks. It happens roughly every two years. The Sol 10 to 12 blackout and the no-repairs rule are game rules.':
      'تصبح الأرض والمريخ على جانبين متقابلين من الشمس، فيوقف المهندسون إرسال الأوامر نحو أسبوعين. يحدث ذلك تقريبًا كل عامين. أما انقطاع الاتصال من اليوم 10 إلى 12 وقاعدة منع الإصلاح فهما من قواعد اللعبة.',
  'The crew closed hatches and used an ultrasonic detector to find a small leak on the ISS. Finding the leak comes before fixing it.':
      'أغلق الطاقم الفتحات واستخدم كاشفًا بالموجات فوق الصوتية للعثور على تسرب صغير في محطة الفضاء الدولية. العثور على التسرب يسبق إصلاحه.',
  'A tiny hole was found and repaired by the crew in 2018.':
      'عثر الطاقم على ثقب صغير وأصلحه في عام 2018.',
  'The ISS oxygen generator shut down, and the crew swapped the faulty part with a spare. That is why repairs use spare parts.':
      'توقف مولد الأكسجين في محطة الفضاء الدولية، فاستبدل الطاقم القطعة المعطوبة بقطعة احتياطية. لهذا تستخدم الإصلاحات قطع غيار.',
  'Over-watered flowers with weak airflow grew mold on the ISS, and an astronaut cleaned it. Fresh food matters because packaged vitamins fade.':
      'نما العفن على زهور رُويت أكثر من اللازم مع ضعف تدفق الهواء في محطة الفضاء الدولية، فنظّفه أحد رواد الفضاء. الغذاء الطازج مهم لأن فيتامينات الأغذية المعبأة تتلاشى.',
  'Confirms the mold happened on the ISS zinnias.':
      'يؤكد أن العفن أصاب زهور الزينيا في محطة الفضاء الدولية.',
  'Mineral buildup clogged the urine processor, and a fix raised water recovery from 70% to 85%. That is why filters need care.':
      'تراكم المعادن وسدّ معالج البول، وأدى الإصلاح إلى رفع استعادة المياه من 70٪ إلى 85٪. لهذا تحتاج الفلاتر إلى عناية.',
  'The ISS now recovers about 98% of its water, and long trips need close to that.':
      'تستعيد محطة الفضاء الدولية الآن نحو 98٪ من مياهها، وتحتاج الرحلات الطويلة إلى ما يقارب ذلك.',
  'The MOXIE experiment on Perseverance made oxygen from the Martian air. A crewed version would be much bigger.':
      'صنعت تجربة «موكسي» على المركبة «برسفيرنس» الأكسجين من هواء المريخ. وستكون النسخة المأهولة أكبر بكثير.',
  'A design competition for 3-D printed Mars habitats. We only use it as inspiration for the story.':
      'مسابقة تصميم لموائل المريخ المطبوعة ثلاثية الأبعاد. نستخدمها فقط مصدر إلهام للقصة.',
  'A Sol (a Martian day) is about 39 minutes and 35 seconds longer than an Earth day.':
      'اليوم الشمسي (يوم المريخ) أطول من يوم الأرض بنحو 39 دقيقة و35 ثانية.',
  'A public database of solar flares and storms. It is research-grade data, not the official forecast.':
      'قاعدة بيانات عامة للتوهجات والعواصف الشمسية. بياناتها بحثية وليست التنبؤ الرسمي.',
};

class _Tpl {
  _Tpl(String en, this.ar)
    : re = RegExp(
        '^${RegExp.escape(en).replaceAll(r'\{\}', '(.+?)')}\$',
        dotAll: true,
      );
  final RegExp re;
  final String ar;
}

/// قوالب فيها أرقام أو أسماء متغيرة: {} في الإنجليزي = {1} {2} ... في العربي.
final List<_Tpl> _templates = [
  _Tpl('Welcome to Mars, {}. This is your base. Keep an eye on the resources, handle any events, and make the right decisions. Your crew is counting on you.', 'مرحبًا بك على المريخ يا {1}. هذه قاعدتك. راقب الموارد، وتعامل مع الأحداث، واتخذ القرارات الصحيحة. طاقمك يعتمد عليك.'),
  _Tpl('A big dust storm is coming around Sol {}, and the Sol 10 to 12 blackout too. Build a Nuclear Unit and bank energy in the battery before then.', 'عاصفة غبارية كبيرة قادمة نحو اليوم الشمسي {1}، وكذلك انقطاع الاتصال من اليوم 10 إلى 12. ابنِ وحدة نووية وخزّن الطاقة في البطارية قبل ذلك.'),
  _Tpl('Energy is short: the panels make {} per Sol but the base needs {}. Match the TILT to the sun angle, or add Solar Panels or a Nuclear Unit.', 'الطاقة ناقصة: تنتج الألواح {1} في اليوم الشمسي بينما تحتاج القاعدة {2}. اضبط الميل على زاوية الشمس، أو أضف ألواحًا شمسية أو وحدة نووية.'),
  _Tpl('Tank level: {} / 100\nRecyclers: {}\nAuto cycle costs: {} energy (you have {})\nAuto cycle gives: +{} water\nFilter condition: {}%\nQuality: {}', 'مستوى الخزان: {1} / 100\nأجهزة التدوير: {2}\nتكلفة الدورة التلقائية: {3} طاقة (لديك {4})\nالدورة التلقائية تعطي: +{5} ماء\nحالة الفلتر: {6}٪\nالجودة: {7}'),
  _Tpl('Four crew drink {} Water a Sol. The recycler runs by itself at the end of the Sol: it spends {} energy and gives +{} water.', 'يشرب أربعة أفراد {1} ماء في اليوم الشمسي. يعمل جهاز التدوير تلقائيًا في نهاية اليوم: يستهلك {2} طاقة ويعطي +{3} ماء.'),
  _Tpl('Oxygen is the most urgent problem: you make {} per Sol but the crew breathes {}. Build another Oxygen Generator.', 'الأكسجين هو المشكلة الأعجل: تنتج {1} في اليوم الشمسي لكن الطاقم يتنفس {2}. ابنِ مولد أكسجين آخر.'),
  _Tpl('No greenhouse yet, Cadet! Plant one. It costs {} water from the tank and the crops take {} Sols to grow.', 'لا توجد صوبة بعد أيها المتدرب! ازرع واحدة. تكلف {1} ماء من الخزان وتحتاج المحاصيل إلى {2} أيام شمسية لتنمو.'),
  _Tpl('There is no food production. Plant a Greenhouse now (it costs {} water); new beds are ripe in {} Sols.', 'لا يوجد إنتاج غذاء. ازرع صوبة الآن (تكلف {1} ماء)؛ وتنضج الأحواض الجديدة بعد {2} أيام شمسية.'),
  _Tpl('Nothing to harvest yet. Press MAINTAIN to water the beds, and tomorrow each ripe bed gives {} food.', 'لا شيء للحصاد بعد. اضغط «صيانة» لسقي الأحواض، وغدًا يعطي كل حوض ناضج {1} غذاء.'),
  _Tpl('Careful: {}. Keep energy for the auto water cycle, water the greenhouse, and check the generators.', 'احذر: {1}. احتفظ بالطاقة لدورة المياه التلقائية، واسقِ الصوبة، وتفقّد المولدات.'),
  _Tpl('A big dust storm hits around Sol {} and the panels almost stop. The nuclear unit keeps producing.', 'عاصفة غبارية كبيرة تضرب نحو اليوم الشمسي {1} وتكاد تتوقف الألواح. وتواصل الوحدة النووية الإنتاج.'),
  _Tpl('Maintain the greenhouse ({} water) to ripen its beds, then harvest +{} food from each one.', 'اعتنِ بالصوبة ({1} ماء) لتنضج أحواضها، ثم احصد +{2} غذاء من كل حوض.'),
  _Tpl('Food will run short: your beds make {} per Sol but the crew eats {}. Plant another bed.', 'سينقص الغذاء: تنتج أحواضك {1} في اليوم الشمسي بينما يأكل الطاقم {2}. ازرع حوضًا آخر.'),
  _Tpl('New recycler online! Each auto cycle now gives more water and costs {} more energy.', 'جهاز تدوير جديد يعمل! كل دورة تلقائية تعطي الآن ماءً أكثر وتكلف {1} طاقة إضافية.'),
  _Tpl('Press MAINTAIN ({} water) to grow the plants. Tap each ripe bed to harvest {} food.', 'اضغط «صيانة» ({1} ماء) لتنمية النباتات. اضغط على كل حوض ناضج لحصاد {2} غذاء.'),
  _Tpl('Congratulations {}! You kept the Theta-9 training outpost alive for all {} Sols.', 'تهانينا يا {1}! حافظت على بقاء قاعدة ثيتا-9 التدريبية طوال {2} يومًا شمسيًا.'),
  _Tpl('Radiation grows {} per Sol. Reach shield level 2 early, or the mission fails.', 'يزداد الإشعاع بمقدار {1} كل يوم شمسي. بلغ مستوى الدرع 2 مبكرًا وإلا فشلت المهمة.'),
  _Tpl('One {} will be removed. This costs {} AP and you do not get anything back.', 'سيتم هدم {1} واحد. يكلف ذلك {2} نقطة إجراءات ولا تسترد شيئًا.'),
  _Tpl('Plant 2 Greenhouses ({} water each). Four crew eat 16 food a Sol.', 'ازرع صوبتين ({1} ماء لكل منهما). يأكل أربعة أفراد 16 وحدة غذاء في اليوم الشمسي.'),
  _Tpl('Latest real solar flare: class {}, peak {}. Location on the Sun: {}.', 'آخر توهج شمسي حقيقي: الفئة {1}، الذروة {2}. الموقع على الشمس: {3}.'),
  _Tpl('The beds are ready! Tap each bed to harvest up to {} food.', 'الأحواض جاهزة! اضغط على كل حوض لحصاد ما يصل إلى {1} غذاء.'),
  _Tpl('+10 food per watered Sol, +6 oxygen once grown ({} Sols)', '+10 غذاء لكل يوم شمسي يُسقى فيه، و+6 أكسجين بعد النمو ({1} أيام شمسية)'),
  _Tpl('Panels and reactors add about {} to the battery each Sol', 'تضيف الألواح والمفاعلات نحو {1} إلى البطارية كل يوم شمسي'),
  _Tpl('Nothing to harvest yet. Tomorrow this bed gives {} food.', 'لا شيء للحصاد بعد. غدًا يعطي هذا الحوض {1} غذاء.'),
  _Tpl('O₂ {}  •  Water {}  •  Food {}  •  Radiation {}  •  Health {}', 'الأكسجين {1}  •  الماء {2}  •  الغذاء {3}  •  الإشعاع {4}  •  الصحة {5}'),
  _Tpl('Radiation reaches 100 in about {} Sols at this rate', 'سيصل الإشعاع إلى 100 خلال نحو {1} يومًا شمسيًا بهذا المعدل'),
  _Tpl('Filters serviced for {} energy. Full output again.', 'تمت صيانة الفلاتر مقابل {1} طاقة. عاد الإنتاج كاملًا.'),
  _Tpl('Generators: {} (+20 oxygen / Sol, 6 energy each)', 'المولدات: {1} (+20 أكسجين / يوم شمسي، 6 طاقة لكل مولد)'),
  _Tpl('Bed {} is still growing ({}%). Be patient, Cadet.', 'الحوض {1} ما زال ينمو ({2}٪). تحلَّ بالصبر أيها المتدرب.'),
  _Tpl('Empty bed. Plant a greenhouse here ({} water).', 'حوض فارغ. ازرع صوبة هنا ({1} ماء).'),
  _Tpl('Plants grown! Tap each bed to harvest {} food.', 'نمت النباتات! اضغط على كل حوض لحصاد {1} غذاء.'),
  _Tpl('New bed planted for {} water! Ripe in {} Sols.', 'تمت زراعة حوض جديد مقابل {1} ماء! ينضج بعد {2} أيام شمسية.'),
  _Tpl('Sol {}: Maintain Water Recycler (-{} energy)', 'اليوم {1}: صيانة جهاز تدوير المياه (-{2} طاقة)'),
  _Tpl('Latest real solar flare: class {}, peak {}.', 'آخر توهج شمسي حقيقي: الفئة {1}، الذروة {2}.'),
  _Tpl('Sol {}: Collect {} energy from the battery', 'اليوم {1}: تحصيل {2} طاقة من البطارية'),
  _Tpl('Sol {}: Water the greenhouse (-{} water)', 'اليوم {1}: ري الصوبة (-{2} ماء)'),
  _Tpl('Plants add +{} oxygen / Sol (health {}%)', 'النباتات تضيف +{1} أكسجين / يوم شمسي (الصحة {2}٪)'),
  _Tpl('Sol {}: Plant Greenhouse (-{} water)', 'اليوم {1}: زراعة صوبة (-{2} ماء)'),
  _Tpl('Rank: {}   •   Sols survived: {}/20', 'الرتبة: {1}   •   الأيام الشمسية التي نجوت فيها: {2}/20'),
  _Tpl('The crew breathes {} oxygen / Sol', 'يستهلك الطاقم {1} أكسجين / يوم شمسي'),
  _Tpl('Units: {} (+12 energy / Sol each)', 'الوحدات: {1} (+12 طاقة / يوم شمسي لكل وحدة)'),
  _Tpl('Radiation builds up by {} per Sol', 'يزداد الإشعاع بمقدار {1} كل يوم شمسي'),
  _Tpl('Your energy counter is full ({}).', 'مخزون الطاقة ممتلئ ({1}).'),
  _Tpl('Empty bed. Plant it for {} water.', 'حوض فارغ. ازرعه مقابل {1} ماء.'),
  _Tpl('Ask Mission Control for advice', 'طلب المشورة من مركز التحكم'),
  _Tpl('DUST STORM: panels at {}% output', 'عاصفة غبارية: الألواح تعمل بنسبة {1}٪'),
  _Tpl('Sol {}: Respond to {} (-{} energy)', 'اليوم {1}: الاستجابة لـ{2} (-{3} طاقة)'),
  _Tpl('Sol {}: Respond to {} (-{} water)', 'اليوم {1}: الاستجابة لـ{2} (-{3} ماء)'),
  _Tpl('Sol {}: Harvest bed {} (+{} food)', 'اليوم {1}: حصاد الحوض {2} (+{3} غذاء)'),
  _Tpl('Sol {}: Gather grass (+{} food)', 'اليوم {1}: جمع العشب (+{2} غذاء)'),
  _Tpl('Total energy income: {} / Sol', 'إجمالي دخل الطاقة: {1} / يوم شمسي'),
  _Tpl('Oxygen from plants: +{} / Sol', 'الأكسجين من النباتات: +{1} / يوم شمسي'),
  _Tpl('Harvested +{} food from bed {}!', 'تم حصاد +{1} غذاء من الحوض {2}!'),
  _Tpl('Harvested +{} food in total!', 'تم حصاد +{1} غذاء في المجموع!'),
  _Tpl('Watered today: {}   Water: {}', 'سُقي اليوم: {1}   الماء: {2}'),
  _Tpl('Maximum {} panels reached.', 'بلغت الحد الأقصى: {1} ألواح.'),
  _Tpl('Auto cost: {} energy / Sol', 'تكلفة الدورة: {1} طاقة / يوم شمسي'),
  _Tpl('Life support failure! {}.', 'فشل دعم الحياة! {1}.'),
  _Tpl('Panels: {} / {} (1 damaged)', 'الألواح: {1} / {2} (لوح واحد متضرر)'),
  _Tpl('Maximum {} units reached.', 'بلغت الحد الأقصى: {1} وحدات.'),
  _Tpl('Maximum {} beds reached.', 'بلغت الحد الأقصى: {1} أحواض.'),
  _Tpl('Not enough {} for this.', 'لا يوجد {1} كافٍ لذلك.'),
  _Tpl('Shielding level: {} / 3', 'مستوى الدرع: {1} / 3'),
  _Tpl('Growth: {}%   Health: {}%', 'النمو: {1}٪   الصحة: {2}٪'),
  _Tpl('Systems need: {} / Sol', 'احتياج الأنظمة: {1} / يوم شمسي'),
  _Tpl('Filter: {}%   Energy: {}', 'الفلتر: {1}٪   الطاقة: {2}'),
  _Tpl('To-do list    sol {}/{}', 'قائمة المهام    اليوم الشمسي {1}/{2}'),
  _Tpl('Energy counter: {} / {}', 'مخزون الطاقة: {1} / {2}'),
  _Tpl('Stored crops: {} food', 'المحاصيل المخزنة: {1} غذاء'),
  _Tpl('Output: {} Energy/Sol', 'الإنتاج: {1} طاقة/يوم شمسي'),
  _Tpl('Ops: {} / Sol ({} crew)', 'الاستهلاك: {1} / يوم شمسي ({2} أفراد)'),
  _Tpl('Auto cycle: +{} water', 'الدورة التلقائية: +{1} ماء'),
  _Tpl('Auto: +{} Water / Sol', 'تلقائي: +{1} ماء / يوم شمسي'),
  _Tpl('Making now: {} / Sol', 'الإنتاج الحالي: {1} / يوم شمسي'),
  _Tpl('Stored charge: {} / {}', 'الشحنة المخزنة: {1} / {2}'),
  _Tpl('MAX REACHED ({} / {})', 'بلغت الحد الأقصى ({1} / {2})'),
  _Tpl('Dust: {}   Health: {}', 'الغبار: {1}   الحالة: {2}'),
  _Tpl('Upgrade habitat', 'ترقية درع الموطن'),
  _Tpl('Balance: {} / Sol', 'الرصيد: {1} / يوم شمسي'),
  _Tpl('Plant health: {}%', 'صحة النباتات: {1}٪'),
  _Tpl('Earth contact: {}', 'الاتصال بالأرض: {1}'),
  _Tpl('BUILD {} — 2 AP', 'بناء {1} — نقطتا إجراءات'),
  _Tpl('Net per Sol: {}', 'الصافي في اليوم الشمسي: {1}'),
  _Tpl('Stored: {} food', 'المخزن: {1} غذاء'),
  _Tpl('Level: {} / 100', 'المستوى: {1} / 100'),
  _Tpl('Sol {}: {} ({} AP)', 'اليوم {1}: {2} ({3} نقطة إجراءات)'),
  _Tpl('+{} more units', '+{1} وحدات إضافية'),
  _Tpl('Respond to {}', 'الاستجابة لـ{1}'),
  _Tpl('CHARGE  {} / {}', 'الشحنة  {1} / {2}'),
  _Tpl('TAP +{} FOOD', 'اضغط +{1} غذاء'),
  _Tpl('Demolish {}?', 'هدم {1}؟'),
  _Tpl('{} reports: {}', '{1} يُبلّغ: {2}'),
  _Tpl('MAINTAIN {}💧', 'صيانة {1}💧'),
  _Tpl('Demolish {}', 'هدم {1}'),
  _Tpl('RECYCLER {}', 'جهاز التدوير {1}'),
  _Tpl('Filter: {}%', 'الفلتر: {1}٪'),
  _Tpl('REPAIR  {}⚡', 'إصلاح  {1}⚡'),
  _Tpl('Status: {}', 'الحالة: {1}'),
  _Tpl('{} ENERGY', '{1} طاقة'),
  _Tpl('BED {} - {}', 'الحوض {1} - {2}'),
  _Tpl('PLANT {}💧', 'زراعة {1}💧'),
  _Tpl('Tilt: {}%', 'الميل: {1}٪'),
  _Tpl('Build {}', 'بناء {1}'),
  _Tpl('{} WATER', '{1} ماء'),
  _Tpl('PANEL {}', 'اللوح {1}'),
  _Tpl('{}  {} / {}', '{1}  {2} / {3}'),
  _Tpl('FIX {}💧', 'إصلاح {1}💧'),
  _Tpl('{} OFF', '{1} متوقف'),
  _Tpl('{} ON', '{1} يعمل'),
  _Tpl('•  {}', '•  {1}'),
];

/// يترجم جزء متغير (اسم حدث، أو قايمة مفصولة بفواصل)
String _tr(String s) {
  final direct = gameText(s);
  if (direct != s) return direct;
  for (final sep in const [', ', '; ']) {
    if (s.contains(sep)) return s.split(sep).map(gameText).join('، ');
  }
  return s;
}
