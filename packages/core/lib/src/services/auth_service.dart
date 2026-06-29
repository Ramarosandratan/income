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

  /// Crée le tout premier compte (le maître) et sa famille.
  ///
  /// Le nom complet et le nom de famille sont passés dans les métadonnées de
  /// l'inscription : un trigger `on_auth_user_created` crée la famille, le
  /// profil maître et les catégories par défaut dans la transaction GoTrue.
  /// Avantages : fonctionne même avec la confirmation d'email activée (aucune
  /// session requise) et reste atomique (pas de compte orphelin).
  /// Crée le tout premier compte (le maître) et sa famille.
  ///
  /// Les erreurs Supabase sont traduites en messages français via
  /// [AuthErrorMapper].
  Future<void> signUpMaster({
    required String email,
    required String password,
    required String fullName,
    required String familyName,
  }) async {
    try {
      final res = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'family_name': familyName},
      );
      if (res.user == null) {
        throw const AuthException('USER_NULL');
      }
    } on AuthException catch (e) {
      throw AuthException(AuthErrorMapper.map(e.message));
    }
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

/// Traduit les messages d'erreur Supabase Auth en français lisible.
class AuthErrorMapper {
  /// Mappe un message d'erreur Supabase Auth vers un message en français.
  /// Si aucun mapping connu, le message original est retourné.
  static String map(String message) {
    // Normalise pour la comparaison
    final m = message.toLowerCase().trim();

    if (m.contains('user already registered') ||
        m.contains('duplicate key') && m.contains('email')) {
      return 'Un compte existe déjà avec cet email.';
    }
    if (m.contains('invalid login credentials') ||
        m.contains('invalid credentials') ||
        m.contains('email ou mot de passe incorrect')) {
      return 'Email ou mot de passe incorrect.';
    }
    if (m.contains('password should be at least 6 characters') ||
        m.contains('password length') ||
        m.contains('signup requires a valid password')) {
      return 'Le mot de passe doit contenir au moins 6 caractères.';
    }
    if (m.contains('invalid email') || m.contains('email address invalid')) {
      return 'Format d\'email invalide.';
    }
    if (m.contains('email not confirmed')) {
      return 'Veuillez confirmer votre email avant de vous connecter. Vérifiez votre boîte de réception.';
    }
    if (m.contains('email rate limit') ||
        m.contains('rate limit') ||
        m.contains('trop de tentatives')) {
      return 'Trop de tentatives. Veuillez réessayer dans quelques minutes.';
    }
    if (m.contains('timeout') ||
        m.contains('network') ||
        m.contains('connection') ||
        m.contains('connexion') ||
        m.contains('fetch')) {
      return 'Impossible de se connecter au serveur. Vérifiez votre connexion internet.';
    }
    if (m.contains('user_null')) {
      return 'Échec de la création du compte. Veuillez réessayer.';
    }

    return message; // pas de mapping connu → message brut
  }
}
