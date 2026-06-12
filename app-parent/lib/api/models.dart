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
