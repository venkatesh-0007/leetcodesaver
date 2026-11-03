import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class StatsSummaryCard extends StatelessWidget {
  final int streak;
  final int totalActiveDays;
  final int totalSavedSolutions;
  final bool isSolvedToday;
  final int? easyCount;
  final int? mediumCount;
  final int? hardCount;

  const StatsSummaryCard({
    super.key,
    required this.streak,
    required this.totalActiveDays,
    required this.totalSavedSolutions,
    required this.isSolvedToday,
    this.easyCount,
    this.mediumCount,
    this.hardCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Today Status Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSolvedToday
                ? AppColors.accepted.withAlpha(20)
                : AppColors.wrongAnswer.withAlpha(20),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSolvedToday
                  ? AppColors.accepted.withAlpha(80)
                  : AppColors.wrongAnswer.withAlpha(80),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSolvedToday
                    ? Icons.check_circle_rounded
                    : Icons.warning_amber_rounded,
                color: isSolvedToday ? AppColors.accepted : AppColors.wrongAnswer,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSolvedToday ? "Today's Streak is Saved!" : "Today's Streak at Risk",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isSolvedToday ? AppColors.accepted : AppColors.wrongAnswer,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isSolvedToday
                          ? "Great job! Your LeetCode streak is secured for today."
                          : "Submit a solution before midnight to keep your streak alive.",
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Grid of 3 stats
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                icon: Icons.local_fire_department_rounded,
                iconColor: AppColors.primary,
                title: 'Streak',
                value: '$streak',
                unit: 'days',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricTile(
                icon: Icons.calendar_today_rounded,
                iconColor: AppColors.blueAccent,
                title: 'Active Days',
                value: '$totalActiveDays',
                unit: 'days',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricTile(
                icon: Icons.code_rounded,
                iconColor: AppColors.purpleAccent,
                title: 'Solutions',
                value: '$totalSavedSolutions',
                unit: 'saved',
              ),
            ),
          ],
        ),

        // LeetCode Solved Breakdown (if profile connected)
        if (easyCount != null && mediumCount != null && hardCount != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDifficultyCount('Easy', easyCount!, AppColors.easy),
                Container(height: 20, width: 1, color: AppColors.border),
                _buildDifficultyCount('Medium', mediumCount!, AppColors.medium),
                Container(height: 20, width: 1, color: AppColors.border),
                _buildDifficultyCount('Hard', hardCount!, AppColors.hard),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: iconColor, size: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyCount(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

