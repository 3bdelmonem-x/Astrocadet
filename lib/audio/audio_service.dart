import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../game/game_engine.dart';

/// محرك الصوت الوحيد في اللعبة (حسب AstroCadet_Sound_Design.md).
/// الشاشات مبتلمسش اللاعبين مباشرة: بتنادي audio.sfx('ui_tap') وخلاص.
///
/// الملفات بتتلاقي بالاسم من أي فولدر جوه assets/audio/ وبأي امتداد
/// (wav / mp3 / ogg)، والحروف الكبيرة والمسافات والشرطات مش فارقة.
/// يعني لو حولتي ملف من wav لـ mp3 مفيش حاجة في الكود بتتغير.

/// أسماء بديلة: لو الاسم الأول مش موجود بيجرب اللي بعده.
/// عدّلي الترتيب هنا لو عايزة تختاري ملف تاني (مثلاً jingle_lose).
const Map<String, List<String>> _aliases = {
  // مزيكا (الأسماء الأخيرة في كل قايمة هي اللي موجودة دلوقتي في الدرايف)
  'music_menu': ['music_menu', 'start_menu'],
  'music_briefing': ['music_briefing', 'start_menu'],
  'music_base_calm': ['music_base_calm', 'start_menu'],
  'music_base_tense': ['music_base_tense', 'music_base_calm', 'start_menu'],
  'music_final_stretch': [
    'music_final_stretch',
    'music_base_tense',
    'music_base_calm',
    'start_menu',
  ],
  'music_conjunction': ['music_conjunction'],
  'jingle_win': ['jingle_win', 'Victory!', 'win 1'],
  'jingle_lose': ['jingle_lose', 'lose music 3 - 1_0', 'game over 8-bit'],
  'amb_mars_wind': ['amb_mars_wind', 'wind1'],
  // لحظات اليوم
  'sol_new': ['sol_new', 'sol_start'],
  'report_row': ['report_row', 'ui_hover_select'],
  'event_alert': ['event_alert', 'event_spawn', 'anomaly_alert'],
  'resource_low': ['resource_low', 'anomaly_alert'],
};

/// صوت كل حدث (بيتشغل بعد صافرة الإنذار بثانية)
const Map<String, String> _eventSfx = {
  'Solar Flare': 'event_solar_flare',
  'Life Support Leak': 'event_leak',
  'Equipment Malfunction': 'event_equipment',
  'Crop Contamination': 'event_crop',
  'Water System Strain': 'event_water',
};

class AudioService extends ChangeNotifier {
  static const bool _enabled = true;

  final Map<String, String> _files = {};
  final Set<String> _warned = {};

  final List<AudioPlayer> _pool = [];
  int _poolIdx = 0;
  final Map<AudioPlayer, double> _lastVol = {};
  final Map<AudioPlayer, double> _lastRate = {};

  AudioPlayer? _music;
  AudioPlayer? _amb;
  AudioPlayer? _loopFx;
  AudioPlayer? _jingle;

  bool _ready = false;
  bool _paused = false; // اللعبة في الباك جراوند: كل الصوت واقف
  final Set<AudioPlayer> _wasPlaying = {};
  bool sfxMuted = false;
  bool musicMuted = false;

  // المزيكا
  String? _musicPath;
  int _musicToken = 0;
  double _musicVol = 0;
  double _duck = 1;
  double get _musicTarget => 0.35 * _duck;

  String? _ambPath;
  String? _loopFxPath;
  Timer? _jingleTimer;
  DateTime _alarmFree = DateTime(2000);

  // ------------------------------------------------------------------
  // تجهيز
  // ------------------------------------------------------------------
  static String _norm(String s) {
    var t = s.toLowerCase();
    t = t.replaceAll(RegExp(r'\.(wav|mp3|ogg|m4a|aac)$'), '');
    return t.replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  Future<void> init() async {
    if (!_enabled) return;
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      const prefix = 'assets/audio/';
      for (final key in manifest.listAssets()) {
        if (!key.startsWith(prefix)) continue;
        final lower = key.toLowerCase();
        final isAudio =
            lower.endsWith('.wav') ||
            lower.endsWith('.mp3') ||
            lower.endsWith('.ogg') ||
            lower.endsWith('.m4a') ||
            lower.endsWith('.aac');
        if (!isAudio) continue;
        final name = _norm(key.split('/').last);
        final path = key.substring(
          'assets/'.length,
        ); // AssetSource بيضيف assets/
        // لو الملف موجود wav و mp3 مع بعض نفضل الـ mp3 (أخف)
        if (!_files.containsKey(name) || lower.endsWith('.mp3')) {
          _files[name] = path;
        }
      }
      debugPrint('[audio] ${_files.length} sound files found');

      for (var i = 0; i < 4; i++) {
        final p = AudioPlayer();
        await p.setPlayerMode(PlayerMode.lowLatency);
        _pool.add(p);
      }
      _music = AudioPlayer();
      _amb = AudioPlayer();
      _loopFx = AudioPlayer();
      _jingle = AudioPlayer();
      _ready = true;
    } catch (e) {
      debugPrint('[audio] init failed: $e');
    }
  }

  String? _path(String id) {
    final names = _aliases[id] ?? [id];
    for (final n in names) {
      final p = _files[_norm(n)];
      if (p != null) return p;
    }
    if (_warned.add(id)) debugPrint('[audio] MISSING sound: $id');
    return null;
  }

  // ------------------------------------------------------------------
  // مؤثرات قصيرة
  // ------------------------------------------------------------------
  void sfx(String id, {double volume = 0.7, double rate = 1.0}) {
    if (!_ready || sfxMuted || _paused) return;
    final path = _path(id);
    if (path == null) return;
    final p = _pool[_poolIdx++ % _pool.length];
    _fire(p, path, volume, rate);
  }

  void _fire(AudioPlayer p, String path, double volume, double rate) {
    unawaited(
      (() async {
        try {
          final v = volume.clamp(0.0, 1.0).toDouble();
          if (_lastVol[p] != v) {
            _lastVol[p] = v;
            await p.setVolume(v);
          }
          final r =
              (rate * 20).round() / 20; // نقرّب النغمة عشان نقلل الاستدعاءات
          if (_lastRate[p] != r) {
            _lastRate[p] = r;
            await p.setPlaybackRate(r);
          }
          await p.play(AssetSource(path));
        } catch (e) {
          debugPrint('[audio] play failed: $e');
        }
      })(),
    );
  }

  /// صوت بعد تأخير (بالمللي ثانية)
  void sfxLater(String id, int ms, {double volume = 0.7, double rate = 1.0}) {
    Timer(
      Duration(milliseconds: ms),
      () => sfx(id, volume: volume, rate: rate),
    );
  }

  /// إنذارات: مبتتشغلش اتنين مع بعض، كل واحد بيستنى ثانية بعد اللي قبله.
  void alarm(String id) {
    final now = DateTime.now();
    final start = _alarmFree.isAfter(now) ? _alarmFree : now;
    _alarmFree = start.add(const Duration(milliseconds: 1200));
    final delay = start.difference(now);
    if (delay <= Duration.zero) {
      sfx(id);
    } else {
      Timer(delay, () => sfx(id));
    }
  }

  /// صوت الكلام (blip) لكل شخصية: بيتغير نغمته ±5% عشان مايبقاش روبوتي.
  /// mood: موجب = أعلى شوية (قلقان)، سالب = أوطى (حزين)
  // ------------------------------------------------------------------
  // مزيكا
  // ------------------------------------------------------------------
  Future<void> playMusic(String id) async {
    if (!_ready) return;
    final path = _path(id);
    if (path == _musicPath) return; // نفس المقطع شغال، مانعيدوش
    _musicPath = path;
    if (path == null) {
      _musicToken++;
      unawaited(_music?.stop());
      return;
    }
    if (musicMuted) return;
    unawaited(_switchMusic(path));
  }

  Future<void> _fade(
    AudioPlayer? p,
    double from,
    double to,
    int ms,
    int token, {
    bool isMusic = true,
  }) async {
    if (p == null) return;
    const steps = 8;
    for (var i = 1; i <= steps; i++) {
      if (isMusic && token != _musicToken) return;
      final v = (from + (to - from) * i / steps).clamp(0.0, 1.0).toDouble();
      try {
        await p.setVolume(v);
      } catch (_) {}
      if (isMusic) _musicVol = v;
      await Future<void>.delayed(Duration(milliseconds: ms ~/ steps));
    }
  }

  Future<void> _switchMusic(String path) async {
    final token = ++_musicToken;
    final m = _music;
    if (m == null) return;
    if (_musicVol > 0.01) await _fade(m, _musicVol, 0, 350, token);
    if (token != _musicToken) return;
    try {
      await m.stop();
      await m.setReleaseMode(ReleaseMode.loop);
      await m.setVolume(0);
      _musicVol = 0;
      await m.play(AssetSource(path));
      if (_paused) {
        await m.pause();
        _wasPlaying.add(m);
      }
    } catch (e) {
      debugPrint('[audio] music failed: $e');
    }
    await _fade(m, 0, _musicTarget, 600, token);
  }

  /// بيوطّي المزيكا (أثناء كارت الحدث) أو يرجعها
  void duck(bool on) {
    _duck = on ? 0.15 / 0.35 : 1.0;
    if (_musicPath != null && !musicMuted && _music != null) {
      _musicVol = _musicTarget;
      unawaited(_music!.setVolume(_musicTarget));
    }
  }

  // ------------------------------------------------------------------
  // أجواء (ambience) ولوب مؤثرات (عاصفة / انقطاع الاتصال)
  // ------------------------------------------------------------------
  Future<void> _startLoop(AudioPlayer? p, String path, double volume) async {
    if (p == null) return;
    try {
      await p.stop();
      await p.setReleaseMode(ReleaseMode.loop);
      await p.setVolume(volume);
      await p.play(AssetSource(path));
      if (_paused) {
        await p.pause();
        _wasPlaying.add(p);
      }
    } catch (e) {
      debugPrint('[audio] loop failed: $e');
    }
  }

  void startAmbience(String id) {
    if (!_ready) return;
    final path = _path(id);
    if (path == null || path == _ambPath) return;
    _ambPath = path;
    if (musicMuted) return;
    unawaited(_startLoop(_amb, path, 0.2));
  }

  void stopAmbience() {
    _ambPath = null;
    unawaited(_amb?.stop());
  }

  void startLoopFx(String id, {double volume = 0.35}) {
    if (!_ready) return;
    final path = _path(id);
    if (path == null || path == _loopFxPath) return;
    _loopFxPath = path;
    if (sfxMuted) return;
    unawaited(_startLoop(_loopFx, path, volume));
  }

  void stopLoopFx() {
    _loopFxPath = null;
    unawaited(_loopFx?.stop());
  }

  /// جنجل الفوز/الخسارة: بيوقف المزيكا والأجواء ويشغل المقطع لحد maxSeconds
  Future<void> playJingle(String id, {int maxSeconds = 9}) async {
    if (!_ready) return;
    stopAmbience();
    stopLoopFx();
    _musicPath = null;
    _musicToken++;
    unawaited(_music?.stop());
    final path = _path(id);
    if (path == null || sfxMuted) return;
    final j = _jingle;
    if (j == null) return;
    try {
      await j.stop();
      await j.setReleaseMode(ReleaseMode.release);
      await j.setVolume(0.8);
      await j.play(AssetSource(path));
    } catch (e) {
      debugPrint('[audio] jingle failed: $e');
    }
    _jingleTimer?.cancel();
    _jingleTimer = Timer(Duration(seconds: maxSeconds), () {
      unawaited(j.stop());
    });
  }

  void stopJingle() {
    _jingleTimer?.cancel();
    unawaited(_jingle?.stop());
  }

  // ------------------------------------------------------------------
  // الباك جراوند: لما اللاعب يخرج من اللعبة كل الأصوات بتقف (توفير بطارية)
  // ------------------------------------------------------------------
  Future<void> pauseAll() async {
    if (!_ready || _paused) return;
    _paused = true;
    _wasPlaying.clear();
    // الجنجل (فوز/خسارة) بنوقفه خالص بدل ما نستناه
    _jingleTimer?.cancel();
    unawaited(_jingle?.stop());
    for (final p in [_music, _amb, _loopFx]) {
      if (p == null) continue;
      try {
        if (p.state == PlayerState.playing) {
          _wasPlaying.add(p);
          await p.pause();
        }
      } catch (e) {
        debugPrint('[audio] pause failed: $e');
      }
    }
  }

  Future<void> resumeAll() async {
    if (!_ready || !_paused) return;
    _paused = false;
    final toResume = _wasPlaying.toList();
    _wasPlaying.clear();
    for (final p in toResume) {
      try {
        await p.resume();
      } catch (e) {
        debugPrint('[audio] resume failed: $e');
      }
    }
  }

  // ------------------------------------------------------------------
  // كتم
  // ------------------------------------------------------------------
  void toggleSfx() {
    sfxMuted = !sfxMuted;
    if (sfxMuted) stopLoopFx();
    notifyListeners();
  }

  void toggleMusic() {
    musicMuted = !musicMuted;
    if (musicMuted) {
      _musicToken++;
      unawaited(_music?.stop());
      unawaited(_amb?.stop());
    } else {
      final m = _musicPath;
      if (m != null) unawaited(_switchMusic(m));
      final a = _ambPath;
      if (a != null) unawaited(_startLoop(_amb, a, 0.2));
    }
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // لحظات اللعبة (بتتنادى من الشاشات في الوقت المناسب)
  // ------------------------------------------------------------------

  /// تقرير الصبح فتح: شروق، مزيكا حسب الحالة، لوب العاصفة/الانقطاع، إنذار الموارد
  void onMorning(Game g) {
    sfx('sol_new');
    if (g.sol == 10) sfxLater('conjunction_start', 900);
    if (g.sol == 13) sfxLater('conjunction_end', 900);
    if (g.greenhouseBuildSols.any((s) => g.sol - s == greenhouseGrowTime)) {
      sfxLater('greenhouse_ready', 1000);
    }
    syncMusic(g);

    if (g.conjunction) {
      startLoopFx('conjunction_loop', volume: 0.2);
    } else if (g.event == 'Dust Storm') {
      startLoopFx('event_dust_storm', volume: 0.35);
    } else {
      stopLoopFx();
    }

    // إنذار الموارد بعد ثانيتين (ومش على صافرة الحدث لأن alarm() بيرتبهم)
    Timer(const Duration(milliseconds: 2000), () {
      final critical = g.oxygen < 10 || g.health < 30;
      final low =
          g.oxygen <= 25 || g.water <= 20 || g.food <= 20 || g.radiation >= 60;
      if (g.isOver) return;
      if (critical) {
        alarm('resource_critical');
      } else if (low) {
        alarm('resource_low');
      }
    });
  }

  /// المزيكا حسب الحالة: انقطاع اتصال / آخر مرحلة / توتر / هادية
  void syncMusic(Game g) {
    final tense =
        (g.event != 'None' && g.event != 'Mars Solar Conjunction') ||
        g.warnings().isNotEmpty;
    final String id = g.conjunction
        ? 'music_conjunction'
        : (g.sol >= 16
              ? 'music_final_stretch'
              : (tense ? 'music_base_tense' : 'music_base_calm'));
    unawaited(playMusic(id));
    startAmbience('amb_mars_wind');
  }

  /// لما اللاعب يكمل لعبة محفوظة (من غير تقرير الصبح): نرجّع الأجواء بس
  void onResumeGame(Game g) {
    syncMusic(g);
    if (g.conjunction) {
      startLoopFx('conjunction_loop', volume: 0.2);
    } else if (g.event == 'Dust Storm') {
      startLoopFx('event_dust_storm', volume: 0.35);
    } else {
      stopLoopFx();
    }
  }

  /// كارت الحدث فتح
  void onEventCard(String event) {
    duck(true);
    alarm('event_alert');
    final id = _eventSfx[event];
    if (id != null) sfxLater(id, 1000);
  }

  void endEventCard(Game g) {
    duck(false);
    syncMusic(g);
  }

  /// بعد ما اليوم خلص وقبل تقرير آخر اليوم
  void afterSol(Game g) {
    final ignored =
        g.lastEvent != 'None' &&
        g.lastEvent != 'Mars Solar Conjunction' &&
        !g.mitigated;
    if (ignored) {
      sfxLater('event_ignored', 300);
    }
    if (g.oxygenRunning < g.buildings['Oxygen Generator']!) {
      sfxLater('power_failure', ignored ? 1400 : 300);
    }
  }
}

/// نسخة واحدة مشتركة في اللعبة كلها
final AudioService audio = AudioService();
