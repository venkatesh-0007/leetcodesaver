import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:leetstreak/data/services/preference_service.dart';
import 'package:leetstreak/main.dart';
import 'package:leetstreak/providers/app_state_providers.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('LeetStreakApp smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'is_demo_mode': true,
      'lc_username': 'Demo_Coder',
    });
    final prefs = await SharedPreferences.getInstance();
    final prefService = PreferenceService(prefs);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferenceServiceProvider.overrideWithValue(prefService),
        ],
        child: const LeetStreakApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('LeetStreak'), findsOneWidget);
    expect(find.text('Save Today\'s Streak'), findsOneWidget);
    expect(find.text('Submission Activity'), findsOneWidget);
  });
}
