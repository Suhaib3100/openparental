import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models.dart';
import '../features/monii_features.dart';
import '../navigation/feature_navigator.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../theme/status.dart';
import '../widgets/device_card.dart';
import '../widgets/device_dashboard.dart';
import '../widgets/feature_tile.dart';
import '../widgets/gradient_header.dart';
import '../widgets/live_location_preview.dart';
import '../widgets/usage_report_preview.dart';
import '../widgets/ui.dart';
import 'pairing_screen.dart';

/// Device hub — matches the reference archive: usage report, live monitoring,
/// block-all toggle, live location, then sectioned feature grids.
class DevicesTab extends ConsumerStatefulWidget {
  const DevicesTab({super.key});

  @override
  ConsumerState<DevicesTab> createState() => _DevicesTabState();
}

class _DevicesTabState extends ConsumerState<DevicesTab> {
  bool _blockAllApps = false;
  bool _policyLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadPolicy();
  }

  Future<void> _loadPolicy() async {
    try {
      final rules = await ref.read(apiProvider).getPolicy();
      final schedules = rules?['schedules'] as List?;
      final blockAll = schedules?.any((s) {
            if (s is Map) return s['blockAll'] == true;
            return false;
          }) ??
          false;
      if (mounted) {
        setState(() {
          _blockAllApps = blockAll;
          _policyLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _policyLoaded = true);
    }
  }

  Future<void> _setBlockAll(Device device, bool enabled) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final existing = await ref.read(apiProvider).getPolicy() ?? {};
      final raw = existing['schedules'];
      final schedules = <Map<String, dynamic>>[];
      if (raw is List) {
        for (final s in raw) {
          if (s is Map<String, dynamic> && s['blockAll'] != true) {
            schedules.add(s);
          } else if (s is Map && s['blockAll'] != true) {
            schedules.add(Map<String, dynamic>.from(s));
          }
        }
      }
      if (enabled) {
        schedules.add({
          'start': '00:00',
          'end': '23:59',
          'blockAll': true,
        });
      }
      await ref.read(apiProvider).mergePolicy({
        ...existing,
        'schedules': schedules,
      });
      setState(() => _blockAllApps = enabled);
      messenger.showSnackBar(
        SnackBar(
          content: Text(enabled ? 'Block all apps enabled' : 'Block all apps off'),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _startPairing() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final pairing = await ref.read(apiProvider).createPairing();
      await navigator.push(
        MaterialPageRoute<void>(builder: (_) => PairingScreen(pairing: pairing)),
      );
      ref.invalidate(devicesProvider);
    } catch (e) {
      messenger
          .showSnackBar(SnackBar(content: Text('Could not start pairing: $e')));
    }
  }

  Future<void> _command(String deviceId, String type, String label) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(apiProvider).sendCommand(deviceId, type);
      messenger.showSnackBar(SnackBar(content: Text('$label sent')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  void _switchDevice(List<Device> devices) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            for (final d in devices) ...[
              DeviceCard(
                device: d,
                onTap: () {
                  ref.read(selectedDeviceIdProvider.notifier).state = d.id;
                  Navigator.pop(sheet);
                },
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  void _openFeature(Device device, MoniiFeatureId id) {
    FeatureNavigator.open(
      context,
      id: id,
      device: device,
      sendCommand: (type, label) => _command(device.id, type, label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final devicesAsync = ref.watch(devicesProvider);
    final selectedId = ref.watch(selectedDeviceIdProvider);

    return devicesAsync.when(
      loading: () => const HeaderShell(
        header: Row(children: [Expanded(child: HeaderTitle('Device'))]),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => HeaderShell(
        header: const Row(children: [Expanded(child: HeaderTitle('Device'))]),
        body: RefreshIndicator(
          onRefresh: () => ref.refresh(devicesProvider.future),
          child: EmptyState(
            icon: Icons.wifi_off_rounded,
            title: "Couldn't reach the server",
            subtitle: '$e',
          ),
        ),
      ),
      data: (devices) {
        if (devices.isEmpty) {
          return HeaderShell(
            header:
                const Row(children: [Expanded(child: HeaderTitle('Device'))]),
            body: Builder(builder: (context) {
              final muted = Theme.of(context).colorScheme.onSurfaceVariant;
              return ListView(
                padding: const EdgeInsets.fromLTRB(32, 60, 32, 32),
                children: [
                  Icon(Icons.smartphone, size: 44, color: muted),
                  const SizedBox(height: 16),
                  Text(
                    'No devices yet',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Pair your child's phone to start — they'll see "
                    'everything this app does.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: muted),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _startPairing,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Pair your first device'),
                  ),
                ],
              );
            }),
          );
        }

        final device = devices.firstWhere(
          (d) => d.id == selectedId,
          orElse: () => devices.first,
        );

        return HeaderShell(
          header: _DeviceHeader(
            device: device,
            canSwitch: devices.length > 1,
            onSwitch: () => _switchDevice(devices),
            onAdd: _startPairing,
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await ref.refresh(devicesProvider.future);
              await _loadPolicy();
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                UsageReportPreview(device: device),
                const SizedBox(height: 12),
                LiveMonitoringCard(
                  onFeatureTap: (label) {
                    final id = switch (label) {
                      'Remote Camera' => MoniiFeatureId.remoteCamera,
                      'Screen Mirroring' => MoniiFeatureId.screenMirroring,
                      _ => MoniiFeatureId.oneWayAudio,
                    };
                    _openFeature(device, id);
                  },
                ),
                const SizedBox(height: 12),
                BlockAllAppsCard(
                  enabled: _blockAllApps,
                  onChanged: _policyLoaded
                      ? (v) => _setBlockAll(device, v)
                      : null,
                ),
                const SizedBox(height: 12),
                LiveLocationPreview(device: device),
                const SizedBox(height: 16),
                for (final entry in kDeviceSections.entries) ...[
                  FeatureSection(
                    title: entry.key,
                    tiles: [
                      for (final fid in entry.value)
                        _tile(device, fid),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                HelpBanner(
                  onTap: () {
                    showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Child app access"),
                        content: const Text(
                          'The managed app stays visible on the home screen '
                          'and in Settings. If your launcher hides it, search '
                          'for "Monii" or open it from the pairing notification.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Got it'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Visible by design — your child sees everything this app does.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _tile(Device device, MoniiFeatureId id) {
    final f = featureById(id);
    return FeatureTile(
      icon: f.icon,
      label: f.title,
      color: f.color,
      badge: f.badge,
      onTap: () => _openFeature(device, id),
    );
  }
}

class _DeviceHeader extends StatelessWidget {
  final Device device;
  final bool canSwitch;
  final VoidCallback onSwitch;
  final VoidCallback onAdd;
  const _DeviceHeader({
    required this.device,
    required this.canSwitch,
    required this.onSwitch,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final s = deviceStatusStyle(device.status);
    final initial =
        device.name.isNotEmpty ? device.name[0].toUpperCase() : '?';
    final modelLabel = device.model ?? device.name;

    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          child: Text(
            initial,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: canSwitch ? onSwitch : null,
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        modelLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (canSwitch)
                      const Icon(Icons.expand_more_rounded,
                          color: Colors.white70, size: 22),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  StatusDot(s.color, size: 8),
                  const SizedBox(width: 6),
                  Text(
                    s.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      '${device.batteryPct != null ? ' · ${device.batteryPct}%' : ''}'
                      ' · ${timeAgo(device.lastSeenAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          tooltip: 'Pair a device',
        ),
      ],
    );
  }
}
