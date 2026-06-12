import 'package:flutter/material.dart';

import '../api/models.dart';
import '../theme/status.dart';
import '../widgets/ui.dart';

/// Everything the controller can see about one device.
class DeviceInfoScreen extends StatelessWidget {
  final Device device;
  const DeviceInfoScreen({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant;
    final s = deviceStatusStyle(device.status);

    Widget row(String label, Widget value) => ListTile(
          title: Text(label),
          trailing: DefaultTextStyle(
            style: TextStyle(fontSize: 15, color: muted),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                  child: Text(
                    'Information available to controller',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
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
                const Divider(height: 1),
                row('GPS location', const Text('See Live Location')),
                const Divider(height: 1),
                row('Installed apps', const Text('See Installed Apps')),
                const Divider(height: 1),
                row('Usage logs', const Text('See Usage Logs')),
                const Divider(height: 1),
                row('Screen time reports', const Text('See Usage Report')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                  child: Text(
                    'High-risk permissions (if enabled)',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                for (final p in const [
                  'Location',
                  'Notifications',
                  'Usage Statistics',
                  'Accessibility Service',
                  'Device Admin Privileges',
                  'Screen Capture Permission',
                  'Microphone',
                ]) ...[
                  ListTile(
                    dense: true,
                    title: Text(p, style: const TextStyle(fontSize: 14)),
                    trailing: Text('Check on device',
                        style: TextStyle(color: muted, fontSize: 13)),
                  ),
                  if (p != 'Microphone') const Divider(height: 1),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
