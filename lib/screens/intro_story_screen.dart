import 'package:flutter/material.dart' hide Text;
import '../widgets/game_text.dart';
import '../audio/audio_service.dart';
import '../game/crew.dart';
import '../game/game_controller.dart';
import '../localization/game_localization.dart';
import '../widgets/crew_avatar.dart';
import '../widgets/smart_asset.dart';
import '../widgets/typewriter_text.dart';
import 'briefing_screen.dart';

/// المقدمة: القائدة نادية بتعرّف نفسها وتعرّف العالم، بعدين اللاعب يكتب اسمه،
/// وبعدين نادية تعرّفه على كريم وأمارة.
class IntroStoryScreen extends StatefulWidget {
  const IntroStoryScreen({super.key});

  @override
  State<IntroStoryScreen> createState() => _IntroStoryScreenState();
}

class _IntroStoryScreenState extends State<IntroStoryScreen> {
  // 0: نادية تعرّف نفسها
  // 1: العالم (المريخ و Sol)
  // 2: المهمة + انقطاع الاتصال
  // 3: اللاعب يكتب اسمه
  // 4: نادية ترحب بيه
  // 5: كريم
  // 6: أمارة
  // 7: نادية تختم وتروح للبريفينج
  int step = 0;
  final TextEditingController nameController = TextEditingController();
  String? nameError; // رسالة الخطأ تحت خانة الاسم
  bool nameTouched = false;

  @override
  void initState() {
    super.initState();
    audio.playMusic('music_briefing');
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  void _next() {
    audio.sfx('ui_tap');
    setState(() => step++);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // الكيبورد مبيصغرش الشاشة ولا بيقص الخلفية
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFF090D16),
      body: Stack(
        children: [
          // خلفية المريخ (نفس خلفية القاعدة) مع تغميق
          Positioned.fill(
            child: Image.asset(
              'assets/images/BaseViewScreen/baseline.jpg',
              fit: BoxFit.cover,
              cacheWidth: decodeSizeFor(context, double.infinity, null).w,
              errorBuilder: (c, o, s) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF3D160F), Color(0xFF090D16)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.45)),
          ),
          // صندوق الحوار بيطلع فوق الكيبورد، والخلفية بتفضل ملء الشاشة
          SafeArea(
            child: LayoutBuilder(
              builder: (context, box) {
                final kb = MediaQuery.viewInsetsOf(context).bottom;
                final maxH = (box.maxHeight - kb - 32).clamp(120.0, 2000.0);
                return Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + kb),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: maxH.toDouble()),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF0D131E,
                          ).withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.cyan.withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                        ),
                        child: SingleChildScrollView(child: _buildStep()),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // تعبير نادية حسب لحظة الحوار
  Widget _nadiaAvatar() {
    const moods = {0: 'Happy', 1: 'Neutral', 2: 'Worried', 3: 'Neutral'};
    return CommanderPortrait(mood: moods[step] ?? 'Happy', size: 64);
  }

  Widget _dialogue({
    required Widget avatar,
    required String title,
    required String text,
    required String button,
    Color buttonColor = Colors.cyan,
  }) {
    return Row(
      children: [
        avatar,
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                gameText(title),
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              TypewriterText(
                text: gameText(text),
                maxLines: 8,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    if (step == 7) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BriefingScreen(),
                        ),
                      );
                    } else {
                      _next();
                    }
                  },
                  child: Text(
                    gameText(button),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// قواعد الاسم: من 2 لـ 16 حرف، حروف (عربي أو إنجليزي) وأرقام ومسافات و - _ .
  /// لازم يبدأ بحرف أو رقم، وفيه حرف واحد على الأقل، ومفيش مسافات مكررة.
  static String? validateCadetName(String raw) {
    final name = raw.trim();
    if (name.isEmpty) return 'Please enter a name to continue.';
    if (name.length < 2) return 'The name must have at least 2 characters.';
    if (name.length > 16) return 'The name can have at most 16 characters.';
    if (!RegExp(
      r'^[\p{L}\p{N}][\p{L}\p{N} _.\-]*$',
      unicode: true,
    ).hasMatch(name)) {
      return 'Use letters, numbers, spaces, - _ . only, and start with a letter or number.';
    }
    if (!RegExp(r'\p{L}', unicode: true).hasMatch(name)) {
      return 'The name must contain at least one letter.';
    }
    if (name.contains(RegExp(r'\s{2,}'))) return 'No double spaces please.';
    return null;
  }

  void _confirmName() {
    final error = validateCadetName(nameController.text);
    if (error != null) {
      audio.sfx('ui_denied', volume: 0.6);
      setState(() {
        nameTouched = true;
        nameError = error;
      });
      return;
    }
    audio.sfx('ui_confirm');
    gameController.setCadetName(nameController.text.trim());
    FocusScope.of(context).unfocus();
    _next();
  }

  Widget _buildStep() {
    final name = gameController.cadetName;
    final nadiaTitle = nadia.label;

    switch (step) {
      case 0:
        return _dialogue(
          avatar: _nadiaAvatar(),
          title: nadiaTitle,
          text:
              'Over here, Cadet! I\'m Commander Nadia. I run Outpost Theta-9, our training base on Mars. '
              'I lead construction and operations, and I\'ll be guiding you.',
          button: 'Next',
        );
      case 1:
        return _dialogue(
          avatar: _nadiaAvatar(),
          title: nadiaTitle,
          text:
              'This is Mars. A day here is called a Sol, and it lasts about 24 hours 39 minutes. '
              'The air is 95% carbon dioxide, so we have to make our own oxygen, water and food.',
          button: 'Next',
        );
      case 2:
        return _dialogue(
          avatar: _nadiaAvatar(),
          title: nadiaTitle,
          text:
              'Our training mission: keep the crew alive for 20 Sols. Every couple of years the Sun '
              'disrupts the radio link between Earth and Mars. In our scenario that blackout starts at '
              'Sol 10 and lasts three Sols, so we are on our own.',
          button: 'Next',
        );
      case 3:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _nadiaAvatar(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gameText('ENTER YOUR CADET NAME:'),
                    style: TextStyle(
                      color: Colors.cyanAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    gameText('First things first. What should we call you?'),
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    maxLength: 16,
                    autofocus:
                        true, // تفعيل إظهار الكيبورد تلقائياً فور دخول هذه الخطوة
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _confirmName(),
                    onChanged: (v) => setState(() {
                      nameTouched = true;
                      nameError = validateCadetName(v);
                    }),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      isDense: true,
                      counterStyle: const TextStyle(color: Colors.white38),
                      errorText: nameTouched && nameError != null
                          ? gameText(nameError!)
                          : null,
                      errorStyle: const TextStyle(color: Colors.redAccent),
                      hintText: gameText('Type your name or callsign...'),
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.black38,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.cyan),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: (nameTouched && nameError != null)
                              ? Colors.redAccent
                              : Colors.cyan,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            validateCadetName(nameController.text) == null
                            ? Colors.amber
                            : Colors.grey,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: _confirmName,
                      child: Text(
                        gameText('Confirm Identity'),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      case 4:
        return _dialogue(
          avatar: _nadiaAvatar(),
          title: nadiaTitle,
          text:
              'Welcome to the crew, $name! Let me introduce the rest of the team.',
          button: 'Meet the crew',
        );
      case 5:
        return _dialogue(
          avatar: const CrewAvatar(member: karim, size: 64),
          title: karim.label,
          text:
              '"Hey, $name! I manage our Solar Panels, Nuclear Reactor, and Batteries. Keep power flowing!"',
          button: 'Next Crewmember',
        );
      case 6:
        return _dialogue(
          avatar: const CrewAvatar(member: amara, size: 64),
          title: amara.label,
          text:
              '"Welcome aboard! I oversee Oxygen generation, Water recycling, and Greenhouse crops."',
          button: 'Next',
        );
      default:
        return _dialogue(
          avatar: _nadiaAvatar(),
          title: nadiaTitle,
          text:
              'That makes four of us, counting you. Let\'s go over the plan before we start.',
          button: 'Mission Briefing',
          buttonColor: Colors.amber,
        );
    }
  }
}
