import 'package:supabase_flutter/supabase_flutter.dart';

class AuthResponseModel {
  final String id;
  final String? email;

  const AuthResponseModel({required this.id, this.email});

  factory AuthResponseModel.fromSupabase(User user) {
    return AuthResponseModel(id: user.id, email: user.email);
  }
}
