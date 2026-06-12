import 'package:flutter/material.dart';

import '../api/models.dart';
import '../theme/status.dart';
import '../widgets/ui.dart';

/// Read-only details for one device.
class DeviceInfoScreen extends StatelessWidget {
  final Device device;
  const DeviceInfoScreen({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = deviceStatusStyle(device.status);

    Widget row(String label, Widget value) => ListTile(
          title: Text(label),
          trailing: DefaultTextStyle(
            style: TextStyle(fontSize: 15, color: scheme.onSurfaceVariant),
            child: value,
          ),
        );

    return Scaffold(
      appBar: AppBar(title: Text(device.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Card(
            child: Column(
              children: [
                row(
                  'Status',
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StatusDot(s.color, size: 8),
                      const SizedBox(width: 6),
                      Text(s.label,
                          style: TextStyle(
                              color: s.color, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                row('Last seen', Text(timeAgo(device.lastSeenAt))),
                const Divider(height: 1),
                row(
                  'Battery',
                  Text(device.batteryPct != null
                      ? '${device.batteryPct}%'
                      : '—'),
                ),
                const Divider(height: 1),
                row('Model', Text(device.model ?? '—')),
                const Divider(height: 1),
                row('Manufacturer', Text(device.manufacturer ?? '—')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
