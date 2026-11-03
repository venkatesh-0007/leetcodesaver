import 'package:flutter/material.dart';
import '../../data/models/difficulty.dart';

class DifficultyBadge extends StatelessWidget {
  final Difficulty difficulty;
  final double fontSize;

  const DifficultyBadge({
    super.key,
    required this.difficulty,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: difficulty.color.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: difficulty.color.withAlpha(120),
          width: 0.8,
        ),
      ),
      child: Text(
        difficulty.displayName,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: difficulty.color,
        ),
      ),
    );
  }
}

