import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/difficulty.dart';
import '../../data/models/language.dart';
import '../../providers/problem_providers.dart';
import '../widgets/solution_card.dart';
import 'edit_problem_screen.dart';
import 'problem_detail_screen.dart';
import 'streak_saver_flow_screen.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredProblems = ref.watch(filteredProblemsProvider);
    final filter = ref.watch(filterStateProvider);
    final allProblemsAsync = ref.watch(problemListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Solution Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primary, size: 28),
            tooltip: 'Add Solution',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProblemScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            color: AppColors.background,
            child: Column(
              children: [
                // Search Input
                TextField(
                  onChanged: (val) {
                    ref.read(filterStateProvider.notifier).state = filter.copyWith(query: val);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by title, number, or notes...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                    suffixIcon: filter.query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              ref.read(filterStateProvider.notifier).state =
                                  filter.copyWith(query: '');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),

                // Difficulty Filter Chips & Language Dropdown
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildDifficultyChip(ref, null, 'All', filter.difficulty == null),
                            const SizedBox(width: 6),
                            _buildDifficultyChip(
                              ref,
                              Difficulty.easy,
                              'Easy',
                              filter.difficulty == Difficulty.easy,
                            ),
                            const SizedBox(width: 6),
                            _buildDifficultyChip(
                              ref,
                              Difficulty.medium,
                              'Medium',
                              filter.difficulty == Difficulty.medium,
                            ),
                            const SizedBox(width: 6),
                            _buildDifficultyChip(
                              ref,
                              Difficulty.hard,
                              'Hard',
                              filter.difficulty == Difficulty.hard,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Language Filter Popup
                    PopupMenuButton<String>(
                      initialValue: filter.language,
                      color: AppColors.surfaceElevated,
                      onSelected: (val) {
                        ref.read(filterStateProvider.notifier).state =
                            filter.copyWith(language: val);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Text(
                              filter.language == 'All' ? 'Lang' : filter.language,
                              style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down_rounded, size: 16, color: AppColors.textMuted),
                          ],
                        ),
                      ),
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: 'All', child: Text('All Languages')),
                        ...SupportedLanguage.all.map(
                          (l) => PopupMenuItem(value: l.name, child: Text(l.name)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Problem List
          Expanded(
            child: allProblemsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, _) => Center(
                child: Text('Error loading solutions: $err', style: const TextStyle(color: AppColors.wrongAnswer)),
              ),
              data: (_) {
                if (filteredProblems.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off_rounded, size: 54, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          const Text(
                            'No matching solutions found',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Try adjusting your search terms or add a new solution to your library.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const EditProblemScreen()),
                              );
                            },
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add Solution'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: filteredProblems.length,
                  itemBuilder: (context, index) {
                    final problem = filteredProblems[index];
                    return SolutionCard(
                      problem: problem,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProblemDetailScreen(problem: problem),
                          ),
                        );
                      },
                      onQuickSubmit: () {
                        ref.read(randomSelectionProvider.notifier).selectManual(problem);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StreakSaverFlowScreen(),
                          ),
                        );
                      },
                      onDelete: () {
                        if (problem.id != null) {
                          ref.read(problemListProvider.notifier).deleteProblem(problem.id!);
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditProblemScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Solution', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _buildDifficultyChip(
    WidgetRef ref,
    Difficulty? diff,
    String label,
    bool isSelected,
  ) {
    Color activeColor = AppColors.primary;
    if (diff == Difficulty.easy) activeColor = AppColors.easy;
    if (diff == Difficulty.medium) activeColor = AppColors.medium;
    if (diff == Difficulty.hard) activeColor = AppColors.hard;

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.black : AppColors.textSecondary,
        ),
      ),
      selected: isSelected,
      selectedColor: activeColor,
      backgroundColor: AppColors.surfaceElevated,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      side: BorderSide(
        color: isSelected ? activeColor : AppColors.border,
        width: 1,
      ),
      onSelected: (_) {
        ref.read(filterStateProvider.notifier).state =
            ref.read(filterStateProvider).copyWith(difficulty: diff, clearDifficulty: diff == null);
      },
    );
  }
}

