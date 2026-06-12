import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../theme/status.dart';
import '../widgets/device_card.dart';
import '../widgets/feature_tile.dart';
import '../widgets/gradient_header.dart';
import '../widgets/ui.dart';
import 'blocked_apps_screen.dart';
import 'device_info_screen.dart';
import 'location_screen.dart';
import 'pairing_screen.dart';

/// Device hub: gradient header with a device selector, then sectioned
/// feature grids (the reference "Device" tab pattern).
class DevicesTab extends ConsumerWidget {
  const DevicesTab({super.key});

  Future<void> _startPairing(BuildContext context, WidgetRef ref) async {
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

  Future<void> _command(BuildContext context, WidgetRef ref, String deviceId,
      String type, String label) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(apiProvider).sendCommand(deviceId, type);
      messenger.showSnackBar(SnackBar(content: Text('$label sent')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  void _switchDevice(
      BuildContext context, WidgetRef ref, List<Device> devices) {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(devicesProvider);
    final selectedId = ref.watch(selectedDeviceIdProvider);

    return devicesAsync.when(
      loading: () => const HeaderShell(
        header: Row(children: [Expanded(child: HeaderTitle('Devices'))]),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => HeaderShell(
        header: const Row(children: [Expanded(child: HeaderTitle('Devices'))]),
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
                const Row(children: [Expanded(child: HeaderTitle('Devices'))]),
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
                    onPressed: () => _startPairing(context, ref),
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
            onSwitch: () => _switchDevice(context, ref, devices),
            onAdd: () => _startPairing(context, ref),
          ),
          body: RefreshIndicator(
            onRefresh: () => ref.refresh(devicesProvider.future),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                FeatureSection(
                  title: 'Remote control',
                  tiles: [
                    FeatureTile(
                      icon: Icons.lock_rounded,
                      label: 'Lock now',
                      color: AppColors.alert,
                      onTap: () =>
                          _command(context, ref, device.id, 'LOCK', 'Lock'),
                    ),
                    FeatureTile(
                      icon: Icons.wifi_tethering_rounded,
                      label: 'Ping',
                      color: AppColors.brand,
                      onTap: () =>
                          _command(context, ref, device.id, 'PING', 'Ping'),
                    ),
                    FeatureTile(
                      icon: Icons.location_on_rounded,
                      label: 'Locate',
                      color: AppColors.online,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                            builder: (_) => LocationScreen(device: device)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FeatureSection(
                  title: 'Rules & device',
                  tiles: [
                    FeatureTile(
                      icon: Icons.block_rounded,
                      label: 'Blocked apps',
                      color: AppColors.attention,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                            builder: (_) => const BlockedAppsScreen()),
                      ),
                    ),
                    FeatureTile(
                      icon: Icons.smartphone,
                      label: 'Device info',
                      color: AppColors.offline,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                            builder: (_) => DeviceInfoScreen(device: device)),
                      ),
                    ),
                    FeatureTile(
                      icon: Icons.qr_code_rounded,
                      label: 'Add device',
                      color: AppColors.brand,
                      onTap: () => _startPairing(context, ref),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
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
                        device.name,
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
