import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../api/models.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/alert_tile.dart';
import '../widgets/ui.dart';

/// Full alert timeline — opened from Notice → Alerts & Request.
class AlertsRequestsScreen extends ConsumerWidget {
  final Device device;
  const AlertsRequestsScreen({super.key, required this.device});

  String _dayLabel(DateTime? dt) {
    if (dt == null) return 'Earlier';
    final now = DateTime.now();
    final day = DateTime(dt.year, dt.month, dt.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    if (diff <= 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('MMM d').format(dt);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(alertsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Alerts & Request')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(alertsProvider.future),
        child: alerts.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => EmptyState(
            icon: Icons.wifi_off_rounded,
            title: "Couldn't load alerts",
            subtitle: '$e',
          ),
          data: (list) {
            if (list.isEmpty) {
              return const EmptyState(
                icon: Icons.check_circle_outline_rounded,
                title: 'No alerts',
                subtitle: 'Low battery, offline, permission requests, and '
                    'new app installs show up here.',
              );
            }
            final sorted = [...list]
              ..sort((a, b) {
                final at = a.createdAt?.millisecondsSinceEpoch ?? 0;
                final bt = b.createdAt?.millisecondsSinceEpoch ?? 0;
                return bt.compareTo(at);
              });
            final children = <Widget>[];
            String? lastLabel;
            for (final alert in sorted) {
              final label = _dayLabel(alert.createdAt);
              if (label != lastLabel) {
                lastLabel = label;
                children.add(Padding(
                  padding:
                      EdgeInsets.only(top: children.isEmpty ? 0 : 20, bottom: 10),
                  child: _DayHeader(label),
                ));
              }
              children.add(Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AlertTile(
                  alert: alert,
                  onTap: () async {
                    await ref.read(apiProvider).markAlertRead(alert.id);
                    ref.invalidate(alertsProvider);
                  },
                ),
              ));
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: children,
            );
          },
        ),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  final String label;
  const _DayHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.brand,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
