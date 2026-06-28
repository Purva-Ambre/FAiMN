// lib/services/firebase_service.dart
import 'package:firebase_database/firebase_database.dart';
import '../models/sensor_data.dart';

class FirebaseService {
  static const _base = 'firefighters/device_001';
  static const _latest = '$_base/latest';
  static const _history = '$_base/history';

  final _db = FirebaseDatabase.instance.ref();

  FirebaseService() {
    // keepSynced: tells the Firebase RTDB SDK to maintain a live socket
    // connection even between widget rebuilds, preventing idle disconnects
    // that cause packets to be missed until a manual refresh.
    _db.child(_base).keepSynced(true);
  }

  /// Stream of the latest sensor reading
  Stream<SensorData?> get latestStream => _db.child(_latest).onValue.map((e) {
    final v = e.snapshot.value;
    if (v == null) return null;
    return SensorData.fromMap(v as Map<dynamic, dynamic>);
  });

  /// Stream of last 20 history readings (sorted oldest → newest)
  Stream<List<SensorData>> get historyStream =>
      _db.child(_history).orderByKey().limitToLast(20).onValue.map((e) {
        if (!e.snapshot.exists || e.snapshot.value == null) return [];
        final map = e.snapshot.value as Map<dynamic, dynamic>;
        final result = <SensorData>[];
        for (final entry in map.entries) {
          try {
            final dt = _parseKey(entry.key.toString());
            result.add(
              SensorData.fromMap(entry.value as Map<dynamic, dynamic>, dt),
            );
          } catch (_) {}
        }
        result.sort(
          (a, b) => (a.timestamp ?? DateTime(0)).compareTo(
            b.timestamp ?? DateTime(0),
          ),
        );
        return result;
      });

  static DateTime _parseKey(String key) {
    // Format: 2026-04-18_11-43-38
    final parts = key.split('_');
    if (parts.length < 2) return DateTime.now();
    return DateTime.parse('${parts[0]}T${parts[1].replaceAll('-', ':')}');
  }
}
