import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class LanguageBadge extends StatelessWidget {
  final String language;
  final double fontSize;

  const LanguageBadge({
    super.key,
    required this.language,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.border,
          width: 0.8,
        ),
      ),
      child: Text(
        language,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

