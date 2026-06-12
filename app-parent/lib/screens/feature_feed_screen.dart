import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models.dart';
import '../features/monii_features.dart';
import '../state/providers.dart';
import '../widgets/ui.dart';

/// List screen backed by events or content archive from the backend.
class FeatureFeedScreen extends ConsumerStatefulWidget {
  final MoniiFeature feature;
  final Device device;
  final List<String>? tabs;
  final String emptyHint;

  const FeatureFeedScreen({
    super.key,
    required this.feature,
    required this.device,
    this.tabs,
    this.emptyHint = 'No data available',
  });

  @override
  ConsumerState<FeatureFeedScreen> createState() => _FeatureFeedScreenState();
}

class _FeatureFeedScreenState extends ConsumerState<FeatureFeedScreen> {
  int _tab = 0;
  final _search = TextEditingController();
  bool _loading = true;
  List<_FeedRow> _rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String? get _contentSource => switch (widget.feature.id) {
        MoniiFeatureId.browserSafety => 'browser',
        MoniiFeatureId.appNotifications => 'notification',
        MoniiFeatureId.tiktokYoutubeHistory =>
          _tab == 0 ? 'tiktok' : 'youtube',
        MoniiFeatureId.callSmsSafety => 'calllog',
        MoniiFeatureId.socialKeywordDetection => 'keyword',
        _ => null,
      };

  Future<void> _load() async {
    setState(() => _loading = true);
    final api = ref.read(apiProvider);
    final rows = <_FeedRow>[];
    try {
      if (_usesEvents) {
        final type = switch (widget.feature.id) {
          MoniiFeatureId.usageLogs => 'APP_FOREGROUND',
          MoniiFeatureId.installedApps => null,
          _ => null,
        };
        if (widget.feature.id == MoniiFeatureId.installedApps) {
          final apps = await api.installedApps(widget.device.id);
          for (final a in apps) {
            rows.add(_FeedRow(
              title: a.label ?? a.packageName,
              subtitle: a.packageName,
            ));
          }
        } else {
          final events = await api.deviceEvents(
            widget.device.id,
            type: type,
            limit: 150,
          );
          for (final e in events) {
            rows.add(_eventRow(e));
          }
        }
      } else {
        final source = _contentSource;
        final items = await api.deviceContent(
          widget.device.id,
          source: source,
        );
        for (final item in items) {
          rows.add(_FeedRow(
            title: item.counterparty ?? item.source,
            subtitle: item.body,
            time: item.occurredAt,
            matched: item.matched,
          ));
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _rows = rows;
        _loading = false;
      });
    }
  }

  bool get _usesEvents =>
      widget.feature.id == MoniiFeatureId.usageLogs ||
      widget.feature.id == MoniiFeatureId.installedApps;

  _FeedRow _eventRow(DeviceEvent e) {
    final pkg = e.data['package'] as String? ?? '';
    final action = e.data['action'] as String? ?? e.type;
    return _FeedRow(
      title: _humanizeAction(action, pkg),
      subtitle: widget.device.model ?? widget.device.name,
      time: e.occurredAt,
    );
  }

  String _humanizeAction(String action, String pkg) {
    if (action == 'foreground' && pkg.isNotEmpty) return 'Use $pkg';
    if (action == 'foreground') return 'App opened';
    return action.replaceAll('_', ' ');
  }

  List<_FeedRow> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _rows;
    return _rows
        .where((r) =>
            r.title.toLowerCase().contains(q) ||
            r.subtitle.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final tabs = widget.tabs;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.feature.title),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          if (tabs != null && tabs.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: SegmentedButton<int>(
                segments: [
                  for (var i = 0; i < tabs.length; i++)
                    ButtonSegment(value: i, label: Text(tabs[i])),
                ],
                selected: {_tab},
                onSelectionChanged: (s) {
                  setState(() => _tab = s.first);
                  _load();
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Search',
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? EmptyState(
                        icon: widget.feature.icon,
                        title: widget.emptyHint,
                        subtitle:
                            'Data from ${widget.device.name} appears here after sync.',
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                          itemCount: _filtered.length,
                          itemBuilder: (context, i) {
                            final row = _filtered[i];
                            return Card(
                              child: ListTile(
                                title: Text(row.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                                subtitle: Text(row.subtitle,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis),
                                trailing: row.time != null
                                    ? Text(
                                        timeAgo(row.time),
                                        style: TextStyle(
                                            color: muted, fontSize: 12),
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _FeedRow {
  final String title;
  final String subtitle;
  final DateTime? time;
  final String? matched;
  _FeedRow({
    required this.title,
    required this.subtitle,
    this.time,
    this.matched,
  });
}
