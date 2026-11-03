import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../models/heatmap_day.dart';
import '../models/user_profile.dart';

class LeetCodeApiResponse {
  final UserProfile profile;
  final List<HeatmapDay> heatmapDays;
  final bool isSuccess;
  final String? errorMessage;

  LeetCodeApiResponse({
    required this.profile,
    required this.heatmapDays,
    this.isSuccess = true,
    this.errorMessage,
  });
}

class LeetCodeApiService {
  final http.Client _client;

  LeetCodeApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Query public LeetCode profile and submission calendar
  Future<LeetCodeApiResponse> fetchUserProfile(String username) async {
    final cleanUsername = username.trim();
    if (cleanUsername.isEmpty) {
      return LeetCodeApiResponse(
        profile: const UserProfile(username: '', isConnected: false),
        heatmapDays: [],
        isSuccess: false,
        errorMessage: 'Username cannot be empty',
      );
    }

    const String query = '''
      query getUserProfile(\$username: String!) {
        matchedUser(username: \$username) {
          username
          userCalendar {
            streak
            totalActiveDays
            submissionCalendar
          }
          submitStatsGlobal {
            acSubmissionNum {
              difficulty
              count
            }
          }
        }
      }
    ''';

    try {
      final response = await _client.post(
        Uri.parse(AppConstants.leetCodeGraphQLEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Android; Mobile; rv:120.0) Gecko/120.0 Firefox/120.0',
          'Referer': 'https://leetcode.com/$cleanUsername/',
        },
        body: jsonEncode({
          'query': query,
          'variables': {'username': cleanUsername},
        }),
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        return LeetCodeApiResponse(
          profile: UserProfile(username: cleanUsername, isConnected: false),
          heatmapDays: [],
          isSuccess: false,
          errorMessage: 'LeetCode server responded with HTTP ${response.statusCode}',
        );
      }

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (data.containsKey('errors')) {
        final errors = data['errors'] as List;
        final msg = errors.isNotEmpty ? errors[0]['message'] ?? 'GraphQL Error' : 'Unknown error';
        return LeetCodeApiResponse(
          profile: UserProfile(username: cleanUsername, isConnected: false),
          heatmapDays: [],
          isSuccess: false,
          errorMessage: msg,
        );
      }

      final matchedUser = data['data']?['matchedUser'];
      if (matchedUser == null) {
        return LeetCodeApiResponse(
          profile: UserProfile(username: cleanUsername, isConnected: false),
          heatmapDays: [],
          isSuccess: false,
          errorMessage: 'User "$cleanUsername" not found on LeetCode',
        );
      }

      // Parse submitStatsGlobal
      int totalSolved = 0;
      int easySolved = 0;
      int mediumSolved = 0;
      int hardSolved = 0;

      final acNums = matchedUser['submitStatsGlobal']?['acSubmissionNum'] as List?;
      if (acNums != null) {
        for (final item in acNums) {
          final diff = item['difficulty']?.toString().toLowerCase();
          final count = (item['count'] as num?)?.toInt() ?? 0;
          if (diff == 'all') totalSolved = count;
          if (diff == 'easy') easySolved = count;
          if (diff == 'medium') mediumSolved = count;
          if (diff == 'hard') hardSolved = count;
        }
      }

      // Parse userCalendar
      final calendarData = matchedUser['userCalendar'];
      int streakFromApi = (calendarData?['streak'] as num?)?.toInt() ?? 0;
      int totalActiveDays = (calendarData?['totalActiveDays'] as num?)?.toInt() ?? 0;
      String? calendarJsonStr = calendarData?['submissionCalendar']?.toString();

      // If calendar was at root (legacy endpoint compatibility)
      calendarJsonStr ??= matchedUser['submissionCalendar']?.toString();

      // Parse submission calendar map: timestamp string -> submission count
      final Map<String, int> dailyCounts = {};
      if (calendarJsonStr != null && calendarJsonStr.isNotEmpty && calendarJsonStr != '{}') {
        try {
          final Map<String, dynamic> parsedCalendar = jsonDecode(calendarJsonStr);
          parsedCalendar.forEach((key, val) {
            final epochSec = int.tryParse(key);
            if (epochSec != null) {
              final count = (val as num).toInt();
              // Normalize epoch seconds into local timezone date key (YYYY-MM-DD)
              final dt = DateTime.fromMillisecondsSinceEpoch(epochSec * 1000, isUtc: true).toLocal();
              final dateKey = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
              dailyCounts[dateKey] = (dailyCounts[dateKey] ?? 0) + count;
            }
          });
        } catch (_) {}
      }

      if (totalActiveDays == 0) {
        totalActiveDays = dailyCounts.length;
      }

      // Calculate streak if API returned 0 or missing
      final calculatedStreak = _calculateStreak(dailyCounts);
      final finalStreak = streakFromApi > 0 ? streakFromApi : calculatedStreak;

      // Build 1-year heatmap day list ending today
      final heatmapDays = _buildHeatmapList(dailyCounts);

      final profile = UserProfile(
        username: cleanUsername,
        currentStreak: finalStreak,
        totalActiveDays: totalActiveDays,
        totalSolved: totalSolved,
        easySolved: easySolved,
        mediumSolved: mediumSolved,
        hardSolved: hardSolved,
        lastSyncTime: DateTime.now(),
        isDemo: false,
        isConnected: true,
      );

      return LeetCodeApiResponse(
        profile: profile,
        heatmapDays: heatmapDays,
        isSuccess: true,
      );
    } catch (e) {
      return LeetCodeApiResponse(
        profile: UserProfile(username: cleanUsername, isConnected: false),
        heatmapDays: [],
        isSuccess: false,
        errorMessage: 'Network connection failed: ${e.toString()}',
      );
    }
  }

  /// Calculates current streak backwards from today / yesterday
  static int _calculateStreak(Map<String, int> dailyCounts) {
    if (dailyCounts.isEmpty) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayKey = _dateToKey(today);
    final yesterdayKey = _dateToKey(today.subtract(const Duration(days: 1)));

    // Check if user solved today or yesterday
    bool hasToday = (dailyCounts[todayKey] ?? 0) > 0;
    bool hasYesterday = (dailyCounts[yesterdayKey] ?? 0) > 0;

    if (!hasToday && !hasYesterday) {
      return 0; // Streak broken
    }

    int streak = 0;
    DateTime checkDate = hasToday ? today : today.subtract(const Duration(days: 1));

    while (true) {
      final key = _dateToKey(checkDate);
      if ((dailyCounts[key] ?? 0) > 0) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  /// Builds a complete list of days for the past 365 days up to today
  static List<HeatmapDay> _buildHeatmapList(Map<String, int> dailyCounts) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final List<HeatmapDay> days = [];

    // 52 weeks = 364 days + today's remaining weekday
    const int totalDays = 364;
    final startDate = today.subtract(const Duration(days: totalDays));

    for (int i = 0; i <= totalDays; i++) {
      final date = startDate.add(Duration(days: i));
      final key = _dateToKey(date);
      final count = dailyCounts[key] ?? 0;
      days.add(HeatmapDay(
        date: date,
        count: count,
        level: HeatmapDay.calculateLevel(count),
      ));
    }

    return days;
  }

  static String _dateToKey(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  /// Generates realistic demo data clearly marked as demo
  static LeetCodeApiResponse generateDemoData() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final Map<String, int> demoCounts = {};

    // Simulate steady activity with a current streak of 24 days
    for (int i = 0; i < 365; i++) {
      final date = today.subtract(Duration(days: i));
      final key = _dateToKey(date);
      if (i < 24) {
        // Active streak for past 24 days
        demoCounts[key] = (i % 3) + 1;
      } else if (i % 2 == 0 || i % 5 == 0) {
        // Sporadic activity earlier in the year
        demoCounts[key] = (i % 4) + 1;
      }
    }

    final days = _buildHeatmapList(demoCounts);

    return LeetCodeApiResponse(
      profile: UserProfile(
        username: 'Demo_Coder',
        currentStreak: 24,
        totalActiveDays: 168,
        totalSolved: 312,
        easySolved: 142,
        mediumSolved: 138,
        hardSolved: 32,
        lastSyncTime: DateTime.now(),
        isDemo: true,
        isConnected: true,
      ),
      heatmapDays: days,
      isSuccess: true,
    );
  }
}

