import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/native/native_channel.dart';
import '../core/utils/time_utils.dart';
import '../data/local/submission_dao.dart';
import '../data/models/submission_attempt.dart';
import 'app_state_providers.dart';
import 'heatmap_providers.dart';
import 'problem_providers.dart';

class SubmissionHistoryNotifier extends StateNotifier<AsyncValue<List<SubmissionAttempt>>> {
  final SubmissionDao _dao;
  final Ref _ref;

  SubmissionHistoryNotifier(this._dao, this._ref) : super(const AsyncValue.loading()) {
    loadSubmissions();
  }

  Future<void> loadSubmissions() async {
    try {
      state = const AsyncValue.loading();
      final list = await _dao.getAllSubmissions();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Record a submission attempt
  Future<void> recordSubmission({
    required int problemId,
    required String problemTitle,
    required String problemSlug,
    required String language,
    required SubmissionVerdict verdict,
    String? leetCodeSubmissionId,
    String? details,
  }) async {
    final attempt = SubmissionAttempt(
      problemId: problemId,
      problemTitle: problemTitle,
      problemSlug: problemSlug,
      language: language,
      timestamp: DateTime.now(),
      verdict: verdict,
      leetCodeSubmissionId: leetCodeSubmissionId,
      details: details,
    );

    await _dao.insertSubmission(attempt);

    // Update problem stats in problem_dao
    final isAccepted = (verdict == SubmissionVerdict.accepted);
    await _ref.read(problemListProvider.notifier).recordAttempt(
          problemId: problemId,
          isAccepted: isAccepted,
        );

    // If accepted, add to today's heatmap day and refresh widget
    if (isAccepted) {
      await _ref.read(heatmapProvider.notifier).recordAcceptedSubmissionToday();

      // Refresh native widget
      final profile = _ref.read(userProfileProvider);
      final streak = (profile?.currentStreak ?? 0) + 1;
      final activeDays = (profile?.totalActiveDays ?? 0) + 1;

      await NativeChannel.updateWidget(
        streak: streak,
        isSolvedToday: true,
        totalActiveDays: activeDays,
        lastSync: TimeUtils.formatDateTime(DateTime.now()),
      );
    }

    await loadSubmissions();
  }

  Future<void> clearHistory() async {
    await _dao.clearHistory();
    await loadSubmissions();
  }
}

final submissionHistoryProvider = StateNotifierProvider<SubmissionHistoryNotifier, AsyncValue<List<SubmissionAttempt>>>((ref) {
  final dao = ref.watch(submissionDaoProvider);
  return SubmissionHistoryNotifier(dao, ref);
});

/// Returns true if a verified Accepted submission was recorded today
final isStreakSolvedTodayProvider = Provider<bool>((ref) {
  final submissionsAsync = ref.watch(submissionHistoryProvider);
  return submissionsAsync.maybeWhen(
    data: (list) {
      for (final s in list) {
        if (s.verdict == SubmissionVerdict.accepted && TimeUtils.isToday(s.timestamp)) {
          return true;
        }
      }
      // Also check if heatmap shows today solved
      final heatmap = ref.watch(heatmapProvider);
      final todayKey = TimeUtils.todayKey();
      final day = heatmap[todayKey];
      return (day?.count ?? 0) > 0;
    },
    orElse: () => false,
  );
});

