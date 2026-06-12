import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final baseUrl = ref.watch(baseUrlProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // profile header
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.shield_rounded, color: scheme.primary, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your family',
                      style: Theme.of(context).textTheme.titleLarge),
                  Text('OpenParental account',
                      style: TextStyle(color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        const SectionLabel('Account'),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.dns_rounded),
                title: const Text('Backend'),
                subtitle: Text(baseUrl),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: AppColors.alert),
                title: const Text('Log out',
                    style: TextStyle(color: AppColors.alert)),
                onTap: () => ref.read(authProvider.notifier).logout(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        const SectionLabel('About'),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              const ListTile(
                title: Text('OpenParental'),
                subtitle: Text('Bypass-evident parental control'),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Version'),
                trailing: Text('0.1.0',
                    style: TextStyle(color: scheme.onSurfaceVariant)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
