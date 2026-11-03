class UserProfile {
  final String username;
  final int currentStreak;
  final int totalActiveDays;
  final int totalSolved;
  final int easySolved;
  final int mediumSolved;
  final int hardSolved;
  final DateTime? lastSyncTime;
  final bool isDemo;
  final bool isConnected;

  const UserProfile({
    required this.username,
    this.currentStreak = 0,
    this.totalActiveDays = 0,
    this.totalSolved = 0,
    this.easySolved = 0,
    this.mediumSolved = 0,
    this.hardSolved = 0,
    this.lastSyncTime,
    this.isDemo = false,
    this.isConnected = false,
  });

  UserProfile copyWith({
    String? username,
    int? currentStreak,
    int? totalActiveDays,
    int? totalSolved,
    int? easySolved,
    int? mediumSolved,
    int? hardSolved,
    DateTime? lastSyncTime,
    bool? isDemo,
    bool? isConnected,
  }) {
    return UserProfile(
      username: username ?? this.username,
      currentStreak: currentStreak ?? this.currentStreak,
      totalActiveDays: totalActiveDays ?? this.totalActiveDays,
      totalSolved: totalSolved ?? this.totalSolved,
      easySolved: easySolved ?? this.easySolved,
      mediumSolved: mediumSolved ?? this.mediumSolved,
      hardSolved: hardSolved ?? this.hardSolved,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      isDemo: isDemo ?? this.isDemo,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}

