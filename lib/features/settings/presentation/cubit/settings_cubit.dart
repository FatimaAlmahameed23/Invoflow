import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/settings_user.dart';
import '../../domain/usecases/get_current_user_use_case.dart';
import '../../domain/usecases/sign_out_use_case.dart';

class SettingsState {
  final SettingsUser? user;
  final bool isLoading;
  final bool isSigningOut;
  final bool isSignedOut;
  final String? errorMessage;

  const SettingsState({
    this.user,
    this.isLoading = false,
    this.isSigningOut = false,
    this.isSignedOut = false,
    this.errorMessage,
  });
}

class SettingsCubit extends Cubit<SettingsState> {
  final GetCurrentUserUseCase getCurrentUser;
  final SignOutUseCase signOutUseCase;

  SettingsCubit({required this.getCurrentUser, required this.signOutUseCase})
    : super(const SettingsState(isLoading: true));

  void loadAccount() {
    try {
      emit(SettingsState(user: getCurrentUser()));
    } catch (_) {
      emit(
        const SettingsState(
          errorMessage: 'Could not load your account. Please try again.',
        ),
      );
    }
  }

  Future<void> signOut() async {
    emit(SettingsState(user: state.user, isSigningOut: true));
    try {
      await signOutUseCase();
      emit(const SettingsState(isSignedOut: true));
    } on AuthException catch (error) {
      emit(SettingsState(user: state.user, errorMessage: error.message));
    } catch (_) {
      emit(
        SettingsState(
          user: state.user,
          errorMessage: 'Could not sign out. Please try again.',
        ),
      );
    }
  }
}
