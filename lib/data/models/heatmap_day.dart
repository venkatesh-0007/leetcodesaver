import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class HeatmapDay {
  final DateTime date;
  final int count;
  final int level; // 0: none, 1: 1-2, 2: 3-5, 3: 6-9, 4: 10+

  const HeatmapDay({
    required this.date,
    required this.count,
    required this.level,
  });

  static int calculateLevel(int count) {
    if (count <= 0) return 0;
    if (count <= 2) return 1;
    if (count <= 5) return 2;
    if (count <= 9) return 3;
    return 4;
  }

  Color get color {
    switch (level) {
      case 1:
        return AppColors.heatLevel1;
      case 2:
        return AppColors.heatLevel2;
      case 3:
        return AppColors.heatLevel3;
      case 4:
        return AppColors.heatLevel4;
      case 0:
      default:
        return AppColors.heatEmpty;
    }
  }
}

