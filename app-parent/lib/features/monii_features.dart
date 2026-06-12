import 'package:flutter/material.dart';

import '../api/models.dart';
import '../theme/app_theme.dart';

/// Every surface in the parent app — Device tab grids and Notice feed rows.
enum MoniiFeatureId {
  // Live monitoring (consented screen view only — no camera/mic)
  screenMirroring,
  liveLocation,
  blockAllApps,
  usageReport,
  // Device activity
  screenTimeLimits,
  appTimeLimits,
  appRules,
  usageLogs,
  livePainting,
  checkPermissions,
  // Usage safety
  socialAppDetection,
  callSmsSafety,
  albumsSafety,
  browserSafety,
  // Notice-only / history
  appNotifications,
  alertsAndRequests,
  tiktokYoutubeHistory,
  socialKeywordDetection,
  // Remote control
  lockScreen,
  appBlocking,
  usageMonitoring,
  remoteDeviceManagement,
  // Info
  deviceInfo,
  installedApps,
}

class MoniiFeature {
  final MoniiFeatureId id;
  final String title;
  final IconData icon;
  final Color color;
  final String? badge;
  final bool showInNotice;
  final bool showOnDevice;

  const MoniiFeature({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    this.badge,
    this.showInNotice = false,
    this.showOnDevice = true,
  });
}

/// Canonical list — mirrors the reference archive layout.
const kMoniiFeatures = <MoniiFeature>[
  MoniiFeature(
    id: MoniiFeatureId.usageReport,
    title: 'Usage Report',
    icon: Icons.bar_chart_rounded,
    color: AppColors.online,
    showOnDevice: true,
  ),
  MoniiFeature(
    id: MoniiFeatureId.screenMirroring,
    title: 'Screen View',
    icon: Icons.smartphone_rounded,
    color: AppColors.brand,
    showOnDevice: true,
  ),
  MoniiFeature(
    id: MoniiFeatureId.blockAllApps,
    title: 'Block All Apps',
    icon: Icons.lock_rounded,
    color: AppColors.attention,
    showOnDevice: true,
  ),
  MoniiFeature(
    id: MoniiFeatureId.liveLocation,
    title: 'Live Location',
    icon: Icons.location_on_rounded,
    color: AppColors.online,
    showOnDevice: true,
  ),
  MoniiFeature(
    id: MoniiFeatureId.screenTimeLimits,
    title: 'Screen Time Limits',
    icon: Icons.schedule_rounded,
    color: AppColors.brand,
  ),
  MoniiFeature(
    id: MoniiFeatureId.appTimeLimits,
    title: 'App Time Limits',
    icon: Icons.apps_rounded,
    color: AppColors.brand,
  ),
  MoniiFeature(
    id: MoniiFeatureId.appRules,
    title: 'App Rules',
    icon: Icons.rule_folder_rounded,
    color: AppColors.attention,
  ),
  MoniiFeature(
    id: MoniiFeatureId.usageLogs,
    title: 'Usage Logs',
    icon: Icons.history_rounded,
    color: AppColors.alert,
    showInNotice: true,
  ),
  MoniiFeature(
    id: MoniiFeatureId.livePainting,
    title: 'Live Painting',
    icon: Icons.palette_rounded,
    color: AppColors.brand,
    badge: 'Beta',
  ),
  MoniiFeature(
    id: MoniiFeatureId.checkPermissions,
    title: 'Check Permissions',
    icon: Icons.verified_user_rounded,
    color: AppColors.brand,
  ),
  MoniiFeature(
    id: MoniiFeatureId.socialAppDetection,
    title: 'Social App Detection',
    icon: Icons.chat_bubble_rounded,
    color: AppColors.attention,
  ),
  MoniiFeature(
    id: MoniiFeatureId.callSmsSafety,
    title: 'Call & SMS Safety',
    icon: Icons.sms_rounded,
    color: AppColors.online,
    showInNotice: true,
  ),
  MoniiFeature(
    id: MoniiFeatureId.albumsSafety,
    title: 'Albums Safety',
    icon: Icons.photo_library_rounded,
    color: AppColors.attention,
    showInNotice: true,
  ),
  MoniiFeature(
    id: MoniiFeatureId.browserSafety,
    title: 'Browser Safety',
    icon: Icons.public_rounded,
    color: Color(0xFF3B82F6),
    showInNotice: true,
  ),
  MoniiFeature(
    id: MoniiFeatureId.appNotifications,
    title: 'App Notifications',
    icon: Icons.notifications_active_rounded,
    color: Color(0xFF3B82F6),
    showInNotice: true,
    showOnDevice: false,
  ),
  MoniiFeature(
    id: MoniiFeatureId.alertsAndRequests,
    title: 'Alerts & Request',
    icon: Icons.campaign_rounded,
    color: AppColors.alert,
    showInNotice: true,
    showOnDevice: false,
  ),
  MoniiFeature(
    id: MoniiFeatureId.tiktokYoutubeHistory,
    title: 'TikTok & YouTube History',
    icon: Icons.play_circle_rounded,
    color: AppColors.inkLight,
    showInNotice: true,
  ),
  MoniiFeature(
    id: MoniiFeatureId.socialKeywordDetection,
    title: 'Social App Keyword Detection',
    icon: Icons.search_rounded,
    color: Color(0xFF7C5CBF),
    showInNotice: true,
  ),
  MoniiFeature(
    id: MoniiFeatureId.lockScreen,
    title: 'Lock Screen',
    icon: Icons.lock_rounded,
    color: AppColors.alert,
  ),
  MoniiFeature(
    id: MoniiFeatureId.appBlocking,
    title: 'App Blocking',
    icon: Icons.block_rounded,
    color: AppColors.attention,
  ),
  MoniiFeature(
    id: MoniiFeatureId.usageMonitoring,
    title: 'Usage Monitoring',
    icon: Icons.insights_rounded,
    color: AppColors.brand,
  ),
  MoniiFeature(
    id: MoniiFeatureId.remoteDeviceManagement,
    title: 'Remote Device Management',
    icon: Icons.settings_remote_rounded,
    color: AppColors.offline,
  ),
  MoniiFeature(
    id: MoniiFeatureId.deviceInfo,
    title: 'Device info',
    icon: Icons.smartphone,
    color: AppColors.offline,
  ),
  MoniiFeature(
    id: MoniiFeatureId.installedApps,
    title: 'Installed Apps',
    icon: Icons.apps_rounded,
    color: AppColors.brand,
  ),
];

MoniiFeature featureById(MoniiFeatureId id) =>
    kMoniiFeatures.firstWhere((f) => f.id == id);

List<MoniiFeature> noticeFeatures() =>
    kMoniiFeatures.where((f) => f.showInNotice).toList();

/// Preview line under each Notice row — wired where we have data, else placeholder.
String noticePreview(MoniiFeatureId id, {Device? device, AlertModel? latestAlert}) {
  switch (id) {
    case MoniiFeatureId.alertsAndRequests:
      if (latestAlert != null) {
        final name = device?.name ?? 'Device';
        return '$name — ${latestAlert.title}';
      }
      return 'No alerts right now';
    case MoniiFeatureId.browserSafety:
      return 'No browsing data yet';
    case MoniiFeatureId.tiktokYoutubeHistory:
      return 'No watch history yet';
    case MoniiFeatureId.usageLogs:
      if (device != null) {
        return '[${device.name}] Lock the Screen';
      }
      return 'No activity logged yet';
    case MoniiFeatureId.socialKeywordDetection:
      return 'No keywords detected yet';
    case MoniiFeatureId.callSmsSafety:
    case MoniiFeatureId.albumsSafety:
      return 'No data available';
    case MoniiFeatureId.appNotifications:
      return 'No notifications captured yet';
    default:
      return 'Tap to open';
  }
}

const kDeviceSections = <String, List<MoniiFeatureId>>{
  'Device Activity': [
    MoniiFeatureId.screenTimeLimits,
    MoniiFeatureId.appTimeLimits,
    MoniiFeatureId.appRules,
    MoniiFeatureId.usageLogs,
    MoniiFeatureId.livePainting,
    MoniiFeatureId.checkPermissions,
  ],
  'Usage Safety': [
    MoniiFeatureId.socialAppDetection,
    MoniiFeatureId.callSmsSafety,
    MoniiFeatureId.albumsSafety,
    MoniiFeatureId.browserSafety,
  ],
  'Remote control': [
    MoniiFeatureId.lockScreen,
    MoniiFeatureId.appBlocking,
    MoniiFeatureId.usageMonitoring,
    MoniiFeatureId.remoteDeviceManagement,
  ],
  'Information': [
    MoniiFeatureId.deviceInfo,
    MoniiFeatureId.installedApps,
  ],
};
