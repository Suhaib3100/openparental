import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_header.dart';
import '../widgets/ui.dart';

/// Profile + app settings ("Me" tab).
class MeTab extends ConsumerWidget {
  const MeTab({super.key});

  void _whyOvert(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Why bypass-evident?'),
        content: const Text(
          'OpenParental never hides from your child. The child app shows what '
          'it reports, and protection can always be turned off — but never '
          'silently: disabling any layer raises an alert here within minutes.\n\n'
          'No covert recording, no secret screenshots, no stealth mode. '
          'Supervision your kid can verify beats spyware they\'ll route around.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final baseUrl = ref.watch(baseUrlProvider);
    final deviceCount = ref.watch(devicesProvider).value?.length;

    return HeaderShell(
      header: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your family',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w700),
                ),
                const Text(
                  'OpenParental account',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Card(
            child: ListTile(
              leading: const SoftIcon(Icons.devices_rounded, AppColors.brand),
              title: const Text('My devices'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (deviceCount != null)
                    Text(
                      '$deviceCount',
                      style: TextStyle(
                          fontSize: 15, color: scheme.onSurfaceVariant),
                    ),
                  Icon(Icons.chevron_right_rounded,
                      color: scheme.onSurfaceVariant),
                ],
              ),
              onTap: () => ref.invalidate(devicesProvider),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const SoftIcon(Icons.dns_rounded, AppColors.offline),
                  title: const Text('Server'),
                  subtitle: Text(baseUrl, maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const SoftIcon(
                      Icons.visibility_rounded, AppColors.online),
                  title: const Text('Why bypass-evident?'),
                  trailing: Icon(Icons.chevron_right_rounded,
                      color: scheme.onSurfaceVariant),
                  onTap: () => _whyOvert(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading:
                      const SoftIcon(Icons.info_rounded, AppColors.attention),
                  title: const Text('Version'),
                  trailing: Text('0.1.0',
                      style: TextStyle(color: scheme.onSurfaceVariant)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const SoftIcon(Icons.logout_rounded, AppColors.alert),
              title: const Text('Log out',
                  style: TextStyle(color: AppColors.alert)),
              onTap: () => ref.read(authProvider.notifier).logout(),
            ),
          ),
        ],
      ),
    );
  }
}
