// lib/features/user_data/user_repo.dart
import 'dart:async';
import 'package:bungee_manage_sys/features/user_data/user.dart' show User;
import 'package:bungee_manage_sys/features/user_data/user_model.dart' show UserModel;
import '../../core/db/shared_pref_helper.dart';
import '../../core/utils/app_constans.dart';

/// Single source of truth for the current user.
/// Singleton — one instance across the whole app.
class UserRepository {
  // ── Singleton ────────────────────────────────────────────
  static final UserRepository _instance = UserRepository._internal();
  factory UserRepository() => _instance;
  UserRepository._internal();

  // ── Stream ───────────────────────────────────────────────
  final _controller = StreamController<User?>.broadcast();
  Stream<User?> get userStream => _controller.stream;

  // ── State ────────────────────────────────────────────────
  User? _currentUser;
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  // ── Convenience getters ───────────────────────────────────
  bool get isAdmin => _currentUser?.role == 'admin';

  // ── Lifecycle ────────────────────────────────────────────

  /// Call once in main() before runApp
  Future<void> loadUser() async {
    final json = await SharedPrefHelper.getJson(key: AppConstants.userKey);
    if (json != null) {
      _currentUser = UserModel.fromJson(json).toEntity();
    }
  }

  // ── Write ─────────────────────────────────────────────────

  /// Called after login
  Future<void> setUser(User user) async {
    _currentUser = user;
    _controller.add(user);
    await SharedPrefHelper.saveJson(
      key: AppConstants.userKey,
      value: UserModel.fromEntity(user).toJson(),
    );
  }

  /// Called on logout
  Future<void> clearUser() async {
    _currentUser = null;
    _controller.add(null);
    await SharedPrefHelper.delete(key: AppConstants.userKey);
  }

  /// Update specific fields (e.g. profile edit)
  Future<void> updateUser({String? name, String? phone}) async {
    if (_currentUser == null) return;
    await setUser(_currentUser!.copyWith(name: name, phone: phone));
  }

  void dispose() => _controller.close();
}