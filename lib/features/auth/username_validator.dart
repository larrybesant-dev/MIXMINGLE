// Username uniqueness validator
import 'package:supabase_flutter/supabase_flutter.dart';

class UsernameValidator {
  static Future<bool> isUnique(String username) async {
    final response = await Supabase.instance.client
        .from('users')
        .select('id')
        .eq('username', username)
        .maybeSingle();
    return response == null;
  }
}
