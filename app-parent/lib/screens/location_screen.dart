import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/models.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

/// Latest reported location for one device, with a jump into Maps.
class LocationScreen extends ConsumerStatefulWidget {
  final Device device;
  const LocationScreen({super.key, required this.device});

  @override
  ConsumerState<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends ConsumerState<LocationScreen> {
  bool _loading = true;
  DeviceLocation? _location;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    DeviceLocation? loc;
    try {
      loc = await ref.read(apiProvider).latestLocation(widget.device.id);
    } catch (_) {}
    if (mounted) {
      setState(() {
        _location = loc;
        _loading = false;
      });
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
    final scheme = Theme.of(context).colorScheme;
    final loc = _location;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.device.name} — location'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : loc == null
              ? const EmptyState(
                  icon: Icons.location_off_outlined,
                  title: 'No location yet',
                  subtitle: 'The device reports its location periodically — '
                      'check back in a few minutes.',
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            const SoftIcon(Icons.location_on_rounded,
                                AppColors.online, size: 48),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${loc.lat.toStringAsFixed(5)}, '
                                    '${loc.lng.toStringAsFixed(5)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${loc.occurredAt != null ? DateFormat('MMM d, HH:mm').format(loc.occurredAt!.toLocal()) : ''}'
                                    '${loc.accuracyM != null ? ' · ±${loc.accuracyM!.round()}m' : ''}',
                                    style: TextStyle(
                                        color: scheme.onSurfaceVariant,
                                        fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => _openMaps(loc.lat, loc.lng),
                      icon: const Icon(Icons.map_rounded),
                      label: const Text('Open in Maps'),
                    ),
                  ],
                ),
    );
  }
}
