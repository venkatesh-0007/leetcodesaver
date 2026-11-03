import 'package:intl/intl.dart';

class TimeUtils {
  /// Converts an epoch seconds timestamp (as returned by LeetCode submissionCalendar)
  /// into a DateTime in local device timezone (or Indian Standard Time if desired).
  static DateTime epochSecondsToDateTime(int epochSeconds) {
    return DateTime.fromMillisecondsSinceEpoch(epochSeconds * 1000, isUtc: true).toLocal();
  }

  /// Converts DateTime to a normalized midnight date string (yyyy-MM-dd)
  static String toDateKey(DateTime dt) {
    return DateFormat('yyyy-MM-dd').format(dt);
  }

  /// Returns today's date key in local timezone
  static String todayKey() {
    return toDateKey(DateTime.now());
  }

  /// Checks if a given timestamp falls on today
  static bool isToday(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  /// Relative time description (e.g. "2 hours ago", "Yesterday", "3 days ago")
  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return '$mins ${mins == 1 ? 'min' : 'mins'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, yyyy').format(dateTime);
    }
  }

  /// Formatted date string (e.g. "Oct 24, 2026, 05:42 PM")
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM d, yyyy • h:mm a').format(dateTime);
  }
}

