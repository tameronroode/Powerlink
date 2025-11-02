import 'package:shared_preferences/shared_preferences.dart';

class Session {
  static const _kToken = 'auth_token';
  static String? _token;

  static Future<void> init() async {
    final sp = await SharedPreferences.getInstance();
    _token = sp.getString(_kToken);
  }

  static String? get token => _token;

  static Future<void> setToken(String token) async {
    _token = token;
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kToken, token);
  }

  static Future<void> clear() async {
    _token = null;
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kToken);
  }
}
