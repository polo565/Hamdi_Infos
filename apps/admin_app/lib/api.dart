import 'dart:convert';
import 'package:http/http.dart' as http;

/// ⚠️ استبدل هذا برابط النشر (/exec) الخاص بك من Apps Script.
const String kApiUrl =
    'https://script.google.com/macros/s/AKfycbw-tgUtiawUqGKjPZHzKjBwm7rO4HzgI3gUDUSxz2DDSx0WeazuKJJT7X0i2NBhwP63HA/exec';

class AdminApi {
  static String key = '';

  static Future<dynamic> _call(Map<String, dynamic> body) async {
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

  static Future<bool> login(String k) async =>
      (await _call({'action': 'adminLogin', 'key': k})) == true;

  static Future<Map<String, dynamic>> getData() async =>
      Map<String, dynamic>.from(await _call({'action': 'adminGetData', 'key': key}));

  static Future<Map<String, dynamic>> _mut(Map<String, dynamic> body) async {
    body['key'] = key;
    return Map<String, dynamic>.from(await _call(body));
  }

  static Future<Map<String, dynamic>> approveOrder(String id) => _mut({'action': 'adminApproveOrder', 'orderId': id});
  static Future<Map<String, dynamic>> rejectOrder(String id) => _mut({'action': 'adminRejectOrder', 'orderId': id});
  static Future<Map<String, dynamic>> deleteOrder(String id) => _mut({'action': 'adminDeleteOrder', 'orderId': id});
  static Future<Map<String, dynamic>> deleteTab(String id) => _mut({'action': 'adminDeleteTab', 'id': id});
  static Future<Map<String, dynamic>> addTab(Map data) => _mut({'action': 'adminAddTab', 'data': data});
  static Future<Map<String, dynamic>> updateTab(String id, Map data) => _mut({'action': 'adminUpdateTab', 'id': id, 'data': data});
  static Future<Map<String, dynamic>> reorder(List ids) => _mut({'action': 'adminReorder', 'ids': ids});
  static Future<Map<String, dynamic>> saveSettings(Map s) => _mut({'action': 'adminSaveSettings', 'settings': s});
  static Future<Map<String, dynamic>> addCode(String code) => _mut({'action': 'adminAddCode', 'code': code, 'tabId': ''});
  static Future<Map<String, dynamic>> deleteCode(String code) => _mut({'action': 'adminDeleteCode', 'code': code});
  static Future<dynamic> createSubfolder(String name) => _call({'action': 'adminCreateSubfolder', 'key': key, 'name': name});
  static Future<dynamic> deleteSubfolder(String name) => _call({'action': 'adminDeleteSubfolder', 'key': key, 'name': name});

  static String ml(dynamic o, [String lang = 'ar']) {
    if (o == null) return '';
    if (o is String) return o;
    if (o is Map) {
      for (final k in [lang, 'ar', 'en', 'fr']) {
        if (o[k] != null && '${o[k]}'.isNotEmpty) return '${o[k]}';
      }
      for (final v in o.values) {
        if (v != null && '$v'.isNotEmpty) return '$v';
      }
    }
    return '';
  }
}
