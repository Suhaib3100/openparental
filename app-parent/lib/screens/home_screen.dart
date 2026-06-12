import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models.dart';
import '../state/providers.dart';
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('monii'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Log out',
              onPressed: () => ref.read(authProvider.notifier).logout(),
            ),
          ],
          bottom: const TabBar(
            tabs: [Tab(text: 'Devices'), Tab(text: 'Alerts')],
          ),
        ),
        body: const TabBarView(children: [_DevicesTab(), _AlertsTab()]),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _startPairing(context, ref),
          icon: const Icon(Icons.add),
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
            return ListView(children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Error: ${snap.error}'),
              ),
            ]);
          }
          final devices = snap.data ?? const <Device>[];
          if (devices.isEmpty) {
            return ListView(children: const [
              Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('No devices yet. Tap "Pair device".')),
              ),
            ]);
          }
          return ListView.builder(
            itemCount: devices.length,
            itemBuilder: (context, i) {
              final d = devices[i];
              return ListTile(
                leading: _StatusDot(status: d.status),
                title: Text(d.name),
                subtitle: Text(
                  d.batteryPct != null ? '${d.status} · ${d.batteryPct}%' : d.status,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => DeviceScreen(device: d)),
                ),
              );
            },
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
            return ListView(children: const [
              Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('No alerts.')),
              ),
            ]);
          }
          return ListView.builder(
            itemCount: alerts.length,
            itemBuilder: (context, i) {
              final a = alerts[i];
              return ListTile(
                leading: Icon(_iconFor(a.type),
                    color: a.read ? Colors.grey : Colors.blue),
                title: Text(a.title),
                subtitle: Text(a.body),
                onTap: () async {
                  await ref.read(apiProvider).markAlertRead(a.id);
                  _refresh();
                },
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'TAMPER':
        return Icons.warning_amber;
      case 'DEVICE_OFFLINE':
        return Icons.cloud_off;
      case 'GEOFENCE':
        return Icons.location_on;
      case 'UNBLOCK_REQUEST':
        return Icons.lock_open;
      case 'NEW_APP':
        return Icons.download;
      default:
        return Icons.notifications;
    }
  }
}

class _StatusDot extends StatelessWidget {
  final String status;
  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'ONLINE' => Colors.green,
      'DARK' => Colors.red,
      'OFFLINE' => Colors.grey,
      _ => Colors.orange,
    };
    return Icon(Icons.circle, size: 14, color: color);
  }
}
