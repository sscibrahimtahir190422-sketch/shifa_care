import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user.dart';

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  bool get hasSession => _client.auth.currentSession != null;

  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<bool> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final res = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
    return res.session != null;
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<AppUser> fetchProfile() async {
    final uid = _client.auth.currentUser!.id;
    final row = await _client.from('profiles').select().eq('id', uid).single();
    return AppUser.fromJson(row);
  }
}
