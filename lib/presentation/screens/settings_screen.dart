import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_settings_provider.dart';
import '../../widgets/mixvy_drawer.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsControllerProvider);
    final controller = ref.read(appSettingsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      drawer: const MixVyDrawer(),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Could not load settings: $error')),
        data: (settings) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto), label: Text('System')),
                        ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode), label: Text('Light')),
                        ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode), label: Text('Dark')),
                      ],
                      selected: <ThemeMode>{settings.themeMode},
                      onSelectionChanged: (selection) {
                        controller.updateThemeMode(selection.first);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    value: settings.notificationsEnabled,
                    secondary: const Icon(Icons.notifications_active_outlined),
                    title: const Text('Push notifications'),
                    subtitle: const Text('Control alerts for room activity and payments.'),
                    onChanged: controller.setNotificationsEnabled,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: settings.analyticsEnabled,
                    secondary: const Icon(Icons.analytics_outlined),
                    title: const Text('Anonymous analytics'),
                    subtitle: const Text('Help improve MixVy with usage insights.'),
                    onChanged: controller.setAnalyticsEnabled,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.shield_outlined),
                title: const Text('Privacy summary'),
                subtitle: Text(
                  settings.analyticsEnabled
                      ? 'Analytics sharing is enabled. You can disable it at any time.'
                      : 'Analytics sharing is disabled.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
