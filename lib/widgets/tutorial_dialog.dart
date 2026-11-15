import 'package:flutter/material.dart' hide Text;
import 'game_text.dart';
import '../game/game_engine.dart';
import '../localization/game_localization.dart';
import 'pixel_ui.dart';

class _Slide {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  const _Slide(this.icon, this.color, this.title, this.body);
}

final List<_Slide> _slides = [
  const _Slide(
    Icons.flag,
    Colors.cyanAccent,
    'YOUR MISSION',
    'Keep the 4 crew members alive for $missionLength Sols on Mars.\n\n'
        'A Sol is one Martian day. In each Sol you manage the base, then press END SOL and see what happened.\n\n'
        'You lose if Oxygen reaches 0, Radiation reaches 100, or Crew Health reaches 0.',
  ),
  const _Slide(
    Icons.repeat,
    Colors.amber,
    'YOUR ROUTINE EVERY SOL',
    '1. SOLAR FIELD: tap the battery to collect energy. Turn the TILT slider to the sun angle for more.\n'
        '2. WATER TANK: the recycler runs by itself at the end of every Sol and turns energy into water.\n'
        '3. GREENHOUSE: tap the ripe beds to harvest food.\n'
        '4. BASE: build with your Action Points.\n'
        '5. Press END SOL.',
  ),
  const _Slide(
    Icons.speed,
    Colors.lightBlueAccent,
    'THE TOP BAR',
    'Oxygen, Energy, Water, Food, Radiation and Crew Health.\n\n'
        'The small arrows and numbers show what will happen at the end of this Sol if you do nothing else (for example ▼-12).\n\n'
        'Energy shows your counter and the battery charge next to it.',
  ),
  const _Slide(
    Icons.bolt,
    Colors.amber,
    'ACTION POINTS (AP)',
    'You get $dailyActionPoints AP every Sol (max $actionPointCap, they do not pile up).\n\n'
        'Building costs 2 AP. Demolishing (trash icon) and advice cost 1 AP.\n\n'
        'Planting costs water. Auto water cycles and filter repairs cost energy, not AP.',
  ),
  const _Slide(
    Icons.checklist,
    Colors.greenAccent,
    'WHAT TO BUILD FIRST',
    '1. A second Oxygen Generator.\n'
        '2. Habitat shielding (radiation grows fast without it).\n'
        '3. Solar panels (4 or more) so energy is enough.\n'
        '4. A second Water Recycler, then 2 Greenhouses.\n'
        '5. A Nuclear Unit before Sol $stormSol.',
  ),
  const _Slide(
    Icons.warning_amber,
    Colors.redAccent,
    'EVENTS AND THE BLACKOUT',
    'Events pop up in the morning. Tap the Current Event box to react.\n\n'
        'Sols 10 to 12: Earth contact goes dark. No help and no repairs.\n\n'
        'Around Sol $stormSol a long dust storm stops the solar panels. Be ready.',
  ),
];

final List<_Slide> _arabicSlides = [
  _Slide(
    Icons.flag,
    Colors.cyanAccent,
    'مهمتك',
    'أبقِ أفراد الطاقم الأربعة على قيد الحياة لمدة $missionLength يومًا شمسيًا على المريخ.\n\n'
        'اليوم الشمسي هو يوم على المريخ. في كل يوم تدير القاعدة، ثم تنهي اليوم لترى ما حدث.\n\n'
        'تخسر إذا وصل الأكسجين إلى 0 أو الإشعاع إلى 100 أو صحة الطاقم إلى 0.',
  ),
  _Slide(
    Icons.repeat,
    Colors.amber,
    'روتينك كل يوم شمسي',
    '1. حقل الطاقة الشمسية: اضغط على البطارية لتحصيل الطاقة، واضبط الميل نحو زاوية الشمس لزيادة الإنتاج.\n'
        '2. خزان المياه: يعمل جهاز التدوير تلقائيًا في نهاية كل يوم شمسي ويحوّل الطاقة إلى ماء.\n'
        '3. الصوبة الزراعية: اضغط على الأحواض الناضجة لحصاد الطعام.\n'
        '4. القاعدة: ابنِ باستخدام نقاط الإجراءات.\n'
        '5. أنهِ اليوم الشمسي.',
  ),
  _Slide(
    Icons.speed,
    Colors.lightBlueAccent,
    'الشريط العلوي',
    'الأكسجين والطاقة والماء والغذاء والإشعاع وصحة الطاقم.\n\n'
        'توضح الأسهم والأرقام الصغيرة ما سيحدث في نهاية اليوم إذا لم تقم بأي إجراء آخر.\n\n'
        'يعرض مؤشر الطاقة مخزونك وشحنة البطارية بجانبه.',
  ),
  _Slide(
    Icons.bolt,
    Colors.amber,
    'نقاط الإجراءات',
    'تحصل على $dailyActionPoints نقاط إجراءات كل يوم شمسي (بحد أقصى $actionPointCap، ولا تتراكم).\n\n'
        'يكلف البناء نقطتي إجراءات. يكلف الهدم وطلب المشورة نقطة واحدة.\n\n'
        'تستهلك زراعة الصوبة الماء. وتستهلك دورات المياه التلقائية وإصلاح الفلاتر الطاقة، لا نقاط الإجراءات.',
  ),
  _Slide(
    Icons.checklist,
    Colors.greenAccent,
    'ما الذي تبنيه أولًا؟',
    '1. مولد أكسجين ثانٍ.\n'
        '2. درع للموطن، فالإشعاع يرتفع سريعًا من دونه.\n'
        '3. ألواح شمسية (4 على الأقل) لتوفير الطاقة.\n'
        '4. جهاز تدوير مياه ثانٍ، ثم صوبتان زراعيتان.\n'
        '5. ابنِ وحدة نووية قبل اليوم الشمسي $stormSol.',
  ),
  _Slide(
    Icons.warning_amber,
    Colors.redAccent,
    'الأحداث وانقطاع الاتصالات',
    'تظهر الأحداث صباحًا. اضغط على صندوق الحدث الحالي للاستجابة.\n\n'
        'من اليوم الشمسي 10 إلى 12 ينقطع الاتصال بالأرض. لا مساعدة ولا إصلاحات.\n\n'
        'توقّع عاصفة غبارية طويلة قرب اليوم الشمسي $stormSol، وستوقف الألواح الشمسية. استعد لها.',
  ),
];

/// شرح اللعبة (بيظهر أول مرة، ومن الإعدادات ومن القايمة الرئيسية)
Future<void> showTutorial(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      int page = 0;
      return StatefulBuilder(
        builder: (context, setState) {
          final slides = gameArabic.value ? _arabicSlides : _slides;
          final s = slides[page];
          final last = page == slides.length - 1;
          final maxH = MediaQuery.of(context).size.height * 0.92;
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(12),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 560, maxHeight: maxH),
              child: PixelPanel(
                borderColor: s.color,
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(s.icon, color: s.color, size: 26),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            s.title,
                            style: TextStyle(
                              color: s.color,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        Text(
                          '${page + 1} / ${slides.length}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Text(
                          s.body,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        PixelButton(
                          label: 'SKIP',
                          color: Colors.white54,
                          height: 30,
                          onTap: () => Navigator.pop(dialogContext),
                        ),
                        const Spacer(),
                        if (page > 0)
                          PixelButton(
                            label: 'BACK',
                            height: 30,
                            onTap: () => setState(() => page--),
                          ),
                        const SizedBox(width: 8),
                        PixelButton(
                          label: last ? 'START PLAYING' : 'NEXT',
                          color: Colors.amber,
                          height: 30,
                          sound: 'ui_confirm',
                          onTap: () {
                            if (last) {
                              Navigator.pop(dialogContext);
                            } else {
                              setState(() => page++);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
