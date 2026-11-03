import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/problem_dao.dart';
import '../data/models/difficulty.dart';
import '../data/models/saved_problem.dart';
import 'app_state_providers.dart';
import 'settings_providers.dart';

// --- Problem List State ---

class ProblemListNotifier extends StateNotifier<AsyncValue<List<SavedProblem>>> {
  final ProblemDao _dao;

  ProblemListNotifier(this._dao) : super(const AsyncValue.loading()) {
    loadProblems();
  }

  Future<void> loadProblems() async {
    try {
      state = const AsyncValue.loading();
      final problems = await _dao.getAllProblems();
      state = AsyncValue.data(problems);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<int> addProblem(SavedProblem problem) async {
    final id = await _dao.insertProblem(problem);
    await loadProblems();
    return id;
  }

  Future<void> updateProblem(SavedProblem problem) async {
    await _dao.updateProblem(problem);
    await loadProblems();
  }

  Future<void> deleteProblem(int id) async {
    await _dao.deleteProblem(id);
    await loadProblems();
  }

  Future<void> recordAttempt({required int problemId, required bool isAccepted}) async {
    await _dao.recordSubmissionAttempt(problemId: problemId, isAccepted: isAccepted);
    await loadProblems();
  }

  Future<int> importProblems(List<Map<String, dynamic>> problems) async {
    final count = await _dao.importProblems(problems);
    await loadProblems();
    return count;
  }
}

final problemListProvider = StateNotifierProvider<ProblemListNotifier, AsyncValue<List<SavedProblem>>>((ref) {
  final dao = ref.watch(problemDaoProvider);
  return ProblemListNotifier(dao);
});

// --- Search & Filter State ---

class FilterState {
  final String query;
  final Difficulty? difficulty;
  final String language;

  const FilterState({
    this.query = '',
    this.difficulty,
    this.language = 'All',
  });

  FilterState copyWith({
    String? query,
    Difficulty? difficulty,
    bool clearDifficulty = false,
    String? language,
  }) {
    return FilterState(
      query: query ?? this.query,
      difficulty: clearDifficulty ? null : (difficulty ?? this.difficulty),
      language: language ?? this.language,
    );
  }
}

final filterStateProvider = StateProvider<FilterState>((ref) => const FilterState());

final filteredProblemsProvider = Provider<List<SavedProblem>>((ref) {
  final asyncProblems = ref.watch(problemListProvider);
  final filter = ref.watch(filterStateProvider);

  return asyncProblems.maybeWhen(
    data: (problems) {
      return problems.where((p) {
        // Query filter
        if (filter.query.isNotEmpty) {
          final q = filter.query.toLowerCase();
          final matchesTitle = p.title.toLowerCase().contains(q);
          final matchesSlug = p.slug.toLowerCase().contains(q);
          final matchesNotes = p.notes?.toLowerCase().contains(q) ?? false;
          if (!matchesTitle && !matchesSlug && !matchesNotes) return false;
        }

        // Difficulty filter
        if (filter.difficulty != null && p.difficulty != filter.difficulty) {
          return false;
        }

        // Language filter
        if (filter.language != 'All' && p.language.toLowerCase() != filter.language.toLowerCase()) {
          return false;
        }

        return true;
      }).toList();
    },
    orElse: () => [],
  );
});

// --- Random Problem Selection State ---

class RandomSelectionState {
  final SavedProblem? selectedProblem;
  final List<SavedProblem> eligibleCandidates;
  final bool isLoading;
  final String? message;

  const RandomSelectionState({
    this.selectedProblem,
    this.eligibleCandidates = const [],
    this.isLoading = false,
    this.message,
  });

  RandomSelectionState copyWith({
    SavedProblem? selectedProblem,
    List<SavedProblem>? eligibleCandidates,
    bool? isLoading,
    String? message,
  }) {
    return RandomSelectionState(
      selectedProblem: selectedProblem ?? this.selectedProblem,
      eligibleCandidates: eligibleCandidates ?? this.eligibleCandidates,
      isLoading: isLoading ?? this.isLoading,
      message: message ?? this.message,
    );
  }
}

class RandomSelectionNotifier extends StateNotifier<RandomSelectionState> {
  final ProblemDao _dao;
  final Ref _ref;
  final Random _random = Random();

  RandomSelectionNotifier(this._dao, this._ref) : super(const RandomSelectionState());

  /// Pick an eligible problem, avoiding recently submitted problems
  Future<void> pickEligibleProblem({int? excludeProblemId}) async {
    state = state.copyWith(isLoading: true, message: null);

    final settings = _ref.read(settingsNotifierProvider);
    final cooldownDays = settings.cooldownDays;
    final preferredLang = settings.preferredLanguage;

    final candidates = await _dao.getEligibleProblems(
      cooldownDays: cooldownDays,
      preferredLanguage: preferredLang,
    );

    if (candidates.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        selectedProblem: null,
        eligibleCandidates: [],
        message: 'No saved solutions found. Add problems to your library first!',
      );
      return;
    }

    // Filter out currently shown problem if more than one candidate exists
    List<SavedProblem> pool = candidates;
    if (excludeProblemId != null && candidates.length > 1) {
      pool = candidates.where((p) => p.id != excludeProblemId).toList();
      if (pool.isEmpty) pool = candidates;
    }

    final selected = pool[_random.nextInt(pool.length)];

    state = RandomSelectionState(
      selectedProblem: selected,
      eligibleCandidates: candidates,
      isLoading: false,
      message: null,
    );
  }

  /// Re-roll to choose another random candidate
  void reRoll() {
    if (state.selectedProblem != null) {
      pickEligibleProblem(excludeProblemId: state.selectedProblem!.id);
    } else {
      pickEligibleProblem();
    }
  }

  /// Manually select a specific problem
  void selectManual(SavedProblem problem) {
    state = state.copyWith(selectedProblem: problem);
  }
}

final randomSelectionProvider = StateNotifierProvider<RandomSelectionNotifier, RandomSelectionState>((ref) {
  final dao = ref.watch(problemDaoProvider);
  return RandomSelectionNotifier(dao, ref);
});

