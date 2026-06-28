// lib/widgets/critical_diagnostics.dart
// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../models/sensor_data.dart';
import '../theme/app_theme.dart';
import 'common_widgets.dart';

class CriticalDiagnostics extends StatelessWidget {
  final SensorData? data;
  const CriticalDiagnostics({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    final d = data;
    final fallActive = d != null && d.isFallDetected;
    final coActive   = d != null && d.coStatus != SafetyStatus.safe;
    final bodyActive = d != null && d.bodyStatus == SafetyStatus.danger;
    final ambActive  = d != null && d.ambientStatus != SafetyStatus.safe;

    return DashCard(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel('Critical Diagnostics'),
        const SizedBox(height: 14),
        AlertRow(
          icon:     Icons.warning_rounded,
          label:    'FALL DETECTED',
          trailing: fallActive ? 'ACTIVE' : 'CLEAR',
          status:   fallActive ? SafetyStatus.danger : SafetyStatus.safe,
          resolved: !fallActive,
        ),
        const SizedBox(height: 8),
        AlertRow(
          icon:     Icons.air,
          label:    'HIGH CO',
          trailing: coActive ? '${d!.co} PPM' : 'CLEAR',
          status:   coActive ? d!.coStatus : SafetyStatus.safe,
          resolved: !coActive,
        ),
        const SizedBox(height: 8),
        AlertRow(
          icon:     Icons.thermostat,
          label:    'HIGH BODY TEMP',
          trailing: bodyActive ? '${d!.tempBody.toStringAsFixed(1)}°C' : 'NORMAL',
          status:   bodyActive ? SafetyStatus.danger : SafetyStatus.safe,
          resolved: !bodyActive,
        ),
        const SizedBox(height: 8),
        AlertRow(
          icon:     Icons.local_fire_department,
          label:    'AMBIENT TEMP',
          trailing: ambActive
              ? '${d!.tempAmbient.toStringAsFixed(1)}°C'
              : '${d?.tempAmbient.toStringAsFixed(1) ?? '--'}°C',
          status:   ambActive ? d!.ambientStatus : SafetyStatus.safe,
          resolved: !ambActive,
        ),
        const SizedBox(height: 12),
        // Movement strip
        if (d != null) _MovementStrip(data: d),
      ],
    ));
  }
}

class _MovementStrip extends StatelessWidget {
  final SensorData data;
  const _MovementStrip({required this.data});

  @override
  Widget build(BuildContext context) {
    final isCollapse = data.cleanMovement.contains('COLLAPSE');
    final color = isCollapse ? AppColors.danger
                : data.isMoving ? AppColors.primary
                : AppColors.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(children: [
        Icon(
          data.isMoving ? Icons.directions_walk : Icons.personal_injury,
          color: color, size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(
          data.cleanMovement.isEmpty ? 'UNKNOWN' : data.cleanMovement,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
        )),
        Container(width: 7, height: 7,
          decoration: BoxDecoration(
            color: color, shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 5)],
          ),
        ),
      ]),
    );
  }
}
