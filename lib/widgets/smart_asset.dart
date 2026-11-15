import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../game/crew.dart';
import '../game/game_engine.dart';
import 'crew_avatar.dart';

/// حجم فك ضغط الصورة: بنفك الصورة على قد حجم عرضها على الشاشة بس، مش حجمها
/// الأصلي. ده بيقلل الذاكرة والمعالج جداً (خصوصاً الخلفيات الكبيرة)،
/// ومبيكبّرش الصورة لو هي أصلاً أصغر.
/// بنرجّع بُعد واحد بس عشان النسبة تفضل زي ما هي.
({int? w, int? h}) decodeSizeFor(
    BuildContext context, double? width, double? height) {
  final mq = MediaQuery.maybeOf(context);
  final dpr = (mq?.devicePixelRatio ?? 2.0).clamp(1.0, 2.5).toDouble();
  if (height != null && height.isFinite) {
    return (w: null, h: (height * dpr).round().clamp(8, 2048).toInt());
  }
  if (width != null) {
    if (width.isFinite) {
      return (w: (width * dpr).round().clamp(8, 2048).toInt(), h: null);
    }
    // ملء الشاشة (خلفية): على قد أطول ضلع في الشاشة
    if (mq != null) {
      final longest = mq.size.longestSide;
      return (w: (longest * dpr).round().clamp(64, 2048).toInt(), h: null);
    }
  }
  return (w: null, h: null);
}

const String kBase = 'BaseViewScreen';
const String kSolar = 'SolarFieldScreen';
const String kGreen = 'GreenhouseScreen';
const String kWater = 'WaterTankScreen';
const List<String> kAllFolders = [kBase, kSolar, kGreen, kWater];

/// بيقرا قايمة كل الصور اللي في المشروع مرة واحدة عند التشغيل، وبعدين بيلاقي
/// أي صورة بالاسم حتى لو الملف اسمه Asset-Solar-Panel-Front أو Solar-Panel-Front.
/// (بيتجاهل الحروف الكبيرة والصغيرة والشرطات والمسافات وكلمة Asset في الأول).
class AssetFinder {
  static final Map<String, List<String>> _byFolder = {};
  static final Map<String, String?> _cache = {};
  static final Set<String> _logged = {};

  static Future<void> init() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      const prefix = 'assets/images/';
      for (final key in manifest.listAssets()) {
        if (!key.startsWith(prefix)) continue;
        final rest = key.substring(prefix.length);
        final slash = rest.lastIndexOf('/');
        final folder = slash < 0 ? '' : rest.substring(0, slash);
        _byFolder.putIfAbsent(folder, () => []).add(key);
      }
      if (kDebugMode) {
        for (final e in _byFolder.entries) {
          debugPrint('[assets] ${e.key}: ${e.value.length} files');
        }
      }
    } catch (e) {
      debugPrint('[assets] manifest load failed: $e');
    }
  }

  static String _norm(String s) {
    var t = s.toLowerCase();
    t = t.replaceAll(RegExp(r'\.(png|jpg|jpeg|webp|gif)$'), '');
    t = t.replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (t.startsWith('asset')) t = t.substring(5);
    return t;
  }

  /// بيرجّع مسار الصورة أو null لو مش موجودة (وبيطبع اسمها في الـ Console).
  static String? find(List<String> folders, List<String> names) {
    final cacheKey = '${folders.join(',')}|${names.join(',')}';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey];

    final wanted = names.map(_norm).toSet();
    String? found;
    for (final folder in folders) {
      final list = _byFolder[folder];
      if (list == null) continue;
      for (final path in list) {
        if (wanted.contains(_norm(path.split('/').last))) {
          found = path;
          break;
        }
      }
      if (found != null) break;
    }
    if (found == null && _logged.add(cacheKey)) {
      debugPrint('[assets] NOT FOUND: ${names.join(' | ')}');
    }
    _cache[cacheKey] = found;
    return found;
  }
}

/// صورة بيتم البحث عنها بالاسم (بيدور في فولدر الشاشة أولاً وبعدين باقي الفولدرات).
/// لو مش لاقيها بيظهر fallback (أو مربع أحمر صغير في وضع التطوير).
class SmartImage extends StatelessWidget {
  final List<String> folders;
  final List<String> names;
  final double? height;
  final double? width;
  final BoxFit fit;
  final Widget? fallback;
  final double? opacity; // شفافية الصورة نفسها من غير saveLayer

  const SmartImage({
    super.key,
    required this.folders,
    required this.names,
    this.height,
    this.width,
    this.fit = BoxFit.contain,
    this.fallback,
    this.opacity,
  });

  SmartImage.one(
    String folder,
    String name, {
    Key? key,
    this.height,
    this.width,
    this.fit = BoxFit.contain,
    this.fallback,
    this.opacity,
  })  : folders = [folder, ...kAllFolders],
        names = [name],
        super(key: key);

  SmartImage.any(
    String folder,
    List<String> alternatives, {
    Key? key,
    this.height,
    this.width,
    this.fit = BoxFit.contain,
    this.fallback,
    this.opacity,
  })  : folders = [folder, ...kAllFolders],
        names = alternatives,
        super(key: key);

  Widget _missing() {
    if (fallback != null) return fallback!;
    if (kDebugMode) {
      return Container(
        width: width ?? 36,
        height: height ?? 36,
        color: Colors.red.withValues(alpha: 0.25),
        child: const Icon(Icons.image_not_supported,
            size: 14, color: Colors.redAccent),
      );
    }
    return SizedBox(width: width, height: height);
  }

  @override
  Widget build(BuildContext context) {
    final path = AssetFinder.find(folders, names);
    if (path == null) return _missing();
    final size = decodeSizeFor(context, width, height);
    return Image.asset(
      path,
      height: height,
      width: width,
      fit: fit,
      cacheWidth: size.w,
      cacheHeight: size.h,
      gaplessPlayback: true,
      filterQuality: FilterQuality.none, // بيكسل آرت حاد
      opacity: opacity == null ? null : AlwaysStoppedAnimation<double>(opacity!),
      errorBuilder: (c, o, s) => _missing(),
    );
  }
}

/// صورة القائدة نادية بتعبير حسب الموقف: Neutral / Happy / Surprised / Worried / Sad
class CommanderPortrait extends StatelessWidget {
  final String mood;
  final double size;

  const CommanderPortrait({super.key, this.mood = 'Neutral', this.size = 70});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1E36),
        border: Border.all(color: Colors.cyan, width: 2),
        borderRadius: BorderRadius.circular(3),
      ),
      child: SmartImage.one(
        kSolar,
        'Commander-$mood',
        fit: BoxFit.cover,
        fallback: CrewAvatar(member: nadia, size: size),
      ),
    );
  }
}

/// تعبير نادية حسب حالة القاعدة
String commanderMood(Game g) {
  final critical = g.oxygen <= 15 ||
      g.water <= 10 ||
      g.food <= 10 ||
      g.radiation >= 80 ||
      g.health <= 40;
  if (critical) return 'Sad';
  if (g.warnings().isNotEmpty) return 'Worried';
  if (g.event != 'None' && g.event != 'Mars Solar Conjunction') {
    return 'Surprised';
  }
  final healthy = g.oxygen >= 50 &&
      g.water >= 50 &&
      g.food >= 50 &&
      g.radiation < 40 &&
      g.health >= 80;
  return healthy ? 'Happy' : 'Neutral';
}
