import 'package:flutter/material.dart';

import '../api/models.dart';
import '../features/monii_features.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';
import '../screens/alerts_requests_screen.dart';
import '../screens/blocked_apps_screen.dart';
import '../screens/check_permissions_screen.dart';
import '../screens/device_info_screen.dart';
import '../screens/feature_feed_screen.dart';
import '../screens/live_monitoring_screen.dart';
import '../screens/location_screen.dart';
import '../screens/usage_report_screen.dart';

/// Opens the right screen (or command) for a catalog feature.
class FeatureNavigator {
  static Future<void> open(
    BuildContext context, {
    required MoniiFeatureId id,
    required Device device,
    Future<void> Function(String type, String label)? sendCommand,
  }) async {
    final f = featureById(id);
    switch (id) {
      case MoniiFeatureId.liveLocation:
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
              builder: (_) => LocationScreen(device: device)),
        );
        return;
      case MoniiFeatureId.lockScreen:
        await sendCommand?.call('LOCK', 'Lock');
        return;
      case MoniiFeatureId.appBlocking:
        await Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const BlockedAppsScreen()),
        );
        return;
      case MoniiFeatureId.deviceInfo:
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
              builder: (_) => DeviceInfoScreen(device: device)),
        );
        return;
      case MoniiFeatureId.usageReport:
      case MoniiFeatureId.usageMonitoring:
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
              builder: (_) => UsageReportScreen(device: device)),
        );
        return;
      case MoniiFeatureId.checkPermissions:
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
              builder: (_) => CheckPermissionsScreen(device: device)),
        );
        return;
      case MoniiFeatureId.remoteCamera:
        await _live(context, LiveMonitoringKind.camera, device);
        return;
      case MoniiFeatureId.screenMirroring:
        await _live(context, LiveMonitoringKind.screen, device);
        return;
      case MoniiFeatureId.oneWayAudio:
        await _live(context, LiveMonitoringKind.audio, device);
        return;
      case MoniiFeatureId.alertsAndRequests:
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
              builder: (_) => AlertsRequestsScreen(device: device)),
        );
        return;
      case MoniiFeatureId.snapshotAndRecording:
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => FeatureFeedScreen(
              feature: f,
              device: device,
              tabs: const ['Camera', 'Screen', 'Audio'],
              emptyHint:
                  'No data. Go to Device → Camera Snapshot to set up.',
            ),
          ),
        );
        return;
      case MoniiFeatureId.browserSafety:
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => FeatureFeedScreen(
              feature: f,
              device: device,
              tabs: const ['History', 'Blocked'],
              emptyHint: 'No browsing history yet.',
            ),
          ),
        );
        return;
      case MoniiFeatureId.tiktokYoutubeHistory:
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => FeatureFeedScreen(
              feature: f,
              device: device,
              tabs: const ['TikTok', 'YouTube'],
              emptyHint: 'No watch history yet.',
            ),
          ),
        );
        return;
      default:
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => FeatureFeedScreen(
              feature: f,
              device: device,
              emptyHint:
                  'No data. Please go to [Device > ${f.title}] to set up.',
            ),
          ),
        );
    }
  }

  static Future<void> _live(
    BuildContext context,
    LiveMonitoringKind kind,
    Device device,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => LiveMonitoringScreen(kind: kind, device: device),
      ),
    );
  }

  static void showComingSoonSnackBar(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label — backend wiring in progress')),
    );
  }
}

/// Beta badge on feature tiles.
class FeatureBadge extends StatelessWidget {
  final String text;
  const FeatureBadge(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.brand.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: AppColors.brand,
        ),
      ),
    );
  }
}
