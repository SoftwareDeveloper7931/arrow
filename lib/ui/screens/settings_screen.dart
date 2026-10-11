import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/game_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(storageServiceProvider);
    final audio = ref.watch(audioServiceProvider);
    final ads = ref.watch(adsServiceProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _buildSectionHeader('Preferences', isDark),
          _buildSettingsCard(
            isDark: isDark,
            children: [
              SwitchListTile.adaptive(
                title: const Text('Sound Effects'),
                subtitle: const Text('Whoosh, gentle taps, and victory chimes'),
                value: storage.isSoundEnabled(),
                activeTrackColor: AppColors.primarySage,
                onChanged: (val) async {
                  await storage.setSoundEnabled(val);
                  audio.soundEnabled = val;
                  if (mounted) setState(() {});
                },
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              SwitchListTile.adaptive(
                title: const Text('Haptic Feedback'),
                subtitle: const Text('Vibrate gently on actions and errors'),
                value: storage.isHapticsEnabled(),
                activeTrackColor: AppColors.primarySage,
                onChanged: (val) async {
                  await storage.setHapticsEnabled(val);
                  audio.hapticsEnabled = val;
                  if (mounted) setState(() {});
                },
              ),
            ],
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('Appearance & Theme', isDark),
          _buildSettingsCard(
            isDark: isDark,
            children: [
              ListTile(
                title: const Text('Puzzle Color Palette'),
                subtitle: Text(
                  storage.getTheme().name,
                ),
                trailing: DropdownButton<GameThemeType>(
                  value: storage.getTheme(),
                  underline: const SizedBox(),
                  dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
                  items: GameThemeType.values.map((type) {
                    final theme = GameTheme.getByType(type);
                    return DropdownMenuItem(
                      value: type,
                      child: Text(theme.name),
                    );
                  }).toList(),
                  onChanged: (newTheme) {
                    if (newTheme != null) {
                      ref.read(gameControllerProvider.notifier).setTheme(newTheme);
                      if (mounted) setState(() {});
                    }
                  },
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                title: const Text('App UI Mode'),
                subtitle: Text(
                  themeMode == ThemeMode.system
                      ? 'System Default'
                      : (themeMode == ThemeMode.dark ? 'Dark Mode' : 'Light Mode'),
                ),
                trailing: DropdownButton<ThemeMode>(
                  value: themeMode,
                  underline: const SizedBox(),
                  dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
                  items: const [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text('System'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text('Light'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text('Dark'),
                    ),
                  ],
                  onChanged: (newMode) {
                    if (newMode != null) {
                      ref.read(themeModeProvider.notifier).state = newMode;
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('Monetization & Store', isDark),
          _buildSettingsCard(
            isDark: isDark,
            children: [
              ListTile(
                leading: const Icon(Icons.block_rounded, color: AppColors.primarySage),
                title: const Text('Remove Ads'),
                subtitle: Text(
                  ads.isRemoveAdsPurchased()
                      ? 'Purchased • Ads disabled permanently'
                      : 'Remove all interstitial ads (Mock in-app purchase)',
                ),
                trailing: ads.isRemoveAdsPurchased()
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.guidanceGreen)
                    : ElevatedButton(
                        onPressed: () async {
                          await ads.purchaseRemoveAds();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Ads removed successfully! (Mock Purchase)'),
                            ),
                          );
                          if (mounted) setState(() {});
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primarySage,
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                        child: const Text('Remove'),
                      ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('Game Data', isDark),
          _buildSettingsCard(
            isDark: isDark,
            children: [
              ListTile(
                leading: const Icon(Icons.restart_alt_rounded, color: AppColors.blockerRed),
                title: const Text(
                  'Reset Progress',
                  style: TextStyle(color: AppColors.blockerRed),
                ),
                subtitle: const Text('Reset levels back to 1 and clear earned stars'),
                onTap: () {
                  _showResetConfirmDialog(context, storage);
                },
              ),
            ],
          ),

          const SizedBox(height: 36),
          Center(
            child: Text(
              'Arrow Flow • Version 1.0.0\nMade with Flutter & Riverpod',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white24 : Colors.black26,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF282C37) : const Color(0xFFEAEFF5),
        ),
      ),
      child: Column(children: children),
    );
  }

  void _showResetConfirmDialog(
    BuildContext context,
    dynamic storage,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset All Progress?'),
        content: const Text(
          'This will reset your current level back to Level 1, restore default hints, and clear your star records. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await storage.resetProgress();
              ref.read(gameControllerProvider.notifier).loadLevel(1);
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Game progress reset to Level 1.')),
                );
              }
              if (mounted) setState(() {});
            },
            child: const Text(
              'Reset',
              style: TextStyle(color: AppColors.blockerRed),
            ),
          ),
        ],
      ),
    );
  }
}
