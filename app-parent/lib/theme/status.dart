import 'package:flutter/material.dart';

import 'app_theme.dart';

class StatusStyle {
  final Color color;
  final String label;
  const StatusStyle(this.color, this.label);
}

StatusStyle deviceStatusStyle(String status) {
  switch (status.toUpperCase()) {
    case 'ONLINE':
      return const StatusStyle(AppColors.online, 'Online');
    case 'DARK':
      return const StatusStyle(AppColors.alert, 'Went dark');
    case 'OFFLINE':
      return const StatusStyle(AppColors.offline, 'Offline');
    case 'PROVISIONING':
      return const StatusStyle(AppColors.attention, 'Setting up');
    default:
      return const StatusStyle(AppColors.offline, 'Unknown');
  }
}

class AlertStyle {
  final Color color;
  final IconData icon;
  const AlertStyle(this.color, this.icon);
}

AlertStyle alertStyle(String type) {
  switch (type) {
    case 'TAMPER':
      return const AlertStyle(AppColors.alert, Icons.gpp_maybe_outlined);
    case 'DEVICE_OFFLINE':
      return const AlertStyle(AppColors.alert, Icons.cloud_off_rounded);
    case 'GEOFENCE':
      return const AlertStyle(AppColors.attention, Icons.location_on_outlined);
    case 'UNBLOCK_REQUEST':
      return const AlertStyle(AppColors.brand, Icons.lock_open_rounded);
    case 'NEW_APP':
      return const AlertStyle(AppColors.attention, Icons.download_rounded);
    default:
      return const AlertStyle(AppColors.offline, Icons.notifications_none_rounded);
  }
}
