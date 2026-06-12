import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/monii_features.dart';
import '../navigation/feature_navigator.dart';
import '../state/providers.dart';
import '../widgets/gradient_header.dart';
import '../widgets/notice_row.dart';
import '../widgets/ui.dart';

/// Notice tab — feed of monitoring categories (reference archive layout).
class AlertsTab extends ConsumerWidget {
  const AlertsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(devicesProvider);
    final alertsAsync = ref.watch(alertsProvider);
    final selectedId = ref.watch(selectedDeviceIdProvider);

    return HeaderShell(
      header: const Row(children: [Expanded(child: HeaderTitle('Notice'))]),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(devicesProvider);
          ref.invalidate(alertsProvider);
          await ref.read(devicesProvider.future);
          await ref.read(alertsProvider.future);
        },
        child: devicesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => EmptyState(
            icon: Icons.wifi_off_rounded,
            title: "Couldn't load devices",
            subtitle: '$e',
          ),
          data: (devices) {
            if (devices.isEmpty) {
              return const EmptyState(
                icon: Icons.notifications_none_rounded,
                title: 'Pair a device first',
                subtitle: 'Notice feed fills in once a child device is linked.',
              );
            }
            final device = devices.firstWhere(
              (d) => d.id == selectedId,
              orElse: () => devices.first,
            );
            final latestAlert = alertsAsync.valueOrNull?.isNotEmpty == true
                ? alertsAsync.value!.first
                : null;
            final unreadAlerts =
                alertsAsync.valueOrNull?.where((a) => !a.read).length ?? 0;

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                for (final f in noticeFeatures()) ...[
                  NoticeRow(
                    icon: f.icon,
                    color: f.color,
                    title: f.title,
                    subtitle: noticePreview(
                      f.id,
                      device: device,
                      latestAlert: f.id == MoniiFeatureId.alertsAndRequests
                          ? latestAlert
                          : null,
                    ),
                    showBadge: f.id == MoniiFeatureId.alertsAndRequests &&
                        unreadAlerts > 0,
                    onTap: () => FeatureNavigator.open(
                      context,
                      id: f.id,
                      device: device,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
