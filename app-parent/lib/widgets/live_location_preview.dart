import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models.dart';
import '../state/providers.dart';
import 'device_dashboard.dart';
import '../screens/location_screen.dart';

/// Loads latest location once per device and renders [LiveLocationCard].
class LiveLocationPreview extends ConsumerStatefulWidget {
  final Device device;
  const LiveLocationPreview({super.key, required this.device});

  @override
  ConsumerState<LiveLocationPreview> createState() =>
      _LiveLocationPreviewState();
}

class _LiveLocationPreviewState extends ConsumerState<LiveLocationPreview> {
  DeviceLocation? _location;
  String? _loadedForId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(LiveLocationPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.device.id != widget.device.id) _load();
  }

  Future<void> _load() async {
    final id = widget.device.id;
    try {
      final loc = await ref.read(apiProvider).latestLocation(id);
      if (mounted && widget.device.id == id) {
        setState(() {
          _location = loc;
          _loadedForId = id;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return LiveLocationCard(
      device: widget.device,
      location: _loadedForId == widget.device.id ? _location : null,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
            builder: (_) => LocationScreen(device: widget.device)),
      ),
    );
  }
}
