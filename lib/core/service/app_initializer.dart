// lib/core/service/app_initializer.dart
import 'package:bungee_manage_sys/core/api/endpoints.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../di/injection_container.dart' as di;

class AppInitializer {
  static Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();

    // ── 1. EasyLocalization (must be before runApp) ──────────
    await EasyLocalization.ensureInitialized();

    // ── 2. Supabase first — DI depends on it ─────────────────
    await Supabase.initialize(
      url: Endpoints.url,
      anonKey: Endpoints.anonKey,
    );
    // ── 3. Date formatting for ar + en ───────────────────────
    await _initLanguages();

    // ── 4. GetIt dependency injection ────────────────────────
    await di.init();
  }

  static Future<void> _initLanguages() async {
    await initializeDateFormatting('ar', null);
    await initializeDateFormatting('en_US', null);
  }
}