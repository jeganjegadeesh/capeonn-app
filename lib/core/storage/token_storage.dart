import 'package:shared_preferences/shared_preferences.dart';

/// Keeps the API auth token persistently across launches.
/// Uses SharedPreferences which works reliably across Windows, Web, Android, iOS and macOS
/// without native ATL C++ compilation dependencies.
class TokenStorage {
  TokenStorage({SharedPreferences? preferences}) : _prefs = preferences;

  static const _key = 'capeonn_auth_token';
  final SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async => _prefs ?? await SharedPreferences.getInstance();

  Future<String?> read() async {
    final prefs = await _getPrefs();
    return prefs.getString(_key);
  }

  Future<void> write(String token) async {
    final prefs = await _getPrefs();
    await prefs.setString(_key, token);
  }

  Future<void> clear() async {
    final prefs = await _getPrefs();
    await prefs.remove(_key);
  }

  Future<String?> readKey(String key) async {
    final prefs = await _getPrefs();
    return prefs.getString(key);
  }

  Future<void> writeKey(String key, String value) async {
    final prefs = await _getPrefs();
    await prefs.setString(key, value);
  }

  Future<void> deleteKey(String key) async {
    final prefs = await _getPrefs();
    await prefs.remove(key);
  }
}
