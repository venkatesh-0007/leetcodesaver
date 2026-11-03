import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class StreakFlameBadge extends StatelessWidget {
  final int streak;
  final bool isSolvedToday;
  final double size;

  const StreakFlameBadge({
    super.key,
    required this.streak,
    required this.isSolvedToday,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isSolvedToday
            ? AppColors.primary.withAlpha(30)
            : AppColors.wrongAnswer.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSolvedToday
              ? AppColors.primary.withAlpha(120)
              : AppColors.wrongAnswer.withAlpha(80),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            color: isSolvedToday ? AppColors.primary : AppColors.wrongAnswer,
            size: size,
          ),
          const SizedBox(width: 4),
          Text(
            '$streak',
            style: TextStyle(
              fontSize: size * 0.7,
              fontWeight: FontWeight.w800,
              color: isSolvedToday ? AppColors.primary : AppColors.wrongAnswer,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            streak == 1 ? 'day' : 'days',
            style: TextStyle(
              fontSize: size * 0.45,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

