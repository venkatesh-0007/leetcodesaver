import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/native/native_channel.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/heatmap_providers.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'library_screen.dart';
import 'settings_screen.dart';
import 'streak_saver_flow_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  final bool initialOpenStreakSaver;

  const MainNavigationScreen({super.key, this.initialOpenStreakSaver = false});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    LibraryScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();

    // Listen to native method calls (from Quick Settings tile or widget)
    NativeChannel.setMethodCallHandler(_handleNativeCall);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Sync on initial launch
      ref.read(syncNotifierProvider.notifier).syncWithLeetCode();

      if (widget.initialOpenStreakSaver) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StreakSaverFlowScreen()),
        );
      }
    });
  }

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    if (call.method == AppConstants.methodLaunchStreakSaver) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StreakSaverFlowScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.borderSubtle)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primary.withAlpha(50),
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.primary),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.code_rounded),
              selectedIcon: Icon(Icons.code_rounded, color: AppColors.primary),
              label: 'Library',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_rounded),
              selectedIcon: Icon(Icons.history_rounded, color: AppColors.primary),
              label: 'History',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded, color: AppColors.primary),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

