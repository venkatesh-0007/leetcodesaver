import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/time_utils.dart';
import '../../data/models/saved_problem.dart';
import 'difficulty_badge.dart';
import 'language_badge.dart';

class SolutionCard extends StatelessWidget {
  final SavedProblem problem;
  final VoidCallback onTap;
  final VoidCallback? onQuickSubmit;
  final VoidCallback? onDelete;

  const SolutionCard({
    super.key,
    required this.problem,
    required this.onTap,
    this.onQuickSubmit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: ID, Title, Difficulty
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (problem.leetCodeId != null) ...[
                              Text(
                                '#${problem.leetCodeId} ',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                            Expanded(
                              child: Text(
                                problem.title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            DifficultyBadge(difficulty: problem.difficulty),
                            const SizedBox(width: 8),
                            LanguageBadge(language: problem.language),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Actions menu
                  if (onDelete != null)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppColors.textMuted),
                      color: AppColors.surfaceElevated,
                      onSelected: (val) {
                        if (val == 'delete') onDelete?.call();
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded, color: AppColors.wrongAnswer, size: 18),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: AppColors.wrongAnswer)),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Footer row: last submitted & attempts info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 14,
                        color: problem.lastSubmittedDate != null
                            ? AppColors.accepted
                            : AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        problem.lastSubmittedDate != null
                            ? 'Submitted ${TimeUtils.timeAgo(problem.lastSubmittedDate!)}'
                            : 'Never submitted via app',
                        style: TextStyle(
                          fontSize: 11,
                          color: problem.lastSubmittedDate != null
                              ? AppColors.textSecondary
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  if (onQuickSubmit != null)
                    TextButton.icon(
                      onPressed: onQuickSubmit,
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        foregroundColor: AppColors.primary,
                      ),
                      icon: const Icon(Icons.bolt_rounded, size: 16),
                      label: const Text(
                        'Select',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    )
                  else
                    Text(
                      '${problem.submissionAttempts} attempts',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

