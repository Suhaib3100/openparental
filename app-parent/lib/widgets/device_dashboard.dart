import 'package:flutter/material.dart';

import '../api/models.dart';
import '../theme/app_theme.dart';
import 'ui.dart';

/// Usage report teaser card at the top of the Device tab.
class UsageReportCard extends StatelessWidget {
  final String screenTimeLabel;
  final String? topAppLabel;
  final VoidCallback onTap;
  const UsageReportCard({
    super.key,
    required this.screenTimeLabel,
    this.topAppLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Usage Report',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right_rounded,
                            size: 20, color: muted),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Screen Time: $screenTimeLabel',
                      style: TextStyle(color: muted, fontSize: 14),
                    ),
                    if (topAppLabel != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        topAppLabel!,
                        style: TextStyle(color: muted, fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.brand.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.bar_chart_rounded,
                    color: AppColors.brand, size: 28),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Consented screen-view launcher (no camera, no microphone).
class LiveMonitoringCard extends StatelessWidget {
  final void Function(String label) onFeatureTap;
  const LiveMonitoringCard({super.key, required this.onFeatureTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.smartphone_rounded, 'Screen View'),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Live Monitoring',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Icon(Icons.settings_rounded,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (final (icon, label) in items)
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => onFeatureTap(label),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          children: [
                            SoftIcon(icon, AppColors.brand, size: 48),
                            const SizedBox(height: 6),
                            Text(
                              label,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      height: 1.15),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Block-all-apps toggle card.
class BlockAllAppsCard extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool>? onChanged;
  const BlockAllAppsCard({
    super.key,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const SoftIcon(Icons.lock_rounded, AppColors.attention, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Block All Apps',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "All apps except 'Allowed Apps' will be blocked",
                    style: TextStyle(color: muted, fontSize: 12, height: 1.3),
                  ),
                ],
              ),
            ),
            Switch.adaptive(value: enabled, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

/// Map preview teaser — opens full location screen on tap.
class LiveLocationCard extends StatelessWidget {
  final Device device;
  final DeviceLocation? location;
  final VoidCallback onTap;
  const LiveLocationCard({
    super.key,
    required this.device,
    this.location,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final loc = location;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
              child: Row(
                children: [
                  Text(
                    'Live Location',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, size: 20, color: muted),
                ],
              ),
            ),
            Container(
              height: 140,
              width: double.infinity,
              color: AppColors.brand.withValues(alpha: 0.08),
              child: loc == null
                  ? Center(
                      child: Text(
                        'No location yet — tap to refresh',
                        style: TextStyle(color: muted, fontSize: 13),
                      ),
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        Icon(Icons.map_rounded,
                            size: 64,
                            color: AppColors.brand.withValues(alpha: 0.25)),
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${loc.lat.toStringAsFixed(4)}, '
                              '${loc.lng.toStringAsFixed(4)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// FAQ-style help strip above the footer on Device tab.
class HelpBanner extends StatelessWidget {
  final VoidCallback? onTap;
  const HelpBanner({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const SoftIcon(Icons.lightbulb_rounded, AppColors.attention,
                  size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "How to open the hidden child's app?",
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: muted),
            ],
          ),
        ),
      ),
    );
  }
}
