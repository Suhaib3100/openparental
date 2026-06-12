import 'package:flutter/material.dart';

import '../api/models.dart';
import '../theme/status.dart';
import 'ui.dart';

class AlertTile extends StatelessWidget {
  final AlertModel alert;
  final VoidCallback onTap;
  const AlertTile({super.key, required this.alert, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final st = alertStyle(alert.type);
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SoftIcon(st.icon, st.color, size: 42),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          alert.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight:
                                    alert.read ? FontWeight.w500 : FontWeight.w700,
                              ),
                        ),
                      ),
                      Text(
                        timeAgo(alert.createdAt),
                        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    alert.body,
                    style: TextStyle(color: scheme.onSurfaceVariant, height: 1.35),
                  ),
                ],
              ),
            ),
            if (!alert.read) ...[
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: StatusDot(st.color, size: 8),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
