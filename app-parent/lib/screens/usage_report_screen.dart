import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

/// Screen-time report from USAGE_SUMMARY events on the backend.
class UsageReportScreen extends ConsumerStatefulWidget {
  final Device device;
  const UsageReportScreen({super.key, required this.device});

  @override
  ConsumerState<UsageReportScreen> createState() => _UsageReportScreenState();
}

class _UsageReportScreenState extends ConsumerState<UsageReportScreen> {
  UsageReport? _report;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await ref.read(apiProvider).usageReport(widget.device.id);
      if (mounted) setState(() {
        _report = r;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmt(int mins) {
    if (mins <= 0) return '—';
    if (mins < 60) return '$mins min';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m > 0 ? '$h hr $m min' : '$h hr';
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final report = _report;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Usage Report'),
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
                  color: AppColors.online.withValues(alpha: 0.12),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Screen Time',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _fmt(report?.totalMinutes ?? 0),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              if (report?.updatedAt != null)
                                Text(
                                  'Updated ${timeAgo(report!.updatedAt)}',
                                  style: TextStyle(color: muted, fontSize: 13),
                                ),
                            ],
                          ),
                        ),
                        const Text('📊', style: TextStyle(fontSize: 36)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (report != null && report.minutesByApp.isNotEmpty)
                  Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                          child: Text(
                            'By app',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        for (final entry in report.minutesByApp.entries
                            .toList()
                          ..sort((a, b) => b.value.compareTo(a.value)))
                          ListTile(
                            dense: true,
                            title: Text(entry.key,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            trailing: Text(_fmt(entry.value),
                                style: TextStyle(
                                    color: muted, fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                  )
                else
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Text(
                        'Waiting for ${widget.device.name} to report usage. '
                        'Grant Usage Access on the child device.',
                        style: TextStyle(color: muted, height: 1.4),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
