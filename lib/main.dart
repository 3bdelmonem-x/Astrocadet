import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'audio/audio_service.dart';
import 'game/game_controller.dart';
import 'localization/game_localization.dart';
import 'screens/main_menu_screen.dart';
import 'widgets/settings_panel.dart';
import 'widgets/smart_asset.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // إخفاء أزرار النظام عشان اللعبة تملا الشاشة
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  // تثبيت الشاشة أفقياً قبل عرض أي شاشة
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  // قراءة قايمة الصور مرة واحدة (عشان نلاقي أي صورة بالاسم)
  await AssetFinder.init();
  await audio.init();
  await initGameLocale();
  // قراءة اللعبة المحفوظة (لو في) عشان زرار CONTINUE
  await gameController.init();
  // كاش الصور: حد أقصى للذاكرة عشان اللعبة متتقلش على الموبايلات الضعيفة
  PaintingBinding.instance.imageCache
    ..maximumSize = 120
    ..maximumSizeBytes = 48 << 20; // 48 ميجا
  runApp(const AstroCadetApp());
}

/// اسم خط البكسل (متعرّف في pubspec.yaml)
const String kPixelFont = 'PixelifySans';

class AstroCadetApp extends StatefulWidget {
  const AstroCadetApp({super.key});

  @override
  State<AstroCadetApp> createState() => _AstroCadetAppState();
}

class _AstroCadetAppState extends State<AstroCadetApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// لما اللاعب يخرج من اللعبة نحفظ مكانه.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        audio.resumeAll();
        break;
      case AppLifecycleState.inactive:
        gameController.saveNow();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        gameController.saveNow();
        audio.pauseAll();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final base = ThemeData.dark();
    return MaterialApp(
      title: 'AstroCadet',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        scaffoldBackgroundColor: const Color(0xFF090D16),
        primaryColor: Colors.cyan,
        // خط البكسل في كل النصوص (الأزرار، الحوارات، حقول الكتابة...)
        textTheme: base.textTheme.apply(fontFamily: kPixelFont),
        primaryTextTheme: base.primaryTextTheme.apply(fontFamily: kPixelFont),
      ),
      // حجم الخط في اللعبة كلها (بيتغير من نافذة الإعدادات)
      builder: (context, child) => ValueListenableBuilder<double>(
        valueListenable: textScale,
        builder: (context, scale, _) => ValueListenableBuilder<bool>(
          valueListenable: gameArabic,
          builder: (context, arabic, _) => Directionality(
            textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
            child: MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        ),
      ),
      home: const MainMenuScreen(),
    );
  }
}
