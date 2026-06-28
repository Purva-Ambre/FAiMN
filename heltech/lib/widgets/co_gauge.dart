// lib/widgets/co_gauge.dart
// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/sensor_data.dart';
import '../theme/app_theme.dart';
import 'common_widgets.dart';

class CoGauge extends StatelessWidget {
  final SensorData? data;
  const CoGauge({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    final co    = data?.co ?? 0;
    final status = data?.coStatus ?? SafetyStatus.safe;
    final color  = statusColor(status);
    final fill   = (co / 200.0).clamp(0.0, 1.0);
    final label  = status == SafetyStatus.danger ? 'ABOVE THRESHOLD'
                 : status == SafetyStatus.warning ? 'WARNING' : 'SAFE';

    return DashCard(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel('Atmospheric Toxicity'),
        const SizedBox(height: 4),
        Text('CO Level', style: GoogleFonts.spaceGrotesk(
          fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white,
        )),
        const SizedBox(height: 20),
        Center(child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(width: 40, height: 180,
                child: CustomPaint(painter: _GaugePainter(fill: fill, color: color))),
            const SizedBox(width: 22),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$co', style: TextStyle(
                fontSize: 52, fontWeight: FontWeight.w800,
                color: color, letterSpacing: -2, height: 1,
              )),
              Text('PPM CO', style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600,
                letterSpacing: 2, color: AppColors.zinc400,
              )),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: color.withOpacity(0.25)),
                ),
                child: Text(label, style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  letterSpacing: 1, color: color,
                )),
              ),
            ]),
          ],
        )),
      ],
    ));
  }
}

class _GaugePainter extends CustomPainter {
  final double fill; final Color color;
  _GaugePainter({required this.fill, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final r    = size.width / 2;
    final rect = Offset.zero & size;
    final rr   = RRect.fromRectAndRadius(rect, Radius.circular(r));

    canvas.drawRRect(rr, Paint()..color = AppColors.zinc800);

    // Zone tint gradient
    canvas.drawRRect(rr, Paint()..shader = LinearGradient(
      begin: Alignment.bottomCenter, end: Alignment.topCenter,
      colors: [
        AppColors.safe.withOpacity(0.10),
        AppColors.warning.withOpacity(0.10),
        AppColors.danger.withOpacity(0.10),
      ],
    ).createShader(rect));

    // Zone lines
    final lp = Paint()..color = AppColors.zinc700..strokeWidth = 1;
    canvas.drawLine(Offset(0, size.height * 0.33), Offset(size.width, size.height * 0.33), lp);
    canvas.drawLine(Offset(0, size.height * 0.66), Offset(size.width, size.height * 0.66), lp);

    if (fill > 0) {
      final fh = size.height * fill;
      final fr = Rect.fromLTWH(2, size.height - fh - 2, size.width - 4, fh);
      canvas.drawRRect(
        RRect.fromRectAndRadius(fr, const Radius.circular(18)),
        Paint()..shader = LinearGradient(
          begin: Alignment.bottomCenter, end: Alignment.topCenter,
          colors: [color.withOpacity(0.9), color.withOpacity(0.5)],
        ).createShader(fr),
      );
    }

    canvas.drawRRect(rr, Paint()
      ..color = AppColors.zinc600..style = PaintingStyle.stroke..strokeWidth = 1);
  }

  @override bool shouldRepaint(_GaugePainter o) => o.fill != fill || o.color != color;
}
