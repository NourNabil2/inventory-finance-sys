// lib/features/auth/data/datasources/auth_remote_datasource.dart
import 'package:bungee_manage_sys/core/errors/error_handler.dart';
import 'package:bungee_manage_sys/features/user_data/user_model.dart';
import 'package:bungee_manage_sys/features/user_data/user_repo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRemoteDataSource {
  Future<void> login({required String email, required String password});
  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient _supabase;

  AuthRemoteDataSourceImpl(this._supabase);

  @override
  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Sign in via Supabase Auth
      final authResponse = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // 2. Fetch user details + role from public.users table
      final userData = await _supabase
          .from('users')
          .select()
          .eq('id', authResponse.user!.id)
          .single();

      // 3. Map to UserModel and update global singleton
      final user = UserModel.fromJson(userData).toEntity();
      await UserRepository().setUser(user);
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
      await UserRepository().clearUser();
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }
}