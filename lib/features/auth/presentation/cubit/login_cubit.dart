// lib/features/auth/presentation/cubit/login_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:bungee_manage_sys/features/auth/domain/repositories/auth_repository.dart';
part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final AuthRepository _authRepository;

  LoginCubit(this._authRepository) : super(LoginInitial());

  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(LoginLoading());

    final result = await _authRepository.login(
      email: email,
      password: password,
    );

    result.fold(
          (failure) => emit(LoginError(failure.message)),
          (_) => emit(LoginSuccess()),
    );
  }

  Future<void> logout() async {
    final result = await _authRepository.logout();
    result.fold(
          (failure) => emit(LoginError(failure.message)),
          (_) => emit(LoginInitial()),
    );
  }
}