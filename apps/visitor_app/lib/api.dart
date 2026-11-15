import 'dart:convert';
import 'package:http/http.dart' as http;

/// ⚠️ استبدل هذا برابط النشر (/exec) الخاص بك من Apps Script.
const String kApiUrl =
    'https://script.google.com/macros/s/AKfycbw-tgUtiawUqGKjPZHzKjBwm7rO4HzgI3gUDUSxz2DDSx0WeazuKJJT7X0i2NBhwP63HA/exec';

class Api {
  static Future<dynamic> call(Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse(kApiUrl),
      headers: {'Content-Type': 'text/plain;charset=utf-8'},
      body: jsonEncode(body),
    );
    if (res.statusCode < 200 || res.statusCode >= 400) {
      throw Exception('HTTP ${res.statusCode}');
    }
    final j = jsonDecode(res.body);
    if (j is Map && j['ok'] == true) return j['data'];
    throw Exception((j is Map ? j['error'] : null) ?? 'error');
  }

  static Future<Map<String, dynamic>> getPublicData() async =>
      Map<String, dynamic>.from(await call({'action': 'getPublicData'}));

  static Future<Map<String, dynamic>> getLockedContent(String id, String code) async =>
      Map<String, dynamic>.from(await call({'action': 'getLockedContent', 'id': id, 'code': code}));

  static Future<Map<String, dynamic>> createOrder(Map<String, dynamic> data) async =>
      Map<String, dynamic>.from(await call({'action': 'createOrder', 'data': data}));
}

/// حالة الزائر (اللغة + البلدان).
class AppState {
  static String lang = 'ar';
  static String origin = '';
  static String current = '';
  static Map<String, dynamic>? data; // {settings, tabs}

  static Map<String, dynamic> get settings =>
      Map<String, dynamic>.from(data?['settings'] ?? {});
  static List<dynamic> get tabs => List<dynamic>.from(data?['tabs'] ?? []);

  /// اختيار النص حسب اللغة مع احتياطي.
  static String pick(dynamic o) {
    if (o == null) return '';
    if (o is String) return o;
    if (o is Map) {
      for (final k in [lang, 'en', 'fr', 'ar']) {
        final v = o[k];
        if (v != null && '$v'.isNotEmpty) return '$v';
      }
      for (final v in o.values) {
        if (v != null && '$v'.isNotEmpty) return '$v';
      }
    }
    return '';
  }

  static bool matchCountry(dynamic c) {
    final cc = (c ?? '').toString();
    if (current.isEmpty) return true;
    if (current == 'OTHER') return cc.isEmpty;
    return cc.isEmpty || cc == current;
  }

  static String countryLabel(String code) {
    for (final c in (settings['countries'] ?? [])) {
      if (c['code'] == code) return pick(c['label']);
    }
    return code;
  }
}
