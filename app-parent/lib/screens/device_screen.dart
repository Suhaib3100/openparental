import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/models.dart';
import '../state/providers.dart';
import '../theme/status.dart';
import '../widgets/ui.dart';

class DeviceScreen extends ConsumerStatefulWidget {
  final Device device;
  const DeviceScreen({super.key, required this.device});

  @override
  ConsumerState<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends ConsumerState<DeviceScreen> {
  final _blocked = TextEditingController();
  bool _loadingPolicy = true;
  bool _busy = false;
  bool _loadingLocation = true;
  DeviceLocation? _location;

  @override
  void initState() {
    super.initState();
    _loadPolicy();
    _loadLocation();
  }

  @override
  void dispose() {
    _blocked.dispose();
    super.dispose();
  }

  Future<void> _loadPolicy() async {
    try {
      final rules = await ref.read(apiProvider).getPolicy();
      final blocked = (rules?['blockedApps'] as List?)?.cast<String>() ?? const [];
      _blocked.text = blocked.join(', ');
    } catch (_) {}
    if (mounted) setState(() => _loadingPolicy = false);
  }

  Future<void> _loadLocation() async {
    try {
      final loc = await ref.read(apiProvider).latestLocation(widget.device.id);
      if (mounted) setState(() => _location = loc);
    } catch (_) {}
    if (mounted) setState(() => _loadingLocation = false);
  }

  Future<void> _command(String type, String label) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(apiProvider).sendCommand(widget.device.id, type);
      messenger.showSnackBar(SnackBar(content: Text('$label sent')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _savePolicy() async {
    final messenger = ScaffoldMessenger.of(context);
    final apps = _blocked.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    setState(() => _busy = true);
    try {
      await ref.read(apiProvider).updatePolicy({'blockedApps': apps});
      messenger.showSnackBar(
        const SnackBar(content: Text('Saved — pushed to your devices')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openMaps(double lat, double lng) async {
    final uri =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.device;
    final scheme = Theme.of(context).colorScheme;
    final s = deviceStatusStyle(d.status);
    final initial = d.name.isNotEmpty ? d.name[0].toUpperCase() : '?';

    return Scaffold(
      appBar: AppBar(title: Text(d.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ---- hero header ----
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                      border: Border.all(color: s.color.withValues(alpha: 0.55), width: 2),
                    ),
                    child: Text(initial,
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: scheme.primary)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          StatusDot(s.color, size: 9),
                          const SizedBox(width: 6),
                          Text(s.label,
                              style: TextStyle(
                                  color: s.color, fontWeight: FontWeight.w700)),
                        ]),
                        const SizedBox(height: 4),
                        Text('Last seen ${timeAgo(d.lastSeenAt)}',
                            style: TextStyle(
                                color: scheme.onSurfaceVariant, fontSize: 13)),
                      ],
                    ),
                  ),
                  if (d.batteryPct != null)
                    Text('${d.batteryPct}%',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // ---- location ----
          const SectionLabel('Location'),
          const SizedBox(height: 12),
          _locationCard(context, scheme),
          const SizedBox(height: 28),

          // ---- remote control ----
          const SectionLabel('Remote control'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _busy ? null : () => _command('LOCK', 'Lock'),
                  icon: const Icon(Icons.lock_rounded),
                  label: const Text('Lock now'),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 130,
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _command('PING', 'Ping'),
                  icon: const Icon(Icons.wifi_tethering_rounded),
                  label: const Text('Ping'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ---- blocked apps ----
          const SectionLabel('Blocked apps'),
          const SizedBox(height: 6),
          Text(
            'Comma-separated package names. Blocked apps get bounced to the home screen.',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 12),
          if (_loadingPolicy)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            TextField(
              controller: _blocked,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'com.zhiliaoapp.musically, com.instagram.android',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _busy ? null : _savePolicy,
              child: const Text('Save & push'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _locationCard(BuildContext context, ColorScheme scheme) {
    if (_loadingLocation) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    final loc = _location;
    if (loc == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(Icons.location_off_outlined, color: scheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Text('No location yet',
                  style: TextStyle(color: scheme.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            SoftIcon(Icons.location_on_rounded, scheme.primary, size: 46),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${loc.lat.toStringAsFixed(5)}, ${loc.lng.toStringAsFixed(5)}',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    '${loc.occurredAt != null ? DateFormat('MMM d, HH:mm').format(loc.occurredAt!.toLocal()) : ''}'
                    '${loc.accuracyM != null ? ' · ±${loc.accuracyM!.round()}m' : ''}',
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _openMaps(loc.lat, loc.lng),
              child: const Text('Open'),
            ),
          ],
        ),
      ),
    );
  }
}
