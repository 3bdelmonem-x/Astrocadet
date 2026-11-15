import 'package:flutter/material.dart' hide Text;
import '../widgets/game_text.dart';
import '../audio/audio_service.dart';
import '../game/game_controller.dart';
import '../localization/game_localization.dart';
import '../widgets/game_route.dart';
import '../widgets/settings_panel.dart';
import '../widgets/smart_asset.dart';
import '../widgets/tutorial_dialog.dart';
import 'base_view_screen.dart';
import 'intro_story_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  @override
  void initState() {
    super.initState();
    gameArabic.addListener(_refreshLanguage);
    // القائمة الرئيسية: مزيكا القائمة، ومفيش أجواء ولا لوب مؤثرات
    audio.stopJingle();
    audio.stopAmbience();
    audio.stopLoopFx();
    audio.playMusic('music_menu');
  }

  void _refreshLanguage() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    gameArabic.removeListener(_refreshLanguage);
    super.dispose();
  }

  // لو logo_white.png مش موجود، بنحوّل logo.png (أسود على أبيض) لأبيض بفلتر
  static const ColorFilter _whiteLogoFilter = ColorFilter.matrix(<double>[
    0, 0, 0, 0, 255, //
    0, 0, 0, 0, 255, //
    0, 0, 0, 0, 255, //
    -0.2126, -0.7152, -0.0722, 0, 255, //
  ]);

  Widget _logo(BuildContext context) {
    // اللوجو بيصغر على الشاشات القصيرة عشان الزراير الاتنين يتسعوا
    final logoH = (MediaQuery.sizeOf(context).height * 0.36)
        .clamp(100.0, 200.0)
        .toDouble();
    final white = AssetFinder.find(const [''], const ['logo_white']);
    if (white != null) {
      return Image.asset(
        white,
        height: logoH,
        cacheHeight: decodeSizeFor(context, null, logoH).h,
        filterQuality: FilterQuality.medium,
      );
    }
    final black = AssetFinder.find(const [''], const ['logo']);
    if (black != null) {
      return ColorFiltered(
        colorFilter: _whiteLogoFilter,
        child: Image.asset(
          black,
          height: logoH,
          cacheHeight: decodeSizeFor(context, null, logoH).h,
        ),
      );
    }
    return const Text(
      'ASTRO CADET',
      style: TextStyle(
        color: Colors.white,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: 4,
      ),
    );
  }

  /// لعبة جديدة. لو في لعبة محفوظة بنسأل الأول عشان مانمسحهاش بالغلط.
  Future<void> _startNew() async {
    audio.sfx('ui_confirm');
    if (gameController.hasSave) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: const Color(0xFF0D131E),
          title: Text(
            gameText('Start a new game?'),
            style: TextStyle(color: Colors.amber),
          ),
          content: Text(
            gameText(
              'Your saved mission will be deleted. Use CONTINUE if you want to keep it.',
            ),
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                gameText('Cancel'),
                style: TextStyle(color: Colors.cyanAccent),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                gameText('New game'),
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    gameController.newGame();
    Navigator.pushReplacement(context, gameRoute(const IntroStoryScreen()));
  }

  /// يكمّل اللعبة المحفوظة من نفس المكان
  void _continue() {
    if (!gameController.continueGame()) {
      audio.sfx('ui_denied', volume: 0.6);
      setState(() {});
      return;
    }
    audio.sfx('ui_confirm');
    Navigator.pushReplacement(context, gameRoute(const BaseViewScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // الكيبورد مبيصغرش الشاشة ولا بيقص الخلفية
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFF080D25),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // خلفية الفضا بملء الشاشة (space.jpg أو space.png)
          SmartImage(
            folders: const [''],
            names: const ['space'],
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            fallback: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1B1140), Color(0xFF080D25)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // توقيع صغير تحت: اللعبة من صنع Lumera
          const SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(
                  'Made by Lumera',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 9,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _logo(context),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(220, 0),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _startNew,
                    child: Text(
                      gameText('START GAME'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: Colors.white12,
                      disabledForegroundColor: Colors.white38,
                      minimumSize: const Size(220, 0),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: gameController.hasSave ? _continue : null,
                    child: Text(
                      gameText('CONTINUE'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.amber,
                          side: const BorderSide(color: Colors.amber, width: 2),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                        ),
                        onPressed: () {
                          audio.sfx('ui_tap');
                          showTutorial(context);
                        },
                        icon: const Icon(Icons.help_outline, size: 18),
                        label: Text(
                          gameText('HOW TO PLAY'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.cyanAccent,
                          side: const BorderSide(color: Colors.cyan, width: 2),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                        ),
                        onPressed: () {
                          audio.sfx('ui_panel_open');
                          showSettingsPanel(context);
                        },
                        icon: const Icon(Icons.settings, size: 18),
                        label: Text(
                          gameText('SETTINGS'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
