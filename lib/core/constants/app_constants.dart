class AppConstants {
  static const String appName = 'LeetStreak';
  static const String appTagline = 'Maintain your LeetCode streak from your phone';

  // LeetCode URLs & GraphQL
  static const String leetCodeBaseUrl = 'https://leetcode.com';
  static const String leetCodeGraphQLEndpoint = 'https://leetcode.com/graphql';
  static const String leetCodeLoginUrl = 'https://leetcode.com/accounts/login/';
  static const String leetCodeProblemsBaseUrl = 'https://leetcode.com/problems/';

  // SharedPreferences Keys
  static const String keyLeetCodeUsername = 'lc_username';
  static const String keyPreferredLanguage = 'pref_language';
  static const String keyCooldownDays = 'cooldown_days';
  static const String keyAutoSync = 'auto_sync';
  static const String keyLastSyncTimestamp = 'last_sync_timestamp';
  static const String keyIsDemoMode = 'is_demo_mode';
  static const String keyTodaySolved = 'today_solved';
  static const String keyCurrentStreak = 'current_streak';
  static const String keyTotalActiveDays = 'total_active_days';

  // Native Method Channel
  static const String channelName = 'com.leetstreak.app/native';
  static const String methodUpdateWidget = 'updateWidget';
  static const String methodLaunchStreakSaver = 'launchStreakSaver';

  // Defaults
  static const int defaultCooldownDays = 7;
  static const String defaultLanguage = 'Python 3';
}

