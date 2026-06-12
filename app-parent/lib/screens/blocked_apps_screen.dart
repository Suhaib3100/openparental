import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

/// Family blocked-apps policy editor. Saving pushes the new policy to every
/// paired device.
class BlockedAppsScreen extends ConsumerStatefulWidget {
  const BlockedAppsScreen({super.key});

  @override
  ConsumerState<BlockedAppsScreen> createState() => _BlockedAppsScreenState();
}

class _BlockedAppsScreenState extends ConsumerState<BlockedAppsScreen> {
  final _blocked = TextEditingController();
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _blocked.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final rules = await ref.read(apiProvider).getPolicy();
      final blocked =
          (rules?['blockedApps'] as List?)?.cast<String>() ?? const [];
      _blocked.text = blocked.join(', ');
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
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
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Blocked apps')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const SoftIcon(
                            Icons.block_rounded, AppColors.attention),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Blocked apps are bounced back to the home screen '
                            'on every paired device. The child sees that the '
                            'app is blocked — nothing happens silently.',
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const SectionLabel('Package names'),
                const SizedBox(height: 10),
                TextField(
                  controller: _blocked,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    hintText:
                        'com.zhiliaoapp.musically, com.instagram.android',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy ? null : _save,
                  child: const Text('Save & push'),
                ),
              ],
            ),
    );
  }
}
