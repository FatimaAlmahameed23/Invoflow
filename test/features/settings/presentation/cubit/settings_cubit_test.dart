import 'package:flutter_test/flutter_test.dart';
import 'package:invoflow/features/settings/domain/entities/settings_user.dart';
import 'package:invoflow/features/settings/domain/repositories/settings_repository.dart';
import 'package:invoflow/features/settings/domain/usecases/get_current_user_use_case.dart';
import 'package:invoflow/features/settings/domain/usecases/sign_out_use_case.dart';
import 'package:invoflow/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeSettingsRepository implements SettingsRepository {
  @override
  SettingsUser? getCurrentUser() => const SettingsUser(email: 'user@test.com');

  @override
  Future<void> signOut() async {}
}

class _FailingSignOutRepository extends _FakeSettingsRepository {
  @override
  Future<void> signOut() async {
    throw const AuthException('Sign out failed');
  }
}

void main() {
  group('SettingsCubit', () {
    test('loads the signed-in account', () {
      final repository = _FakeSettingsRepository();
      final cubit = SettingsCubit(
        getCurrentUser: GetCurrentUserUseCase(repository),
        signOutUseCase: SignOutUseCase(repository),
      );

      cubit.loadAccount();

      expect(cubit.state.user?.email, 'user@test.com');
      expect(cubit.state.isLoading, isFalse);
      cubit.close();
    });

    test('signs out successfully', () async {
      final repository = _FakeSettingsRepository();
      final cubit = SettingsCubit(
        getCurrentUser: GetCurrentUserUseCase(repository),
        signOutUseCase: SignOutUseCase(repository),
      );

      await cubit.signOut();

      expect(cubit.state.isSignedOut, isTrue);
      await cubit.close();
    });

    test('shows an authentication error when sign out fails', () async {
      final repository = _FailingSignOutRepository();
      final cubit = SettingsCubit(
        getCurrentUser: GetCurrentUserUseCase(repository),
        signOutUseCase: SignOutUseCase(repository),
      );
      cubit.loadAccount();

      await cubit.signOut();

      expect(cubit.state.isSignedOut, isFalse);
      expect(cubit.state.errorMessage, 'Sign out failed');
      expect(cubit.state.user?.email, 'user@test.com');
      await cubit.close();
    });
  });
}
