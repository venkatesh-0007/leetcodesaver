import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'data/services/preference_service.dart';
import 'providers/app_state_providers.dart';
import 'ui/screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Dark system navigation bar and status bar styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize SharedPreferences
  final preferenceService = await PreferenceService.init();

  runApp(
    ProviderScope(
      overrides: [
        preferenceServiceProvider.overrideWithValue(preferenceService),
      ],
      child: const LeetStreakApp(),
    ),
  );
}

class LeetStreakApp extends StatelessWidget {
  final bool openStreakSaver;

  const LeetStreakApp({super.key, this.openStreakSaver = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LeetStreak',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: MainNavigationScreen(initialOpenStreakSaver: openStreakSaver),
    );
  }
}
