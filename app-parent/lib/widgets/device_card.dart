import 'package:flutter/material.dart';

import '../api/models.dart';
import '../theme/app_theme.dart';
import '../theme/status.dart';
import 'ui.dart';

class DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback onTap;
  const DeviceCard({super.key, required this.device, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = deviceStatusStyle(device.status);
    final scheme = Theme.of(context).colorScheme;
    final initial = device.name.isNotEmpty ? device.name[0].toUpperCase() : '?';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                  border: Border.all(color: s.color.withValues(alpha: 0.55), width: 2),
                ),
                child: Text(
                  initial,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        StatusDot(s.color, size: 8),
                        const SizedBox(width: 6),
                        Text(
                          s.label,
                          style: TextStyle(
                            color: s.color,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '  ·  ${timeAgo(device.lastSeenAt)}',
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (device.batteryPct != null) _Battery(device.batteryPct!),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _Battery extends StatelessWidget {
  final int pct;
  const _Battery(this.pct);

  @override
  Widget build(BuildContext context) {
    final low = pct <= 20;
    final color = low ? AppColors.alert : Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Icon(
          low ? Icons.battery_alert_rounded : Icons.battery_full_rounded,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 2),
        Text(
          '$pct%',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}
