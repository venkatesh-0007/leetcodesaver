import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/native/native_channel.dart';
import '../core/utils/time_utils.dart';
import '../data/local/heatmap_dao.dart';
import '../data/models/heatmap_day.dart';
import '../data/models/user_profile.dart';
import '../data/services/leetcode_api_service.dart';
import 'app_state_providers.dart';
import 'settings_providers.dart';

// User Profile State
class UserProfileNotifier extends StateNotifier<UserProfile?> {
  UserProfileNotifier() : super(null);

  void setProfile(UserProfile profile) {
    state = profile;
  }
}

final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfile?>((ref) {
  return UserProfileNotifier();
});

// Sync Status State
enum SyncStatus { idle, syncing, success, error }

class SyncState {
  final SyncStatus status;
  final String? errorMessage;
  final DateTime? lastSync;

  const SyncState({
    this.status = SyncStatus.idle,
    this.errorMessage,
    this.lastSync,
  });

  SyncState copyWith({
    SyncStatus? status,
    String? errorMessage,
    DateTime? lastSync,
  }) {
    return SyncState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      lastSync: lastSync ?? this.lastSync,
    );
  }
}

class SyncNotifier extends StateNotifier<SyncState> {
  final Ref _ref;

  SyncNotifier(this._ref) : super(const SyncState());

  Future<void> syncWithLeetCode({bool forceDemo = false}) async {
    state = state.copyWith(status: SyncStatus.syncing);

    final settings = _ref.read(settingsNotifierProvider);
    final apiService = _ref.read(leetCodeApiServiceProvider);
    final heatmapDao = _ref.read(heatmapDaoProvider);
    final prefs = _ref.read(preferenceServiceProvider);

    if (forceDemo || settings.isDemoMode || settings.username.trim().isEmpty) {
      // Use realistic demo data
      final demoResponse = LeetCodeApiService.generateDemoData();
      _ref.read(userProfileProvider.notifier).setProfile(demoResponse.profile);
      await heatmapDao.saveHeatmapDays(demoResponse.heatmapDays);
      _ref.read(heatmapProvider.notifier).setDays(demoResponse.heatmapDays);

      final now = DateTime.now();
      await _ref.read(settingsNotifierProvider.notifier).recordSync(now);
      await prefs.cacheWidgetData(
        streak: demoResponse.profile.currentStreak,
        isSolvedToday: true,
        totalActiveDays: demoResponse.profile.totalActiveDays,
      );

      await NativeChannel.updateWidget(
        streak: demoResponse.profile.currentStreak,
        isSolvedToday: true,
        totalActiveDays: demoResponse.profile.totalActiveDays,
        lastSync: TimeUtils.formatDateTime(now),
      );

      state = SyncState(status: SyncStatus.success, lastSync: now);
      return;
    }

    // Real API fetch
    final response = await apiService.fetchUserProfile(settings.username);

    if (!response.isSuccess) {
      state = SyncState(status: SyncStatus.error, errorMessage: response.errorMessage);
      return;
    }

    _ref.read(userProfileProvider.notifier).setProfile(response.profile);
    await heatmapDao.saveHeatmapDays(response.heatmapDays);
    _ref.read(heatmapProvider.notifier).setDays(response.heatmapDays);

    final now = DateTime.now();
    await _ref.read(settingsNotifierProvider.notifier).recordSync(now);

    final todayKey = TimeUtils.todayKey();
    final todayCount = response.heatmapDays
        .where((d) => TimeUtils.toDateKey(d.date) == todayKey)
        .fold(0, (sum, d) => sum + d.count);
    final isSolvedToday = todayCount > 0;

    await prefs.cacheWidgetData(
      streak: response.profile.currentStreak,
      isSolvedToday: isSolvedToday,
      totalActiveDays: response.profile.totalActiveDays,
    );

    await NativeChannel.updateWidget(
      streak: response.profile.currentStreak,
      isSolvedToday: isSolvedToday,
      totalActiveDays: response.profile.totalActiveDays,
      lastSync: TimeUtils.formatDateTime(now),
    );

    state = SyncState(status: SyncStatus.success, lastSync: now);
  }
}

final syncNotifierProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier(ref);
});

// Heatmap Days State (Map of yyyy-MM-dd -> HeatmapDay)
class HeatmapNotifier extends StateNotifier<Map<String, HeatmapDay>> {
  final HeatmapDao _dao;

  HeatmapNotifier(this._dao) : super({}) {
    loadCachedHeatmap();
  }

  Future<void> loadCachedHeatmap() async {
    final cached = await _dao.getCachedHeatmap();
    if (cached.isNotEmpty) {
      state = cached;
    }
  }

  void setDays(List<HeatmapDay> days) {
    final Map<String, HeatmapDay> map = {};
    for (final day in days) {
      map[TimeUtils.toDateKey(day.date)] = day;
    }
    state = map;
  }

  Future<void> recordAcceptedSubmissionToday() async {
    final today = DateTime.now();
    final key = TimeUtils.todayKey();
    final current = state[key];
    final newCount = (current?.count ?? 0) + 1;
    final updatedDay = HeatmapDay(
      date: today,
      count: newCount,
      level: HeatmapDay.calculateLevel(newCount),
    );

    final newState = Map<String, HeatmapDay>.from(state);
    newState[key] = updatedDay;
    state = newState;

    await _dao.saveHeatmapDays([updatedDay]);
  }
}

final heatmapProvider = StateNotifierProvider<HeatmapNotifier, Map<String, HeatmapDay>>((ref) {
  final dao = ref.watch(heatmapDaoProvider);
  return HeatmapNotifier(dao);
});

