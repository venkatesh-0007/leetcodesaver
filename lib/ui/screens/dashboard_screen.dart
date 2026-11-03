import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/time_utils.dart';
import '../../data/models/saved_problem.dart';
import '../../providers/heatmap_providers.dart';
import '../../providers/problem_providers.dart';
import '../../providers/settings_providers.dart';
import '../../providers/submission_providers.dart';
import '../widgets/heatmap_widget.dart';
import '../widgets/solution_card.dart';
import '../widgets/stats_summary_card.dart';
import '../widgets/streak_flame_badge.dart';
import 'problem_detail_screen.dart';
import 'streak_saver_flow_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final settings = ref.watch(settingsNotifierProvider);
    final heatmapDays = ref.watch(heatmapProvider);
    final syncState = ref.watch(syncNotifierProvider);
    final isSolvedToday = ref.watch(isStreakSolvedTodayProvider);
    final problemsAsync = ref.watch(problemListProvider);

    final totalSaved = problemsAsync.maybeWhen(
      data: (list) => list.length,
      orElse: () => 0,
    );

    final recentProblems = problemsAsync.maybeWhen(
      data: (list) => list.take(3).toList(),
      orElse: () => <SavedProblem>[],
    );

    final streak = profile?.currentStreak ?? 0;
    final activeDays = profile?.totalActiveDays ?? 0;
    final isDemo = settings.isDemoMode || (profile?.isDemo ?? false);
    final username = settings.username.isNotEmpty ? settings.username : 'Not Connected';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withAlpha(80)),
              ),
              child: const Icon(
                Icons.bolt_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              AppConstants.appName,
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: syncState.status == SyncStatus.syncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  )
                : const Icon(Icons.sync_rounded),
            tooltip: 'Sync with LeetCode',
            onPressed: syncState.status == SyncStatus.syncing
                ? null
                : () => ref.read(syncNotifierProvider.notifier).syncWithLeetCode(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surfaceElevated,
        onRefresh: () async {
          await ref.read(syncNotifierProvider.notifier).syncWithLeetCode();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Connection Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.surfaceElevated,
                      child: Text(
                        username.isNotEmpty ? username[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  username,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (isDemo ? AppColors.primary : AppColors.accepted).withAlpha(30),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isDemo ? 'DEMO' : (profile?.isConnected == true ? 'SYNCED' : 'LOCAL'),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: isDemo ? AppColors.primary : AppColors.accepted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            settings.lastSync != null
                                ? 'Last synced: ${TimeUtils.timeAgo(settings.lastSync!)}'
                                : 'Pull down to sync profile',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StreakFlameBadge(streak: streak, isSolvedToday: isSolvedToday),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Prominent CTA Button: Save Today's Streak
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StreakSaverFlowScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(54),
                  elevation: 2,
                  shadowColor: AppColors.primary.withAlpha(80),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.bolt_rounded, size: 24, color: Colors.black),
                    const SizedBox(width: 8),
                    Text(
                      isSolvedToday ? 'Submit Another Solution' : 'Save Today\'s Streak',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Stats Summary
              StatsSummaryCard(
                streak: streak,
                totalActiveDays: activeDays,
                totalSavedSolutions: totalSaved,
                isSolvedToday: isSolvedToday,
                easyCount: profile?.easySolved,
                mediumCount: profile?.mediumSolved,
                hardCount: profile?.hardSolved,
              ),

              const SizedBox(height: 16),

              // Heatmap Calendar
              HeatmapWidget(
                daysMap: heatmapDays,
                isDemo: isDemo,
              ),

              const SizedBox(height: 20),

              // Recently Added Saved Questions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recently Added Solutions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '$totalSaved total',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (recentProblems.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.code_off_rounded, size: 36, color: AppColors.textMuted),
                      SizedBox(height: 8),
                      Text(
                        'No solutions in library',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                )
              else
                ...recentProblems.map(
                  (p) => SolutionCard(
                    problem: p,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProblemDetailScreen(problem: p),
                        ),
                      );
                    },
                    onQuickSubmit: () {
                      ref.read(randomSelectionProvider.notifier).selectManual(p);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StreakSaverFlowScreen(),
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

