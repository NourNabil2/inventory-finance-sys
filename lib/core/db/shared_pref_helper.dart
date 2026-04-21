// lib/core/db/shared_pref_helper.dart

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/user_data/user_model.dart';
import '../utils/app_constans.dart';

/// Two-tier storage:
///  • [_secure]  — FlutterSecureStorage  → sensitive data (token, user JSON)
///  • [_prefs]   — SharedPreferences     → non-sensitive settings (theme, lang, notifs)
class SharedPrefHelper {
  // ── Secure storage (encrypted) ────────────────────────────
  static const FlutterSecureStorage _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ── Plain storage (fast, non-sensitive) ───────────────────
  static Future<SharedPreferences> get _prefs =>
      SharedPreferences.getInstance();

  // ══════════════════════════════════════════════════════════
  // SECURE — JSON (user data, tokens)
  // ══════════════════════════════════════════════════════════



  // ══════════════════════════════════════════════════════════
  // SECURE — JSON (user data, tokens)
  // ══════════════════════════════════════════════════════════

  static Future<bool> saveJson({
    required String key,
    required Map<String, dynamic> value,
  }) async {
    try {
      await _secure.write(key: key, value: jsonEncode(value));
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getJson({required String key}) async {
    try {
      final raw = await _secure.read(key: key);
      if (raw != null && raw.isNotEmpty) {
        return jsonDecode(raw) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<UserModel?> getUserData() async {
    try {
      final json = await getJson(key: AppConstants.userKey);
      if (json != null) return UserModel.fromJson(json);
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Secure — String (e.g. auth token) ────────────────────

  static Future<String?> getSecureString({required String key}) async {
    try {
      return await _secure.read(key: key);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveSecureString({
    required String key,
    required String value,
  }) async {
    try {
      await _secure.write(key: key, value: value);
    } catch (_) {}
  }

  // ── Secure — Delete ───────────────────────────────────────

  static Future<void> delete({required String key}) async {
    try {
      await _secure.delete(key: key);
    } catch (_) {}
  }

  static Future<void> clearAll() async {
    try {
      await _secure.deleteAll();
      final prefs = await _prefs;
      await prefs.clear();
    } catch (_) {}
  }

  static Future<bool> containsKey({required String key}) async {
    try {
      return await _secure.containsKey(key: key);
    } catch (_) {
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════
  // PLAIN — String  (language code, theme name, etc.)
  // ══════════════════════════════════════════════════════════

  static Future<void> saveString({
    required String key,
    required String value,
  }) async {
    try {
      final prefs = await _prefs;
      await prefs.setString(key, value);
    } catch (_) {}
  }

  static Future<String?> getString({required String key}) async {
    try {
      final prefs = await _prefs;
      return prefs.getString(key);
    } catch (_) {
      return null;
    }
  }

  // ══════════════════════════════════════════════════════════
  // PLAIN — Bool  (notifications, any toggle)
  // ══════════════════════════════════════════════════════════

  static Future<void> saveBool({
    required String key,
    required bool value,
  }) async {
    try {
      final prefs = await _prefs;
      await prefs.setBool(key, value);
    } catch (_) {}
  }

  static Future<bool?> getBool({required String key}) async {
    try {
      final prefs = await _prefs;
      return prefs.getBool(key);
    } catch (_) {
      return null;
    }
  }

  // ══════════════════════════════════════════════════════════
  // PLAIN — Int  (future use)
  // ══════════════════════════════════════════════════════════

  static Future<void> saveInt({
    required String key,
    required int value,
  }) async {
    try {
      final prefs = await _prefs;
      await prefs.setInt(key, value);
    } catch (_) {}
  }

  static Future<int?> getInt({required String key}) async {
    try {
      final prefs = await _prefs;
      return prefs.getInt(key);
    } catch (_) {
      return null;
    }
  }
}