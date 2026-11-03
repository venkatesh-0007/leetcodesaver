import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/time_utils.dart';
import '../../data/models/language.dart';
import '../../providers/app_state_providers.dart';
import '../../providers/heatmap_providers.dart';
import '../../providers/problem_providers.dart';
import '../../providers/settings_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _usernameController;
  bool _isSavingUsername = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsNotifierProvider);
    _usernameController = TextEditingController(text: settings.username);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _saveUsernameAndSync() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) return;

    setState(() => _isSavingUsername = true);
    await ref.read(settingsNotifierProvider.notifier).updateUsername(username);
    await ref.read(syncNotifierProvider.notifier).syncWithLeetCode();
    setState(() => _isSavingUsername = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Profile updated and synced for "$username"!'),
          backgroundColor: AppColors.surfaceElevated,
        ),
      );
    }
  }

  Future<void> _exportBackup() async {
    final problemDao = ref.read(problemDaoProvider);
    final problems = await problemDao.exportAll();

    final backupData = {
      'app': 'LeetStreak',
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'problems': problems,
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(backupData);
    await Clipboard.setData(ClipboardData(text: jsonStr));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Copied backup of ${problems.length} solutions to clipboard!'),
          backgroundColor: AppColors.surfaceElevated,
        ),
      );
    }
  }

  Future<void> _importBackup() async {
    final data = await Clipboard.getData('text/plain');
    if (data == null || data.text == null || data.text!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clipboard is empty! Copy your backup JSON first.')),
        );
      }
      return;
    }

    try {
      final decoded = jsonDecode(data.text!) as Map<String, dynamic>;
      final problems = decoded['problems'] as List?;
      if (problems == null || problems.isEmpty) {
        throw Exception('No problems list found in backup JSON');
      }

      final problemMaps = problems.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      final count = await ref.read(problemListProvider.notifier).importProblems(problemMaps);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Successfully restored $count solutions from backup!'),
            backgroundColor: AppColors.accepted,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to restore backup: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsNotifierProvider);
    final syncState = ref.watch(syncNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        children: [
          // Section: LeetCode Account
          _buildSectionHeader('LeetCode Account'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Public LeetCode Username',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Used to fetch your actual submission calendar heatmap via public GraphQL.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          hintText: 'Enter username (e.g. tourpran)',
                          prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _isSavingUsername || syncState.status == SyncStatus.syncing
                          ? null
                          : _saveUsernameAndSync,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      child: _isSavingUsername
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Text('Sync'),
                    ),
                  ],
                ),
                if (syncState.status == SyncStatus.error) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Error: ${syncState.errorMessage}',
                    style: const TextStyle(fontSize: 12, color: AppColors.wrongAnswer),
                  ),
                ],
                if (settings.lastSync != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Last synchronized: ${TimeUtils.formatDateTime(settings.lastSync!)}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section: Streak & Selection Preferences
          _buildSectionHeader('Streak & Selection Preferences'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Preferred Language
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Preferred Language',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Filter candidate problems for streak save',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    DropdownButton<String>(
                      value: settings.preferredLanguage,
                      dropdownColor: AppColors.surfaceElevated,
                      underline: const SizedBox(),
                      items: [
                        const DropdownMenuItem(value: 'All', child: Text('All')),
                        ...SupportedLanguage.all.map((l) => DropdownMenuItem(value: l.name, child: Text(l.name))),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(settingsNotifierProvider.notifier).updatePreferredLanguage(val);
                        }
                      },
                    ),
                  ],
                ),

                const Divider(),

                // Cooldown Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Selection Cooldown Period',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${settings.cooldownDays} days',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Avoid re-selecting problems submitted within this many days.',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                Slider(
                  value: settings.cooldownDays.toDouble(),
                  min: 1,
                  max: 30,
                  divisions: 29,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.surfaceElevated,
                  onChanged: (val) {
                    ref.read(settingsNotifierProvider.notifier).updateCooldownDays(val.toInt());
                  },
                ),

                const Divider(),

                // Demo Mode Toggle
                Material(
                  color: Colors.transparent,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Demo Mode',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text(
                      'Simulate a 24-day streak with sample heatmap data for testing without live account.',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    value: settings.isDemoMode,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) async {
                      await ref.read(settingsNotifierProvider.notifier).toggleDemoMode(val);
                      await ref.read(syncNotifierProvider.notifier).syncWithLeetCode(forceDemo: val);
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section: Backup & Restore
          _buildSectionHeader('Local Data Management'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Offline Privacy & Backup',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Your solutions are stored 100% locally on your phone in SQLite. Never sent to an external server.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _exportBackup,
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: const Text('Export JSON'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _importBackup,
                        icon: const Icon(Icons.upload_rounded, size: 18),
                        label: const Text('Import JSON'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section: About
          _buildSectionHeader('About LeetStreak'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bolt_rounded, color: AppColors.primary, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'LeetStreak v1.0.0',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Android LeetCode streak companion designed for busy exam days. Select and submit previously accepted solutions on mobile without having to boot up your laptop.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(Icons.widgets_rounded, size: 16, color: AppColors.blueAccent),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Home Screen Widget: Long-press your home screen to add the compact LeetStreak Widget.',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(Icons.tune_rounded, size: 16, color: AppColors.purpleAccent),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Quick Settings Tile: Expand your Android notification drawer to add the "Save Streak" tile.',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
