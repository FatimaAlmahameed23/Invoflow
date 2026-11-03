import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsRemoteDataSource {
  final SupabaseClient _supabase;

  const SettingsRemoteDataSource(this._supabase);

  User? get currentUser => _supabase.auth.currentUser;

  Future<void> signOut() => _supabase.auth.signOut();
}
