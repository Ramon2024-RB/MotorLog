import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final premiumProvider = AsyncNotifierProvider<PremiumNotifier, bool>(
  PremiumNotifier.new,
);

class PremiumNotifier extends AsyncNotifier<bool> {
  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  Future<bool> build() async {
    return _loadPremiumStatus();
  }

  Future<bool> _loadPremiumStatus() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      return false;
    }

    final profile = await _supabase
        .from('profiles')
        .select('is_premium')
        .eq('id', user.id)
        .maybeSingle();

    if (profile == null) {
      return false;
    }

    return profile['is_premium'] == true;
  }

  Future<void> activatePremiumForTesting() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw const AuthException('Kein Benutzer angemeldet.');
    }

    await _supabase
        .from('profiles')
        .update({'is_premium': true})
        .eq('id', user.id);

    state = const AsyncData(true);
  }

  Future<void> reload() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(_loadPremiumStatus);
  }
}
