import 'package:flutter/material.dart';

import '../api/models.dart';
import '../theme/app_theme.dart';
import '../theme/status.dart';
import 'ui.dart';

/// One alert as a white feed card: tinted icon (with an unread badge),
/// title, time, and body — the timeline-feed pattern on the Alerts tab.
class AlertTile extends StatelessWidget {
  final AlertModel alert;
  final VoidCallback onTap;
  const AlertTile({super.key, required this.alert, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final st = alertStyle(alert.type);
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      SoftIcon(st.icon, st.color, size: 44),
                      if (!alert.read)
                        const Positioned(
                          right: -2,
                          top: -2,
                          child: StatusDot(AppColors.alert, size: 9),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      alert.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight:
                                alert.read ? FontWeight.w500 : FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    timeAgo(alert.createdAt),
                    style:
                        TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
              if (alert.body.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  alert.body,
                  style:
                      TextStyle(color: scheme.onSurfaceVariant, height: 1.35),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
