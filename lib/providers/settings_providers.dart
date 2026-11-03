import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/preference_service.dart';
import 'app_state_providers.dart';

class SettingsState {
  final String username;
  final String preferredLanguage;
  final int cooldownDays;
  final bool isDemoMode;
  final DateTime? lastSync;

  const SettingsState({
    required this.username,
    required this.preferredLanguage,
    required this.cooldownDays,
    required this.isDemoMode,
    this.lastSync,
  });

  SettingsState copyWith({
    String? username,
    String? preferredLanguage,
    int? cooldownDays,
    bool? isDemoMode,
    DateTime? lastSync,
  }) {
    return SettingsState(
      username: username ?? this.username,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      cooldownDays: cooldownDays ?? this.cooldownDays,
      isDemoMode: isDemoMode ?? this.isDemoMode,
      lastSync: lastSync ?? this.lastSync,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final PreferenceService _prefs;

  SettingsNotifier(this._prefs)
      : super(SettingsState(
          username: _prefs.getUsername(),
          preferredLanguage: _prefs.getPreferredLanguage(),
          cooldownDays: _prefs.getCooldownDays(),
          isDemoMode: _prefs.isDemoMode(),
          lastSync: _prefs.getLastSyncTimestamp(),
        ));

  Future<void> updateUsername(String username) async {
    await _prefs.setUsername(username);
    state = state.copyWith(username: username);
  }

  Future<void> updatePreferredLanguage(String lang) async {
    await _prefs.setPreferredLanguage(lang);
    state = state.copyWith(preferredLanguage: lang);
  }

  Future<void> updateCooldownDays(int days) async {
    await _prefs.setCooldownDays(days);
    state = state.copyWith(cooldownDays: days);
  }

  Future<void> toggleDemoMode(bool isDemo) async {
    await _prefs.setDemoMode(isDemo);
    state = state.copyWith(isDemoMode: isDemo);
  }

  Future<void> recordSync(DateTime timestamp) async {
    await _prefs.setLastSyncTimestamp(timestamp);
    state = state.copyWith(lastSync: timestamp);
  }
}

final settingsNotifierProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final prefs = ref.watch(preferenceServiceProvider);
  return SettingsNotifier(prefs);
});

