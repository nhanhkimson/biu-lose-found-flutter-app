import 'dart:convert';

import 'package:beltei_app/data/models/app_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists Bearer session token and user profile for API auth.
class SessionStore {
  static const _tokenKey = 'api_session_token';
  static const _userKey = 'api_user_json';
  static const _loggedInKey = 'logged_in';
  static const _themeModeKey = 'theme_mode';

  Future<void> saveSession({
    required String sessionToken,
    required AppUser user,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, sessionToken);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    await prefs.setBool(_loggedInKey, true);
  }

  Future<String?> get sessionToken async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<AppUser?> get user async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null) return null;
    return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveUser(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<bool> get isLoggedIn async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool(_loggedInKey) ?? false;
    if (!loggedIn) return false;
    final token = prefs.getString(_tokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.setBool(_loggedInKey, false);
  }

  Future<void> saveThemeMode(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, value);
  }

  Future<String?> get themeMode async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeModeKey);
  }
}
