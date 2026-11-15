import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// آخر توهج شمسي حقيقي من DONKI (NASA CCMC).
/// مفيش أي أرقام بتتخترع: لو الطلب فشل بيرجّع null واللعبة بتعرض "offline".
class RealFlare {
  final String classType; // مثلاً M2.1
  final String peakTime; // UTC زي ما جه من NASA
  final String? sourceLocation;
  final String? link;
  const RealFlare(this.classType, this.peakTime, this.sourceLocation, this.link);
}

class DonkiService {
  DonkiService._();
  static final DonkiService instance = DonkiService._();

  // DEMO_KEY عليه حد طلبات. للتسليم: اطلب مفتاح مجاني من https://api.nasa.gov/
  static const String apiKey = 'DEMO_KEY';
  static const int lookbackDays = 30;

  RealFlare? _cache;
  bool _loaded = false;
  Future<RealFlare?>? _inflight;

  /// بيجيب البيانات مرة واحدة في الجلسة (بعدها من الكاش).
  Future<RealFlare?> latestFlare() {
    if (_loaded) return Future.value(_cache);
    return _inflight ??= _fetch().whenComplete(() => _inflight = null);
  }

  static String _d(DateTime t) =>
      '${t.year.toString().padLeft(4, '0')}-'
      '${t.month.toString().padLeft(2, '0')}-'
      '${t.day.toString().padLeft(2, '0')}';

  Future<RealFlare?> _fetch() async {
    try {
      final end = DateTime.now().toUtc();
      final start = end.subtract(const Duration(days: lookbackDays));
      final uri = Uri.https('api.nasa.gov', '/DONKI/FLR', {
        'startDate': _d(start),
        'endDate': _d(end),
        'api_key': apiKey,
      });
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body);
      if (data is! List || data.isEmpty) {
        _loaded = true; // اتجاب فعلاً بس مفيش توهجات في الفترة دي
        _cache = null;
        return null;
      }
      Map<String, dynamic>? best;
      for (final e in data) {
        if (e is! Map<String, dynamic>) continue;
        final peak = e['peakTime'] ?? e['beginTime'];
        if (peak is! String || e['classType'] is! String) continue;
        final bp = best == null ? null : (best['peakTime'] ?? best['beginTime']);
        // التواريخ ISO فالمقارنة النصية كفاية
        if (bp == null || peak.compareTo(bp as String) > 0) best = e;
      }
      if (best == null) return null;
      _cache = RealFlare(
        best['classType'] as String,
        (best['peakTime'] ?? best['beginTime']) as String,
        best['sourceLocation'] as String?,
        best['link'] as String?,
      );
      _loaded = true;
      return _cache;
    } catch (_) {
      return null; // مفيش نت / CORS / حد الطلبات: مش مشكلة
    }
  }
}
