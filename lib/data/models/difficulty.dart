import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum Difficulty {
  easy,
  medium,
  hard;

  String get displayName {
    switch (this) {
      case Difficulty.easy:
        return 'Easy';
      case Difficulty.medium:
        return 'Medium';
      case Difficulty.hard:
        return 'Hard';
    }
  }

  Color get color {
    switch (this) {
      case Difficulty.easy:
        return AppColors.easy;
      case Difficulty.medium:
        return AppColors.medium;
      case Difficulty.hard:
        return AppColors.hard;
    }
  }

  static Difficulty fromString(String value) {
    switch (value.trim().toLowerCase()) {
      case 'easy':
        return Difficulty.easy;
      case 'medium':
      case 'med':
        return Difficulty.medium;
      case 'hard':
        return Difficulty.hard;
      default:
        return Difficulty.easy;
    }
  }
}

