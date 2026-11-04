import '../entities/settings_user.dart';
import '../repositories/settings_repository.dart';

class GetCurrentUserUseCase {
  final SettingsRepository repository;

  const GetCurrentUserUseCase(this.repository);

  SettingsUser? call() => repository.getCurrentUser();
}
