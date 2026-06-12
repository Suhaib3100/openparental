import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models.dart';
import '../features/monii_features.dart';
import '../navigation/feature_navigator.dart';
import '../state/providers.dart';
import 'device_dashboard.dart';

/// Fetches usage report summary for the Device tab card.
class UsageReportPreview extends ConsumerStatefulWidget {
  final Device device;
  const UsageReportPreview({super.key, required this.device});

  @override
  ConsumerState<UsageReportPreview> createState() => _UsageReportPreviewState();
}

class _UsageReportPreviewState extends ConsumerState<UsageReportPreview> {
  UsageReport? _report;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(UsageReportPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.device.id != widget.device.id) _load();
  }

  Future<void> _load() async {
    try {
      final r = await ref.read(apiProvider).usageReport(widget.device.id);
      if (mounted) setState(() => _report = r);
    } catch (_) {}
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
    final r = _report;
    final top = r?.topPackage;
    final topMins = r?.topMinutes;
    return UsageReportCard(
      screenTimeLabel: _fmt(r?.totalMinutes ?? 0),
      topAppLabel: top != null && topMins != null
          ? '$top · ${_fmt(topMins)}'
          : null,
      onTap: () => FeatureNavigator.open(
        context,
        id: MoniiFeatureId.usageReport,
        device: widget.device,
      ),
    );
  }
}
