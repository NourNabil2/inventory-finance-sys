// lib/features/user_data/cubit/user_cubit.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:bungee_manage_sys/features/user_data/user.dart' show User;
import 'package:bungee_manage_sys/features/user_data/user_repo.dart';
import 'package:meta/meta.dart';
part 'user_state.dart';

class UserCubit extends Cubit<User?> {
  final UserRepository _userRepository;
  late final StreamSubscription<User?> _subscription;

  UserCubit(this._userRepository) : super(_userRepository.currentUser) {
    _subscription = _userRepository.userStream.listen(emit);
  }

  // ── Convenience getters ───────────────────────────────────
  bool get isLoggedIn   => state != null;
  String get displayName => state?.name ?? '';
  bool get isAdmin       => state?.role == 'admin';
  String get role        => state?.role ?? 'employee';

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}