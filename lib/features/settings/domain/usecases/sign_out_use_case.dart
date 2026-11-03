import '../repositories/settings_repository.dart';

class SignOutUseCase {
  final SettingsRepository repository;

  const SignOutUseCase(this.repository);

  Future<void> call() => repository.signOut();
}
