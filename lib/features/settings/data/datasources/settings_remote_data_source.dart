import '../models/response/settings_user_response_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsRemoteDataSource {
  final SupabaseClient _supabase;

  const SettingsRemoteDataSource(this._supabase);

  SettingsUserResponseModel? getCurrentUser() {
    final user = _supabase.auth.currentUser;
    return user == null ? null : SettingsUserResponseModel.fromSupabase(user);
  }

  Future<void> signOut() => _supabase.auth.signOut();
}
