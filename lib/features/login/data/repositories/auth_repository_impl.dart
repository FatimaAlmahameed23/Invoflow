import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/request/login_request_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final request = LoginRequestModel(email: email, password: password);

    final response = await remoteDataSource.login(request);

    final userEmail = response.email;

    if (userEmail == null || userEmail.isEmpty) {
      throw StateError('Authenticated user email is missing');
    }

    return AuthUser(id: response.id, email: userEmail);
  }
}
