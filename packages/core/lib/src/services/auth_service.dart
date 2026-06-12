import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';

/// Authentification + chargement du profil courant.
class AuthService {
  AuthService(this._client);

  final SupabaseClient _client;

  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;
  bool get isSignedIn => currentSession != null;

  /// Flux des changements d'état d'authentification (connexion / déconnexion).
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) =>
      _client.auth.signInWithPassword(email: email, password: password);

  /// Crée le tout premier compte (le maître) et sa famille via une RPC
  /// transactionnelle côté base.
  Future<void> signUpMaster({
    required String email,
    required String password,
    required String fullName,
    required String familyName,
  }) async {
    final res = await _client.auth.signUp(email: email, password: password);
    final userId = res.user?.id;
    if (userId == null) {
      throw const AuthException('Échec de la création du compte.');
    }
    await _client.rpc('bootstrap_family', params: {
      'p_full_name': fullName,
      'p_family_name': familyName,
    });
  }

  Future<void> signOut() => _client.auth.signOut();

  /// Charge le profil du membre connecté (rôle, famille…).
  Future<Profile?> loadCurrentProfile() async {
    final uid = currentUser?.id;
    if (uid == null) return null;
    final row = await _client
        .from('profiles')
        .select()
        .eq('id', uid)
        .maybeSingle();
    return row == null ? null : Profile.fromJson(row);
  }
}
