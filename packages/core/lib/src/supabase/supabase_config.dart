import 'package:supabase_flutter/supabase_flutter.dart';

/// Configuration et initialisation du client Supabase, partagées par les apps.
///
/// Les valeurs sont fournies au build via --dart-define :
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
class SupabaseConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// À appeler une fois au démarrage (avant runApp).
  static Future<void> initialize() async {
    if (!isConfigured) {
      throw StateError(
        'SUPABASE_URL / SUPABASE_ANON_KEY manquants. '
        'Lancez avec --dart-define (voir README).',
      );
    }
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
