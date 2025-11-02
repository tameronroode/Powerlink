import 'dart:convert';
import 'package:http/http.dart' as http;

class Api {
  static const String base = 'https://powerlinkbackend.onrender.com/api';
  static String? token;

  static Map<String, String> _headers([bool auth = true]) => {
    'Content-Type': 'application/json',
    if (auth && token != null) 'Authorization': 'Bearer $token',
  };

  static Future<Map<String, dynamic>> get(
    String path, {
    bool auth = true,
  }) async {
    final res = await http.get(
      Uri.parse('$base$path'),
      headers: _headers(auth),
    );
    if (res.statusCode >= 400) {
      throw Exception('GET $path failed: ${res.statusCode} ${res.body}');
    }
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> post(
    String path,
    Map data, {
    bool auth = true,
  }) async {
    final res = await http.post(
      Uri.parse('$base$path'),
      headers: _headers(auth),
      body: jsonEncode(data),
    );
    if (res.statusCode >= 400) {
      throw Exception('POST $path failed: ${res.statusCode} ${res.body}');
    }
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> put(String path, Map data) async {
    final res = await http.put(
      Uri.parse('$base$path'),
      headers: _headers(),
      body: jsonEncode(data),
    );
    if (res.statusCode >= 400) {
      throw Exception('PUT $path failed: ${res.statusCode} ${res.body}');
    }
    return jsonDecode(res.body);
  }

  static Future<void> delete(String path) async {
    final res = await http.delete(Uri.parse('$base$path'), headers: _headers());
    if (res.statusCode >= 400 && res.statusCode != 204) {
      throw Exception('DELETE $path failed: ${res.statusCode} ${res.body}');
    }
  }
}
