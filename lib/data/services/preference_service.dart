import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

class PreferenceService {
  final SharedPreferences _prefs;

  PreferenceService(this._prefs);

  static Future<PreferenceService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferenceService(prefs);
  }

  // Username
  String getUsername() {
    return _prefs.getString(AppConstants.keyLeetCodeUsername) ?? '';
  }

  Future<void> setUsername(String username) async {
    await _prefs.setString(AppConstants.keyLeetCodeUsername, username.trim());
  }

  // Preferred Language
  String getPreferredLanguage() {
    return _prefs.getString(AppConstants.keyPreferredLanguage) ?? AppConstants.defaultLanguage;
  }

  Future<void> setPreferredLanguage(String lang) async {
    await _prefs.setString(AppConstants.keyPreferredLanguage, lang);
  }

  // Cooldown Days
  int getCooldownDays() {
    return _prefs.getInt(AppConstants.keyCooldownDays) ?? AppConstants.defaultCooldownDays;
  }

  Future<void> setCooldownDays(int days) async {
    await _prefs.setInt(AppConstants.keyCooldownDays, days);
  }

  // Demo Mode
  bool isDemoMode() {
    return _prefs.getBool(AppConstants.keyIsDemoMode) ?? false;
  }

  Future<void> setDemoMode(bool isDemo) async {
    await _prefs.setBool(AppConstants.keyIsDemoMode, isDemo);
  }

  // Last Sync Timestamp
  DateTime? getLastSyncTimestamp() {
    final str = _prefs.getString(AppConstants.keyLastSyncTimestamp);
    if (str == null) return null;
    return DateTime.tryParse(str);
  }

  Future<void> setLastSyncTimestamp(DateTime dt) async {
    await _prefs.setString(AppConstants.keyLastSyncTimestamp, dt.toIso8601String());
  }

  // Cache Widget Stats
  Future<void> cacheWidgetData({
    required int streak,
    required bool isSolvedToday,
    required int totalActiveDays,
  }) async {
    await _prefs.setInt(AppConstants.keyCurrentStreak, streak);
    await _prefs.setBool(AppConstants.keyTodaySolved, isSolvedToday);
    await _prefs.setInt(AppConstants.keyTotalActiveDays, totalActiveDays);
  }
}

