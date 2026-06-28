// lib/widgets/unit_card.dart
// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/sensor_data.dart';
import '../theme/app_theme.dart';
import 'common_widgets.dart';

class UnitCard extends StatefulWidget {
  final String unitId;
  final String name;
  final SensorData data;
  final DateTime? lastUpdated;
  final VoidCallback onTap;

  const UnitCard({
    super.key,
    required this.unitId,
    required this.name,
    required this.data,
    required this.onTap,
    this.lastUpdated,
  });

  @override
  State<UnitCard> createState() => _UnitCardState();
}

class _UnitCardState extends State<UnitCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final status = widget.data.overallStatus;
    final borderCol = statusColor(status);
    final isCritical = status == SafetyStatus.danger;
    final isWarning = status == SafetyStatus.warning;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.surfaceHighlight
                : AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isCritical
                  ? borderCol.withOpacity(0.7)
                  : isWarning
                  ? borderCol.withOpacity(0.5)
                  : AppColors.outlineVariant,
              width: isCritical ? 1.5 : 1.0,
            ),
            boxShadow: isCritical
                ? [
                    BoxShadow(
                      color: borderCol.withOpacity(0.12),
                      blurRadius: 16,
                    ),
                  ]
                : isWarning
                ? [
                    BoxShadow(
                      color: borderCol.withOpacity(0.08),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: unit id + signal + status dot ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.unitId,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor(status),
                      letterSpacing: 1.2,
                    ),
                  ),
                  Row(
                    children: [
                      SignalBars(status),
                      const SizedBox(width: 8),
                      StatusDot(status),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ── Name ──
              Text(
                widget.name,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 14),

              // ── Stats grid: CO + Body Temp ──
              Row(
                children: [
                  Expanded(
                    child: StatRow(
                      label: 'CO Level',
                      value: '${widget.data.co.toString().padLeft(2, '0')} ppm',
                      valueColor: statusColor(widget.data.coStatus),
                    ),
                  ),
                  Expanded(
                    child: StatRow(
                      label: 'Body Temp',
                      value: '${widget.data.tempBody.toStringAsFixed(1)}°C',
                      valueColor: statusColor(widget.data.bodyStatus),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ── Stats grid: Floor + Movement ──
              Row(
                children: [
                  Expanded(
                    child: StatRow(
                      label: 'Floor / Alt',
                      value: widget.data.floorLabel,
                      valueColor: AppColors.onSurface,
                    ),
                  ),
                  Expanded(
                    child: StatRow(
                      label: 'Movement',
                      value: _movementShort(widget.data),
                      valueColor: _movementColor(widget.data),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Footer: last updated + open icon ──
              Divider(color: AppColors.zinc700, height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.lastUpdated != null
                        ? 'LAST UPDATED: ${_timeAgo(widget.lastUpdated!)}'
                        : 'LAST UPDATED: LIVE',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: AppColors.zinc500,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Icon(
                    Icons.open_in_new_rounded,
                    size: 14,
                    color: AppColors.zinc500,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _movementShort(SensorData d) {
    final m = d.cleanMovement;
    if (m.contains('COLLAPSE')) return 'COLLAPSE';
    if (m.contains('MOVING')) return 'MOVING';
    if (m.isEmpty) return 'UNKNOWN';
    // Truncate with duration if "STATIC (15S)" etc.
    if (m.length > 14) return m.substring(0, 14);
    return m;
  }

  Color _movementColor(SensorData d) {
    final m = d.cleanMovement;
    if (m.contains('COLLAPSE')) return AppColors.danger;
    if (m.contains('MOVING')) return AppColors.primary;
    return AppColors.secondary;
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}S AGO';
    if (diff.inMinutes < 60) return '${diff.inMinutes}M AGO';
    return DateFormat('HH:mm').format(dt);
  }
}
