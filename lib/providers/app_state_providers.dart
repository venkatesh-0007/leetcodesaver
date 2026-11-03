import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/heatmap_dao.dart';
import '../data/local/problem_dao.dart';
import '../data/local/submission_dao.dart';
import '../data/services/leetcode_api_service.dart';
import '../data/services/preference_service.dart';

final preferenceServiceProvider = Provider<PreferenceService>((ref) {
  throw UnimplementedError('preferenceServiceProvider must be initialized in main');
});

final problemDaoProvider = Provider<ProblemDao>((ref) {
  return ProblemDao();
});

final submissionDaoProvider = Provider<SubmissionDao>((ref) {
  return SubmissionDao();
});

final heatmapDaoProvider = Provider<HeatmapDao>((ref) {
  return HeatmapDao();
});

final leetCodeApiServiceProvider = Provider<LeetCodeApiService>((ref) {
  return LeetCodeApiService();
});

