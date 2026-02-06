import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const _key = 'inventory_user';
  static const _selectedProjectKey = 'selected_project_id';

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value == null) return null;
    try {
      return jsonDecode(value) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> setUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(user));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    await prefs.remove(_selectedProjectKey);
  }

  static Future<String?> getToken() async {
    final user = await getUser();
    return user?['token'] as String?;
  }

  static Future<bool> hasUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_key);
  }

  // ============================================================================
  // Selected Project Persistence (like React app's localStorage)
  // ============================================================================
  static Future<void> setSelectedProjectId(String projectId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedProjectKey, projectId);
  }

  static Future<String?> getSelectedProjectId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedProjectKey);
  }

  static Future<void> clearSelectedProject() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedProjectKey);
  }
}
