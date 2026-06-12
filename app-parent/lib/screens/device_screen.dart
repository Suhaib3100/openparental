import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();
    _loadPolicy();
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
    } catch (_) {
      // no policy yet
    }
    if (mounted) setState(() => _loadingPolicy = false);
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

  @override
  Widget build(BuildContext context) {
    final d = widget.device;
    final scheme = Theme.of(context).colorScheme;
    final s = deviceStatusStyle(d.status);

    return Scaffold(
      appBar: AppBar(title: Text(d.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ---- status summary ----
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  StatusDot(s.color, size: 12),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.label,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: s.color,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Last seen ${timeAgo(d.lastSeenAt)}'
                          '${d.lastSeenAt != null ? ' · ${DateFormat('MMM d, HH:mm').format(d.lastSeenAt!.toLocal())}' : ''}',
                          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  if (d.batteryPct != null)
                    Text(
                      '${d.batteryPct}%',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                ],
              ),
            ),
          ),
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
}
