import 'package:flutter/material.dart';

import '../api/models.dart';
import '../theme/app_theme.dart';

enum LiveMonitoringKind { screen }

/// Connecting state for live monitoring features (reference UI).
class LiveMonitoringScreen extends StatelessWidget {
  final LiveMonitoringKind kind;
  final Device device;

  const LiveMonitoringScreen({
    super.key,
    required this.kind,
    required this.device,
  });

  String get _title => switch (kind) {
        LiveMonitoringKind.screen => 'Screen View',
      };

  String get _warning => switch (kind) {
        LiveMonitoringKind.screen =>
          "Screen viewing uses the child device's screen-capture permission, "
          'and the child app shows a banner whenever viewing is active.',
      };

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),
            Icon(Icons.devices_rounded,
                size: 80, color: AppColors.brand.withValues(alpha: 0.5)),
            const SizedBox(height: 24),
            Text(
              'Connecting to ${device.name}…',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'It takes time to connect — please wait patiently.',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted),
            ),
            const SizedBox(height: 32),
            Text(
              _warning,
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontSize: 13, height: 1.4),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          '$_title will stream once WebRTC/signaling ships')),
                );
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
