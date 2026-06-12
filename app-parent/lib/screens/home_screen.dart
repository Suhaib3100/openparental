import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models.dart';
import '../state/providers.dart';
import '../widgets/alert_tile.dart';
import '../widgets/device_card.dart';
import '../widgets/ui.dart';
import 'device_screen.dart';
import 'pairing_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _startPairing(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final pairing = await ref.read(apiProvider).createPairing();
      await navigator.push(
        MaterialPageRoute<void>(builder: (_) => PairingScreen(pairing: pairing)),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not start pairing: $e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 20,
          title: const Text('OpenParental'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Log out',
              onPressed: () => ref.read(authProvider.notifier).logout(),
            ),
            const SizedBox(width: 4),
          ],
          bottom: TabBar(
            labelColor: scheme.primary,
            unselectedLabelColor: scheme.onSurfaceVariant,
            indicatorColor: scheme.primary,
            indicatorWeight: 2.5,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            tabs: const [Tab(text: 'Devices'), Tab(text: 'Alerts')],
          ),
        ),
        body: const TabBarView(children: [_DevicesTab(), _AlertsTab()]),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _startPairing(context, ref),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Pair device'),
        ),
      ),
    );
  }
}

class _DevicesTab extends ConsumerStatefulWidget {
  const _DevicesTab();
  @override
  ConsumerState<_DevicesTab> createState() => _DevicesTabState();
}

class _DevicesTabState extends ConsumerState<_DevicesTab> {
  late Future<List<Device>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(apiProvider).devices();
  }

  Future<void> _refresh() async {
    setState(() => _future = ref.read(apiProvider).devices());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<Device>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return EmptyState(
              icon: Icons.wifi_off_rounded,
              title: "Couldn't reach the server",
              subtitle: '${snap.error}',
            );
          }
          final devices = snap.data ?? const <Device>[];
          if (devices.isEmpty) {
            return const EmptyState(
              icon: Icons.phone_iphone_rounded,
              title: 'No devices yet',
              subtitle: "Tap “Pair device” to add your child's phone.",
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: devices.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => DeviceCard(
              device: devices[i],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                    builder: (_) => DeviceScreen(device: devices[i])),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AlertsTab extends ConsumerStatefulWidget {
  const _AlertsTab();
  @override
  ConsumerState<_AlertsTab> createState() => _AlertsTabState();
}

class _AlertsTabState extends ConsumerState<_AlertsTab> {
  late Future<List<AlertModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(apiProvider).alerts();
  }

  Future<void> _refresh() async {
    setState(() => _future = ref.read(apiProvider).alerts());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<AlertModel>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final alerts = snap.data ?? const <AlertModel>[];
          if (alerts.isEmpty) {
            return const EmptyState(
              icon: Icons.check_circle_outline_rounded,
              title: 'All calm',
              subtitle: 'No alerts right now.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: alerts.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) => AlertTile(
              alert: alerts[i],
              onTap: () async {
                await ref.read(apiProvider).markAlertRead(alerts[i].id);
                _refresh();
              },
            ),
          );
        },
      ),
    );
  }
}
