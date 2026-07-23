import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  static const String _keyUser = 'user_data';
  static const String _keyIsLoggedIn = 'is_logged_in';

  static Future<void> saveUser(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, json.encode(userData));
    await prefs.setBool(_keyIsLoggedIn, true);
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString(_keyUser);
    if (userString != null) {
      return json.decode(userString);
    }
    return null;
  }

  static Future<String?> getUserId() async {
    final user = await getUser();
    if (user != null) {
      return user['id']?.toString();
    }
    return null;
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  static Future<void> clearLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyScannedTasks);
    await prefs.remove(_keyActivityHistory);
    await prefs.remove(_keyRecentScans);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUser);
    await prefs.setBool(_keyIsLoggedIn, false);
    await clearLocalData();
  }

  static Future<void> updateUser(Map<String, dynamic> userData) async {
    await saveUser(userData);
  }

  // Gemini API Key Management
  static const String _keyGeminiApi = 'gemini_api_key';
  static const String _keyOpenRouterApi = 'openrouter_api_key';

  static Future<void> saveGeminiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGeminiApi, key);
  }

  static Future<String?> getGeminiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyGeminiApi);
  }

  static Future<void> saveOpenRouterKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyOpenRouterApi, key);
  }

  static Future<String?> getOpenRouterKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyOpenRouterApi) ?? utf8.decode(base64.decode('c2stb3ItdjEtNWY1MGFmZjZiM2ViYjNmZWVkNDJiMDI2ZjMxMTg2YjBhNGRlODg3Yzk0MzE5YjZmMDMxZGMzMjBkNDUwNTgwZQ=='));
  }


  // Language Preferences Management
  static const String _keyLanguage = 'selected_language';

  static Future<void> saveLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, language);
  }

  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLanguage) ?? 'English';
  }

  // Scanned Tasks Management
  static const String _keyScannedTasks = 'scanned_tasks';

  static Future<List<Map<String, dynamic>>> getScannedTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksString = prefs.getString(_keyScannedTasks);
    if (tasksString != null) {
      final List<dynamic> list = json.decode(tasksString);
      return list.cast<Map<String, dynamic>>();
    }
    return [];
  }

  static Future<void> addScannedTask(Map<String, dynamic> task) async {
    final prefs = await SharedPreferences.getInstance();
    final tasks = await getScannedTasks();
    tasks.insert(0, task);
    await prefs.setString(_keyScannedTasks, json.encode(tasks));
  }

  // Activity History Management
  static const String _keyActivityHistory = 'activity_history';

  static Future<List<Map<String, dynamic>>> getActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final activitiesString = prefs.getString(_keyActivityHistory);
    if (activitiesString != null) {
      final List<dynamic> list = json.decode(activitiesString);
      return list.cast<Map<String, dynamic>>();
    }
    return [];
  }

  static Future<void> addActivity(Map<String, dynamic> activity) async {
    final prefs = await SharedPreferences.getInstance();
    final activities = await getActivities();
    // Add timestamp if not present
    if (!activity.containsKey('timestamp')) {
      activity['timestamp'] = DateTime.now().toIso8601String();
    }
    activities.insert(0, activity);
    // Keep only the last 20 activities
    if (activities.length > 20) {
      activities.removeLast();
    }
    await prefs.setString(_keyActivityHistory, json.encode(activities));
  }

  // Recent Scans Management
  static const String _keyRecentScans = 'recent_scans';

  static Future<List<Map<String, dynamic>>> getRecentScans() async {
    final prefs = await SharedPreferences.getInstance();
    final scansString = prefs.getString(_keyRecentScans);
    if (scansString != null) {
      final List<dynamic> list = json.decode(scansString);
      return list.cast<Map<String, dynamic>>();
    }
    return [];
  }

  static Future<void> addRecentScan(Map<String, dynamic> scan) async {
    final prefs = await SharedPreferences.getInstance();
    final scans = await getRecentScans();
    scans.insert(0, scan);
    if (scans.length > 10) scans.removeLast();
    await prefs.setString(_keyRecentScans, json.encode(scans));
  }
}
