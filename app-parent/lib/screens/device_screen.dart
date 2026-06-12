import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../api/models.dart';
import '../state/providers.dart';

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

  Future<void> _command(String type) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(apiProvider).sendCommand(widget.device.id, type);
      messenger.showSnackBar(SnackBar(content: Text('$type sent')));
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
        const SnackBar(content: Text('Policy updated · pushed to devices')),
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
    return Scaffold(
      appBar: AppBar(title: Text(d.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _info('Status', d.status),
          if (d.batteryPct != null) _info('Battery', '${d.batteryPct}%'),
          if (d.model != null)
            _info('Model', '${d.manufacturer ?? ''} ${d.model}'.trim()),
          _info(
            'Last seen',
            d.lastSeenAt != null
                ? DateFormat('MMM d, HH:mm').format(d.lastSeenAt!.toLocal())
                : '—',
          ),
          const Divider(height: 32),
          Text('Remote control', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _busy ? null : () => _command('LOCK'),
                icon: const Icon(Icons.lock),
                label: const Text('Lock now'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy ? null : () => _command('PING'),
                icon: const Icon(Icons.wifi_tethering),
                label: const Text('Ping'),
              ),
            ),
          ]),
          const Divider(height: 32),
          Text('Blocked apps', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_loadingPolicy)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            TextField(
              controller: _blocked,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'com.zhiliaoapp.musically, com.instagram.android',
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: _busy ? null : _savePolicy,
                child: const Text('Save & push'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _info(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ]),
      );
}
