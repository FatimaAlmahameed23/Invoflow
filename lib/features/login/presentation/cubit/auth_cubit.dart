import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;
import '../../domain/entities/auth_user.dart';
import '../../domain/usecases/login_usecase.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase loginUseCase;

  AuthCubit(this.loginUseCase) : super(AuthInitial());

  Future<void> login({required String email, required String password}) async {
    if (isClosed || state is AuthLoading) return;
    emit(AuthLoading());

    try {
      final user = await loginUseCase(email: email.trim(), password: password);

      if (isClosed) return;
      emit(AuthSuccess(user));
    } on AuthException catch (e) {
      if (isClosed) return;
      emit(AuthFailure(e.message));
    } catch (_) {
      if (isClosed) return;
      emit(AuthFailure('Something went wrong. Please try again.'));
    }
  }
}
