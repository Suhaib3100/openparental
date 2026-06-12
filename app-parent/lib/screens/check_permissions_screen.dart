import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../theme/status.dart';
import '../widgets/ui.dart';

/// Live permission snapshot from PERMISSION_STATE events on the child device.
class CheckPermissionsScreen extends ConsumerStatefulWidget {
  final Device device;
  const CheckPermissionsScreen({super.key, required this.device});

  @override
  ConsumerState<CheckPermissionsScreen> createState() =>
      _CheckPermissionsScreenState();
}

class _CheckPermissionsScreenState extends ConsumerState<CheckPermissionsScreen> {
  PermissionSnapshot? _snapshot;
  bool _loading = true;

  static const _labels = {
    'location': 'Location',
    'notifications': 'Notifications',
    'usageStats': 'Usage Statistics',
    'accessibility': 'Accessibility Service',
    'deviceAdmin': 'Device Admin Privileges',
    'screenCapture': 'Screen Capture Permission',
    'microphone': 'Microphone',
    'vpn': 'VPN / DNS filter',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final s = await ref.read(apiProvider).devicePermissions(widget.device.id);
      if (mounted) setState(() {
        _snapshot = s;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final s = deviceStatusStyle(widget.device.status);
    final perms = _snapshot?.permissions ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Check Permissions'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Card(
                  child: ListTile(
                    leading: StatusDot(s.color),
                    title: Text(widget.device.name),
                    subtitle: Text(
                      '${s.label}'
                      '${_snapshot?.updatedAt != null ? ' · synced ${timeAgo(_snapshot!.updatedAt)}' : ''}',
                      style: TextStyle(color: muted, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      for (var i = 0; i < _labels.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        _permRow(
                          _labels.values.elementAt(i),
                          perms[_labels.keys.elementAt(i)],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Grant missing permissions on ${widget.device.name} via the '
                  'child app onboarding screen.',
                  style: TextStyle(color: muted, fontSize: 13, height: 1.4),
                ),
              ],
            ),
    );
  }

  Widget _permRow(String label, bool? granted) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final ok = granted == true;
    final unknown = granted == null;
    return ListTile(
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            unknown ? 'Unknown' : (ok ? 'Granted' : 'Action needed'),
            style: TextStyle(
              color: unknown
                  ? muted
                  : (ok ? AppColors.online : AppColors.alert),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            unknown
                ? Icons.help_outline_rounded
                : (ok ? Icons.check_circle_rounded : Icons.warning_rounded),
            color: unknown
                ? muted
                : (ok ? AppColors.online : AppColors.alert),
            size: 20,
          ),
        ],
      ),
    );
  }
}
