import '../../domain/entities/settings_user.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_remote_data_source.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsRemoteDataSource remoteDataSource;

  const SettingsRepositoryImpl(this.remoteDataSource);

  @override
  SettingsUser? getCurrentUser() {
    final user = remoteDataSource.getCurrentUser();
    final email = user?.email;
    if (email == null || email.isEmpty) return null;

    return SettingsUser(email: email);
  }

  @override
  Future<void> signOut() => remoteDataSource.signOut();
}
