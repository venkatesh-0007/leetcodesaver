import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/heatmap_day.dart';

class HeatmapWidget extends StatefulWidget {
  final Map<String, HeatmapDay> daysMap;
  final bool isDemo;

  const HeatmapWidget({
    super.key,
    required this.daysMap,
    this.isDemo = false,
  });

  @override
  State<HeatmapWidget> createState() => _HeatmapWidgetState();
}

class _HeatmapWidgetState extends State<HeatmapWidget> {
  final ScrollController _scrollController = ScrollController();
  HeatmapDay? _selectedDay;

  @override
  void initState() {
    super.initState();
    // Auto-scroll to end so user sees recent days first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Generate 52 weeks of days ending today
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Align end date to Sunday of current week so rows align Mon-Sun
    final int weekdayOffset = today.weekday % 7; // 0 for Sun, 1 for Mon...
    final endDate = today.add(Duration(days: 6 - weekdayOffset));
    final startDate = endDate.subtract(const Duration(days: 52 * 7 - 1));

    final List<List<HeatmapDay>> weeks = [];
    DateTime current = startDate;

    for (int w = 0; w < 52; w++) {
      final List<HeatmapDay> weekDays = [];
      for (int d = 0; d < 7; d++) {
        final key = '${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}';
        final day = widget.daysMap[key] ??
            HeatmapDay(
              date: current,
              count: 0,
              level: 0,
            );
        weekDays.add(day);
        current = current.add(const Duration(days: 1));
      }
      weeks.add(weekDays);
    }

    return Container(
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
                  const Icon(Icons.grid_on_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'Submission Activity',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (widget.isDemo) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(40),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.primary, width: 0.8),
                      ),
                      child: const Text(
                        'DEMO DATA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (_selectedDay != null)
                Text(
                  '${_selectedDay!.count} solves on ${DateFormat('MMM d').format(_selectedDay!.date)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Scrollable Heatmap Grid
          SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Weekday labels column
                Padding(
                  padding: const EdgeInsets.only(right: 8, top: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildWeekdayLabel('Mon'),
                      const SizedBox(height: 14),
                      _buildWeekdayLabel('Wed'),
                      const SizedBox(height: 14),
                      _buildWeekdayLabel('Fri'),
                    ],
                  ),
                ),

                // Heatmap Weeks
                Row(
                  children: weeks.map((week) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 3.5),
                      child: Column(
                        children: week.map((day) {
                          final isToday = day.date.year == today.year &&
                              day.date.month == today.month &&
                              day.date.day == today.day;
                          final isFuture = day.date.isAfter(today);

                          return GestureDetector(
                            onTap: isFuture
                                ? null
                                : () {
                                    setState(() {
                                      _selectedDay = day;
                                    });
                                  },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 3.5),
                              width: 13,
                              height: 13,
                              decoration: BoxDecoration(
                                color: isFuture ? Colors.transparent : day.color,
                                borderRadius: BorderRadius.circular(3),
                                border: isToday
                                    ? Border.all(color: AppColors.primary, width: 1.5)
                                    : Border.all(color: AppColors.borderSubtle, width: 0.5),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Heatmap Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(
                'Less',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              const SizedBox(width: 6),
              _buildLegendBox(AppColors.heatEmpty),
              const SizedBox(width: 3),
              _buildLegendBox(AppColors.heatLevel1),
              const SizedBox(width: 3),
              _buildLegendBox(AppColors.heatLevel2),
              const SizedBox(width: 3),
              _buildLegendBox(AppColors.heatLevel3),
              const SizedBox(width: 3),
              _buildLegendBox(AppColors.heatLevel4),
              const SizedBox(width: 6),
              const Text(
                'More',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayLabel(String text) {
    return SizedBox(
      height: 13,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 9,
          color: AppColors.textMuted,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildLegendBox(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: AppColors.borderSubtle, width: 0.5),
      ),
    );
  }
}

