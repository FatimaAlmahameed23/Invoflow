import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsUserResponseModel {
  const SettingsUserResponseModel({required this.id, this.email});

  final String id;
  final String? email;

  factory SettingsUserResponseModel.fromSupabase(User user) {
    return SettingsUserResponseModel(id: user.id, email: user.email);
  }
}
