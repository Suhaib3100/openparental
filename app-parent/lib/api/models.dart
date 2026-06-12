class AuthResult {
  final String accessToken;
  final String refreshToken;
  final String userId;
  final String email;
  final String familyId;

  AuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.email,
    required this.familyId,
  });

  factory AuthResult.fromJson(Map<String, dynamic> j) {
    final user = j['user'] as Map<String, dynamic>;
    return AuthResult(
      accessToken: j['accessToken'] as String,
      refreshToken: j['refreshToken'] as String,
      userId: user['id'] as String,
      email: user['email'] as String,
      familyId: user['familyId'] as String,
    );
  }
}

class Device {
  final String id;
  final String name;
  final String status;
  final int? batteryPct;
  final String? model;
  final String? manufacturer;
  final DateTime? lastSeenAt;

  Device({
    required this.id,
    required this.name,
    required this.status,
    this.batteryPct,
    this.model,
    this.manufacturer,
    this.lastSeenAt,
  });

  factory Device.fromJson(Map<String, dynamic> j) => Device(
        id: j['id'] as String,
        name: (j['name'] as String?) ?? 'Device',
        status: (j['status'] as String?) ?? 'UNKNOWN',
        batteryPct: j['batteryPct'] as int?,
        model: j['model'] as String?,
        manufacturer: j['manufacturer'] as String?,
        lastSeenAt: j['lastSeenAt'] != null
            ? DateTime.tryParse(j['lastSeenAt'] as String)
            : null,
      );
}

class AlertModel {
  final String id;
  final String type;
  final String title;
  final String body;
  final DateTime? createdAt;
  final bool read;

  AlertModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.createdAt,
    required this.read,
  });

  factory AlertModel.fromJson(Map<String, dynamic> j) => AlertModel(
        id: j['id'] as String,
        type: (j['type'] as String?) ?? 'SYSTEM',
        title: (j['title'] as String?) ?? '',
        body: (j['body'] as String?) ?? '',
        createdAt: j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt'] as String)
            : null,
        read: j['readAt'] != null,
      );
}

class Pairing {
  final String id;
  final String code;
  final String qrToken;
  final String status;

  Pairing({
    required this.id,
    required this.code,
    required this.qrToken,
    required this.status,
  });

  factory Pairing.fromJson(Map<String, dynamic> j) => Pairing(
        id: j['id'] as String,
        code: (j['code'] as String?) ?? '',
        qrToken: (j['qrToken'] as String?) ?? '',
        status: (j['status'] as String?) ?? 'PENDING',
      );
}

class DeviceLocation {
  final double lat;
  final double lng;
  final double? accuracyM;
  final DateTime? occurredAt;

  DeviceLocation({
    required this.lat,
    required this.lng,
    this.accuracyM,
    this.occurredAt,
  });

  factory DeviceLocation.fromJson(Map<String, dynamic> j) => DeviceLocation(
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        accuracyM: (j['accuracyM'] as num?)?.toDouble(),
        occurredAt: j['occurredAt'] != null
            ? DateTime.tryParse(j['occurredAt'] as String)
            : null,
      );
}

class DeviceEvent {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final DateTime? occurredAt;

  DeviceEvent({
    required this.id,
    required this.type,
    required this.data,
    this.occurredAt,
  });

  factory DeviceEvent.fromJson(Map<String, dynamic> j) => DeviceEvent(
        id: j['id'] as String,
        type: j['type'] as String,
        data: (j['data'] as Map<String, dynamic>?) ?? {},
        occurredAt: j['occurredAt'] != null
            ? DateTime.tryParse(j['occurredAt'] as String)
            : null,
      );
}

class ContentItem {
  final String id;
  final String source;
  final String? counterparty;
  final String body;
  final String? matched;
  final DateTime? occurredAt;

  ContentItem({
    required this.id,
    required this.source,
    this.counterparty,
    required this.body,
    this.matched,
    this.occurredAt,
  });

  factory ContentItem.fromJson(Map<String, dynamic> j) => ContentItem(
        id: j['id'] as String,
        source: j['source'] as String,
        counterparty: j['counterparty'] as String?,
        body: j['body'] as String? ?? '',
        matched: j['matched'] as String?,
        occurredAt: j['occurredAt'] != null
            ? DateTime.tryParse(j['occurredAt'] as String)
            : null,
      );
}

class UsageReport {
  final int totalMinutes;
  final Map<String, int> minutesByApp;
  final DateTime? updatedAt;
  final String? topPackage;
  final int? topMinutes;

  UsageReport({
    required this.totalMinutes,
    required this.minutesByApp,
    this.updatedAt,
    this.topPackage,
    this.topMinutes,
  });

  factory UsageReport.fromJson(Map<String, dynamic> j) {
    final raw = j['minutesByApp'] as Map<String, dynamic>? ?? {};
    final byApp = raw.map((k, v) => MapEntry(k, (v as num).toInt()));
    final top = j['topApp'] as Map<String, dynamic>?;
    return UsageReport(
      totalMinutes: (j['totalMinutes'] as num?)?.toInt() ?? 0,
      minutesByApp: byApp,
      updatedAt: j['updatedAt'] != null
          ? DateTime.tryParse(j['updatedAt'] as String)
          : null,
      topPackage: top?['package'] as String?,
      topMinutes: (top?['minutes'] as num?)?.toInt(),
    );
  }
}

class PermissionSnapshot {
  final Map<String, bool> permissions;
  final DateTime? updatedAt;

  PermissionSnapshot({required this.permissions, this.updatedAt});

  factory PermissionSnapshot.fromJson(Map<String, dynamic> j) {
    final raw = j['permissions'] as Map<String, dynamic>?;
    final perms = raw?.map((k, v) => MapEntry(k, v == true)) ?? {};
    return PermissionSnapshot(
      permissions: perms,
      updatedAt: j['updatedAt'] != null
          ? DateTime.tryParse(j['updatedAt'] as String)
          : null,
    );
  }
}

class InstalledApp {
  final String packageName;
  final String? label;

  InstalledApp({required this.packageName, this.label});

  factory InstalledApp.fromJson(Map<String, dynamic> j) => InstalledApp(
        packageName: j['package'] as String,
        label: j['label'] as String?,
      );
}
