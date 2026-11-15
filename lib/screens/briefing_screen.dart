import 'package:flutter/material.dart' hide Text;
import '../widgets/game_text.dart';
import '../widgets/game_image.dart';
import '../widgets/game_route.dart';
import '../audio/audio_service.dart';
import '../game/game_controller.dart';
import '../localization/game_localization.dart';
import 'base_view_screen.dart';

class BriefingScreen extends StatelessWidget {
  const BriefingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final name = gameController.cadetName;
    final briefingText = gameArabic.value
        ? 'مرحبًا بك في قاعدة ثيتا-9، $name.\n\n'
              'مهمتك هي إبقاء أفراد الطاقم الأربعة على قيد الحياة لمدة 20 يومًا شمسيًا على المريخ.\n\n'
              '• تحصل كل يوم شمسي على 3 نقاط إجراءات (AP)، ولا تتراكم (الحد الأقصى 3). يكلف البناء نقطتي إجراءات، والهدم أو التعامل مع حدث نقطة واحدة.\n'
              '• مولد أكسجين واحد أو جهاز تدوير مياه واحد أو صوبة واحدة لا تكفي لأربعة أشخاص. ضاعف مباني دعم الحياة قبل اليوم الشمسي 10!\n'
              '• يأتي الماء من جهاز التدوير الذي يعمل تلقائيًا في نهاية كل يوم شمسي مقابل الطاقة. اسقِ الصوبة مرة يوميًا واضغط على الأحواض الناضجة للحصاد. راقب السهمين ▲ / ▼ لمعرفة التغييرات المتوقعة.\n'
              '• من اليوم الشمسي 10 إلى 12 ينقطع الاتصال بالأرض بسبب الاقتران الشمسي. لا إصلاحات ولا مساعدة.\n\n'
              'حظًا موفقًا، أيها المتدرب.'
        : 'Welcome to Outpost Theta-9, $name.\n\n'
              'Your objective: keep the 4-person crew alive for 20 Sols on Mars.\n\n'
              '• Every Sol you get 3 Action Points (AP). They do not pile up (max 3). Building costs 2 AP; demolishing and handling an event cost 1 AP.\n'
              '• One Oxygen Generator, Water Recycler or Greenhouse is NOT enough for 4 people. '
              'Double every life-support building before Sol 10!\n'
              '• Water comes from the Water Recycler, which runs a cycle by itself at the end of every Sol (it spends energy). Water the greenhouse once a Sol and tap the ripe beds to harvest. Watch the ▲ / ▼ arrows: they show what will happen at the end of the Sol.\n'
              '• Sol 10 to 12 is Solar Conjunction: Earth contact goes completely dark. No repairs, no help.\n\n'
              'Good luck, Cadet.';

    return SpaceBackground(
      child: Scaffold(
        // الكيبورد مبيصغرش الشاشة ولا بيقص الخلفية
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: const Color(0xFF161B22),
          title: Text(gameText('Mission Briefing')),
          elevation: 0,
          toolbarHeight: 44,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.cyan,
                      child: Icon(Icons.person, color: Colors.black, size: 20),
                    ),
                    SizedBox(width: 12),
                    Text(
                      gameText('Commander Nadia'),
                      style: TextStyle(
                        color: Colors.cyan,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161B22),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        briefingText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    audio.sfx('ui_confirm');
                    Navigator.pushReplacement(
                      context,
                      gameRoute(const BaseViewScreen()),
                    );
                  },
                  child: Text(
                    gameText('Enter Outpost'),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
