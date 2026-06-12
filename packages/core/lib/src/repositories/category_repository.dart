import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/category.dart';
import '../models/enums.dart';

class CategoryRepository {
  CategoryRepository(this._client);
  final SupabaseClient _client;

  Future<List<Category>> list({EntryKind? kind}) async {
    var query = _client.from('categories').select();
    if (kind != null) query = query.eq('kind', kind.name);
    final rows = await query.order('name');
    return (rows as List)
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Category> create(Category category, String familyId) async {
    final row = await _client
        .from('categories')
        .insert(category.toInsert(familyId))
        .select()
        .single();
    return Category.fromJson(row);
  }

  Future<void> delete(String id) async {
    await _client.from('categories').delete().eq('id', id);
  }
}
