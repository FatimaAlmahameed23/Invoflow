import '../entities/settings_user.dart';

abstract interface class SettingsRepository {
  SettingsUser? getCurrentUser();

  Future<void> signOut();
}
