import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/request/login_request_model.dart';
import '../models/response/auth_response_model.dart';

class AuthRemoteDataSource {
  final SupabaseClient _supabase;

  AuthRemoteDataSource(this._supabase);

  Future<AuthResponseModel> login(LoginRequestModel request) async {
    final response = await _supabase.auth.signInWithPassword(
      email: request.email,
      password: request.password,
    );

    final user = response.user;

    if (user == null) {
      throw const AuthException('Login failed. Please try again.');
    }

    return AuthResponseModel.fromSupabase(user);
  }
}
