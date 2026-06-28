// lib/widgets/common_widgets.dart
// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/sensor_data.dart';
import '../theme/app_theme.dart';

// ── DashCard ─────────────────────────────────────────────────────────────────
class DashCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;

  const DashCard({super.key, required this.child, this.padding, this.borderColor});

  @override
  Widget build(BuildContext context) => Container(
    padding: padding ?? const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: borderColor ?? AppColors.outlineVariant),
    ),
    child: child,
  );
}

// ── Section label (all-caps small) ───────────────────────────────────────────
class SectionLabel extends StatelessWidget {
  final String text;
  final Color? color;
  const SectionLabel(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: GoogleFonts.spaceGrotesk(
      fontSize: 10, fontWeight: FontWeight.w600,
      letterSpacing: 1.3,
      color: color ?? AppColors.zinc400,
    ),
  );
}

// ── Status dot ────────────────────────────────────────────────────────────────
class StatusDot extends StatelessWidget {
  final SafetyStatus status;
  final double size;
  const StatusDot(this.status, {super.key, this.size = 10});

  @override
  Widget build(BuildContext context) {
    final c = statusColor(status);
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: c, shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: c.withOpacity(0.55), blurRadius: 6)],
      ),
    );
  }
}

// ── Signal bars icon (like phone signal) ─────────────────────────────────────
class SignalBars extends StatelessWidget {
  final SafetyStatus status;
  const SignalBars(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = statusColor(status);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(3, (i) => Container(
        width: 3,
        height: 5.0 + i * 3,
        margin: const EdgeInsets.only(right: 1.5),
        decoration: BoxDecoration(
          color: c.withOpacity(i == 0 ? 1.0 : (i == 1 ? 0.75 : 0.5)),
          borderRadius: BorderRadius.circular(1),
        ),
      )),
    );
  }
}

// ── Stat mini-row (label + value) ─────────────────────────────────────────────
class StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color  valueColor;
  const StatRow({super.key, required this.label, required this.value, required this.valueColor});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label.toUpperCase(), style: GoogleFonts.spaceGrotesk(
        fontSize: 9, fontWeight: FontWeight.w600,
        letterSpacing: 1.2, color: AppColors.zinc400,
      )),
      const SizedBox(height: 2),
      Text(value, style: GoogleFonts.spaceGrotesk(
        fontSize: 17, fontWeight: FontWeight.w800,
        color: valueColor, height: 1,
      )),
    ],
  );
}

// ── Alert row ─────────────────────────────────────────────────────────────────
class AlertRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String trailing;
  final SafetyStatus status;
  final bool resolved;

  const AlertRow({
    super.key, required this.icon, required this.label,
    required this.trailing, required this.status, this.resolved = false,
  });

  @override
  Widget build(BuildContext context) {
    final c  = resolved ? AppColors.zinc500 : statusColor(status);
    final bg = resolved
        ? AppColors.zinc800.withOpacity(0.25)
        : (status == SafetyStatus.danger
            ? AppColors.dangerContainer.withOpacity(0.7)
            : c.withOpacity(0.1));
    return Opacity(
      opacity: resolved ? 0.45 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(7),
          border: Border.all(color: c.withOpacity(0.3)),
          boxShadow: resolved ? null :
              [BoxShadow(color: c.withOpacity(0.08), blurRadius: 8)],
        ),
        child: Row(children: [
          Icon(icon, color: resolved ? AppColors.zinc400 : c, size: 17),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: resolved ? AppColors.zinc400 : Colors.white,
          ))),
          Text(trailing, style: TextStyle(
            fontFamily: 'monospace', fontSize: 11,
            color: resolved ? AppColors.zinc500 : Colors.white.withOpacity(0.55),
          )),
        ]),
      ),
    );
  }
}

// ── Metric tile ───────────────────────────────────────────────────────────────
class MetricTile extends StatelessWidget {
  final String label, value;
  final SafetyStatus status;
  final String? unit;

  const MetricTile({
    super.key, required this.label, required this.value,
    required this.status, this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final c = statusColor(status);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.withOpacity(0.22)),
        boxShadow: [BoxShadow(color: c.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          StatusDot(status, size: 7),
          const SizedBox(width: 6),
          Text(label.toUpperCase(), style: GoogleFonts.spaceGrotesk(
            fontSize: 9, fontWeight: FontWeight.w600,
            letterSpacing: 1.2, color: AppColors.zinc400,
          )),
        ]),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value, style: TextStyle(
              fontSize: 26, fontWeight: FontWeight.w800,
              color: c, letterSpacing: -0.5,
            )),
            if (unit != null) ...[
              const SizedBox(width: 3),
              Text(unit!, style: TextStyle(
                fontSize: 12, color: c.withOpacity(0.65), fontWeight: FontWeight.w600,
              )),
            ],
          ],
        ),
      ]),
    );
  }
}
