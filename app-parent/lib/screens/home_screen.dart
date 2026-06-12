import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/alert_tile.dart';
import '../widgets/device_card.dart';
import '../widgets/ui.dart';
import 'device_screen.dart';
import 'pairing_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _index = 0;

  static const _titles = ['Home', 'Alerts', 'Settings'];

  Future<void> _startPairing() async {
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
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      body: IndexedStack(
        index: _index,
        children: const [_DevicesView(), _AlertsView(), SettingsScreen()],
      ),
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              onPressed: _startPairing,
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Pair device'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.14),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none_rounded),
            selectedIcon: Icon(Icons.notifications_rounded),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Devices view

class _DevicesView extends ConsumerStatefulWidget {
  const _DevicesView();
  @override
  ConsumerState<_DevicesView> createState() => _DevicesViewState();
}

class _DevicesViewState extends ConsumerState<_DevicesView> {
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
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              _HeroSummary(devices: devices),
              const SizedBox(height: 20),
              if (devices.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 48),
                  child: Center(
                    child: Text(
                      'No devices yet.\nTap “Pair device” to add your child\'s phone.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                ...[
                  const SectionLabel('Devices'),
                  const SizedBox(height: 12),
                  for (final d in devices) ...[
                    DeviceCard(
                      device: d,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                            builder: (_) => DeviceScreen(device: d)),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
            ],
          );
        },
      ),
    );
  }
}

/// Greeting + a calm "all good / N need attention" overview card.
class _HeroSummary extends StatelessWidget {
  final List<Device> devices;
  const _HeroSummary({required this.devices});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final attention = devices
        .where((d) => d.status == 'DARK' || d.status == 'OFFLINE' || d.status == 'PROVISIONING')
        .length;
    final calm = attention == 0;
    final accent = calm ? AppColors.online : AppColors.attention;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
            ? 'Good afternoon'
            : 'Good evening';
    final headline = devices.isEmpty
        ? 'Add your first device'
        : calm
            ? 'Everything looks calm'
            : '$attention device${attention == 1 ? '' : 's'} need attention';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(greeting,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  calm ? Icons.check_rounded : Icons.priority_high_rounded,
                  color: accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  headline,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------- Alerts view

class _AlertsView extends ConsumerStatefulWidget {
  const _AlertsView();
  @override
  ConsumerState<_AlertsView> createState() => _AlertsViewState();
}

class _AlertsViewState extends ConsumerState<_AlertsView> {
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
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
