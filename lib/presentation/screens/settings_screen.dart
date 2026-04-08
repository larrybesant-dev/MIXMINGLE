import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/app_settings_provider.dart';
import '../../widgets/mixvy_drawer.dart';
import '../../features/beta/beta_tester_provider.dart';
import '../../features/profile/widgets/device_settings_panel.dart';
import '../../features/after_dark/providers/after_dark_provider.dart';

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
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: settings.localeCode,
                      decoration: const InputDecoration(
                        labelText: 'Language',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'en', child: Text('English')),
                        DropdownMenuItem(value: 'es', child: Text('Espa\u00f1ol')),
                        DropdownMenuItem(value: 'fr', child: Text('Fran\u00e7ais')),
                      ],
                      onChanged: (value) {
                        if (value == null || value.isEmpty) return;
                        controller.setLocaleCode(value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Camera & Microphone', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    const DeviceSettingsPanel(),
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
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.gavel_outlined),
                    title: const Text('Terms of Service'),
                    subtitle: Text(
                      settings.hasAcceptedCurrentLegal
                          ? 'Accepted version ${settings.legalAcceptedVersion}'
                          : 'Not accepted yet',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/legal/terms'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('Privacy Policy'),
                    subtitle: const Text('Read how MixVy uses and protects your data.'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/legal/privacy'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.verified_user_outlined),
                title: const Text('Account Verification'),
                subtitle: const Text('Request a verified badge for your profile.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/verification'),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.manage_accounts_outlined),
                title: const Text('Account Center'),
                subtitle: const Text('Email verification, password reset, and account deletion.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/account'),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('App Info & Diagnostics'),
                subtitle: const Text('Version, build number, environment, and runtime mode.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/about'),
              ),
            ),
            // Beta tester section — only visible when betaTester == true
            Builder(builder: (context) {
              final isBeta = ref.watch(isBetaTesterProvider).valueOrNull ?? false;
              if (!isBeta) return const SizedBox.shrink();
              return Column(
                children: [
                  const SizedBox(height: 12),
                  Card(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    child: ListTile(
                      leading: const Icon(Icons.science_outlined),
                      title: const Text('Beta Feedback'),
                      subtitle: const Text('You are a beta tester. Submit your checklist here.'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/beta-feedback'),
                    ),
                  ),
                ],
              );
            }),
            // ── After Dark ────────────────────────────────────────────────
            const SizedBox(height: 12),
            _AfterDarkSettingsCard(),
          ],
        ),
      ),
    );
  }
}

class _AfterDarkSettingsCard extends ConsumerWidget {
  const _AfterDarkSettingsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabledAsync  = ref.watch(afterDarkEnabledProvider);
    final sessionActive = ref.watch(afterDarkSessionProvider);
    final controller    = ref.read(afterDarkControllerProvider);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1E0D16),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: enabledAsync.when(
          loading: () => const ListTile(
            leading: Icon(Icons.local_fire_department_rounded,
                color: Color(0xFFE0142A)),
            title: Text('MixVy After Dark'),
            trailing: SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (_, __) => const ListTile(
            leading: Icon(Icons.local_fire_department_rounded,
                color: Color(0xFFE0142A)),
            title: Text('MixVy After Dark'),
            subtitle: Text('Unavailable'),
          ),
          data: (enabled) {
            if (!enabled) {
              return ListTile(
                leading: const Icon(Icons.local_fire_department_rounded,
                    color: Color(0xFFE0142A)),
                title: const Text('MixVy After Dark',
                    style: TextStyle(color: Color(0xFFF5E8EE))),
                subtitle: const Text('18+ adult content. Tap to enable.',
                    style: TextStyle(color: Color(0xFFBB96A4))),
                trailing: FilledButton(
                  onPressed: () => context.go('/after-dark/setup'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE0142A),
                  ),
                  child: const Text('Enable'),
                ),
              );
            }

            // Enabled — show Enter / Disable options
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.local_fire_department_rounded,
                          color: Color(0xFFE0142A), size: 22),
                      SizedBox(width: 10),
                      Text('MixVy After Dark',
                          style: TextStyle(
                            color: Color(0xFFF5E8EE),
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          )),
                      SizedBox(width: 8),
                      _EnabledChip(),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'PIN-protected adult mode. Keep it locked when not in use.',
                    style: TextStyle(
                        color: Color(0xFFBB96A4), fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: () => context.go(
                          sessionActive
                              ? '/after-dark'
                              : '/after-dark/unlock',
                        ),
                        icon: const Icon(Icons.door_front_door_outlined,
                            size: 18),
                        label: Text(
                            sessionActive ? 'Enter' : 'Unlock'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFE0142A),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (sessionActive)
                        OutlinedButton.icon(
                          onPressed: () => controller.lock(),
                          icon: const Icon(Icons.lock_outline_rounded,
                              size: 18,
                              color: Color(0xFFBB96A4)),
                          label: const Text('Lock',
                              style:
                                  TextStyle(color: Color(0xFFBB96A4))),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: Color(0xFF5A2A3A)),
                          ),
                        ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _confirmDisable(
                            context, ref, controller),
                        child: const Text('Disable',
                            style: TextStyle(
                                color: Color(0xFF9E9E9E),
                                fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmDisable(
    BuildContext context,
    WidgetRef ref,
    AfterDarkController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Disable After Dark?'),
        content: const Text(
            'Your PIN and settings will be cleared. You can re-enable anytime.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Disable',
                style: TextStyle(color: Color(0xFFE0142A))),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.disable();
  }
}

class _EnabledChip extends StatelessWidget {
  const _EnabledChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE0142A).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
            color: const Color(0xFFE0142A).withValues(alpha: 0.5)),
      ),
      child: const Text('ON',
          style: TextStyle(
            color: Color(0xFFE0142A),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          )),
    );
  }
}
