import 'package:sqflite/sqflite.dart';
import '../models/heatmap_day.dart';
import 'database_helper.dart';

class HeatmapDao {
  Future<void> saveHeatmapDays(List<HeatmapDay> days) async {
    final db = await DatabaseHelper.database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final day in days) {
        final key = '${day.date.year}-${day.date.month.toString().padLeft(2, '0')}-${day.date.day.toString().padLeft(2, '0')}';
        batch.insert(
          'heatmap_cache',
          {
            'date_key': key,
            'count': day.count,
            'level': day.level,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<Map<String, HeatmapDay>> getCachedHeatmap() async {
    final db = await DatabaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('heatmap_cache');
    final Map<String, HeatmapDay> result = {};

    for (final row in maps) {
      final dateKey = row['date_key'] as String;
      final parts = dateKey.split('-');
      if (parts.length == 3) {
        final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        result[dateKey] = HeatmapDay(
          date: date,
          count: row['count'] as int,
          level: row['level'] as int,
        );
      }
    }
    return result;
  }
}

