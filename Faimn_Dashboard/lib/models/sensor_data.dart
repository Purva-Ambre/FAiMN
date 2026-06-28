// lib/models/sensor_data.dart

enum SafetyStatus { safe, warning, danger, unknown }

class SensorData {
  final int      co;
  final String   direction;
  final String   fall;
  final String   floor;
  final String   movement;
  final int      packet;
  final double   tempAmbient;
  final double   tempBody;
  final DateTime? timestamp;

  const SensorData({
    required this.co,
    required this.direction,
    required this.fall,
    required this.floor,
    required this.movement,
    required this.packet,
    required this.tempAmbient,
    required this.tempBody,
    this.timestamp,
  });

  factory SensorData.fromMap(Map<dynamic, dynamic> map, [DateTime? ts]) {
    return SensorData(
      co:          (map['co'] ?? 0) as int,
      direction:   (map['direction'] ?? 'UNKNOWN').toString(),
      fall:        (map['fall'] ?? 'NORMAL').toString(),
      floor:       (map['floor'] ?? 'UNKNOWN').toString(),
      movement:    (map['movement'] ?? 'UNKNOWN').toString(),
      packet:      (map['packet'] ?? 0) as int,
      tempAmbient: _dbl(map['temp_ambient']),
      tempBody:    _dbl(map['temp_body']),
      timestamp:   ts,
    );
  }

  static double _dbl(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int)    return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  // ── Thresholds ──────────────────────────────────────────────────────────
  // Ambient temp: 35–49 = warning, ≥50 = danger
  SafetyStatus get ambientStatus {
    if (tempAmbient >= 50) return SafetyStatus.danger;
    if (tempAmbient >= 35) return SafetyStatus.warning;
    return SafetyStatus.safe;
  }

  // Body temp: 37–38.9 = warning, ≥39 = danger
  SafetyStatus get bodyStatus {
    if (tempBody >= 39) return SafetyStatus.danger;
    if (tempBody >= 37) return SafetyStatus.warning;
    return SafetyStatus.safe;
  }

  // CO: 30–99 = warning, ≥100 = danger
  SafetyStatus get coStatus {
    if (co >= 100) return SafetyStatus.danger;
    if (co >= 30)  return SafetyStatus.warning;
    return SafetyStatus.safe;
  }

  SafetyStatus get fallStatus {
    final f = fall.toUpperCase();
    if (f.contains('COLLAPSE') || f.contains('DETECTED') || f.contains('FALL')) {
      return SafetyStatus.danger;
    }
    return SafetyStatus.safe;
  }

  SafetyStatus get overallStatus {
    final all = [ambientStatus, bodyStatus, coStatus, fallStatus];
    if (all.contains(SafetyStatus.danger))  return SafetyStatus.danger;
    if (all.contains(SafetyStatus.warning)) return SafetyStatus.warning;
    return SafetyStatus.safe;
  }

  bool get isFallDetected => fallStatus == SafetyStatus.danger;
  bool get isMoving        => movement.toUpperCase().contains('MOVING');

  String get cleanMovement =>
      movement.replaceAll(RegExp(r'[^\x20-\x7E]'), '').trim().toUpperCase();
  String get cleanDirection =>
      direction.replaceAll(RegExp(r'[^\x20-\x7E]'), '').trim().toUpperCase();

  // Floor number for display
  int get floorNumber {
    final up = floor.toUpperCase();
    if (up == 'INIT' || up == 'UNKNOWN') return 1;
    if (up.contains('SAME')) return 2;
    return int.tryParse(RegExp(r'\d+').firstMatch(floor)?.group(0) ?? '') ?? 1;
  }

  String get floorLabel => 'F-${floorNumber.toString().padLeft(2, '0')}';
}
