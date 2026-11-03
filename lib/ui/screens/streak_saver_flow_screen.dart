import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/time_utils.dart';
import '../../data/models/language.dart';
import '../../data/models/submission_attempt.dart';
import '../../providers/problem_providers.dart';
import '../../providers/submission_providers.dart';
import '../widgets/difficulty_badge.dart';
import '../widgets/language_badge.dart';
import 'authenticated_submission_webview_screen.dart';

class StreakSaverFlowScreen extends ConsumerStatefulWidget {
  const StreakSaverFlowScreen({super.key});

  @override
  ConsumerState<StreakSaverFlowScreen> createState() => _StreakSaverFlowScreenState();
}

class _StreakSaverFlowScreenState extends ConsumerState<StreakSaverFlowScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(randomSelectionProvider.notifier).pickEligibleProblem();
    });
  }

  Future<void> _startSubmission() async {
    final selectionState = ref.read(randomSelectionProvider);
    final problem = selectionState.selectedProblem;
    if (problem == null) return;

    // Open Webview
    final verdict = await Navigator.push<SubmissionVerdict>(
      context,
      MaterialPageRoute(
        builder: (_) => AuthenticatedSubmissionWebviewScreen(problem: problem),
      ),
    );

    if (verdict != null) {
      if (!mounted) return;
      await ref.read(submissionHistoryProvider.notifier).recordSubmission(
            problemId: problem.id ?? 0,
            problemTitle: problem.title,
            problemSlug: problem.slug,
            language: problem.language,
            verdict: verdict,
          );

      if (!mounted) return;
      if (verdict == SubmissionVerdict.accepted) {
        _showSuccessDialog(problem.title);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission recorded as ${verdict.displayName}.'),
            backgroundColor: AppColors.surfaceElevated,
          ),
        );
      }
    }
  }

  void _showSuccessDialog(String title) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.accepted,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Streak Secured!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Accepted submission for "$title" has been verified and recorded.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx); // Close dialog
                Navigator.pop(context); // Return to dashboard
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Back to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(randomSelectionProvider);
    final problem = state.selectedProblem;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Save Today\'s Streak'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            tooltip: 'Pick Another Solution',
            onPressed: state.isLoading
                ? null
                : () => ref.read(randomSelectionProvider.notifier).reRoll(),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : problem == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.folder_off_rounded, size: 56, color: AppColors.textMuted),
                        const SizedBox(height: 16),
                        Text(
                          state.message ?? 'No eligible solutions found.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('Go to Library'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Problem Info Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    DifficultyBadge(difficulty: problem.difficulty),
                                    const SizedBox(width: 8),
                                    LanguageBadge(language: problem.language),
                                  ],
                                ),
                                if (problem.lastSubmittedDate != null)
                                  Text(
                                    'Last: ${TimeUtils.timeAgo(problem.lastSubmittedDate!)}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              problem.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (problem.notes != null && problem.notes!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                problem.notes!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Code Preview Card
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.code_rounded, size: 18, color: AppColors.primary),
                              SizedBox(width: 6),
                              Text(
                                'Solution Code',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: () =>
                                ref.read(randomSelectionProvider.notifier).reRoll(),
                            icon: const Icon(Icons.shuffle_rounded, size: 16),
                            label: const Text('Pick Another'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: HighlightView(
                            problem.sourceCode,
                            language: SupportedLanguage.fromName(problem.language).highlightLanguage,
                            theme: atomOneDarkTheme,
                            padding: const EdgeInsets.all(16),
                            textStyle: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
      bottomNavigationBar: problem == null
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                child: ElevatedButton.icon(
                  onPressed: _startSubmission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  icon: const Icon(Icons.bolt_rounded, size: 20),
                  label: const Text(
                    'Proceed to LeetCode Submission',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
    );
  }
}
