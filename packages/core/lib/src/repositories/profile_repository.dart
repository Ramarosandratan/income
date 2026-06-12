import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';

class ProfileRepository {
  ProfileRepository(this._client);
  final SupabaseClient _client;

  /// Tous les membres de la famille (visible par le maître ; un membre ne voit
  /// que lui-même selon les policies RLS).
  Future<List<Profile>> listMembers() async {
    final rows = await _client
        .from('profiles')
        .select()
        .order('role') // master d'abord
        .order('full_name');
    return (rows as List)
        .map((e) => Profile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Profile> getById(String id) async {
    final row = await _client.from('profiles').select().eq('id', id).single();
    return Profile.fromJson(row);
  }

  /// Invite un nouveau membre. La création du compte d'auth nécessite la clé
  /// service ; elle est donc déléguée à une Edge Function sécurisée.
  Future<void> inviteMember({
    required String email,
    required String fullName,
  }) async {
    await _client.functions.invoke('invite-member', body: {
      'email': email,
      'full_name': fullName,
    });
  }

  Future<void> updateName(String id, String fullName) async {
    await _client.from('profiles').update({'full_name': fullName}).eq('id', id);
  }
}
