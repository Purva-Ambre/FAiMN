// lib/widgets/compass_widget.dart
// ignore_for_file: deprecated_member_use
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/sensor_data.dart';
import '../theme/app_theme.dart';
import 'common_widgets.dart';

class CompassWidget extends StatelessWidget {
  final SensorData? data;
  const CompassWidget({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    final dir   = data?.cleanDirection ?? 'UNKNOWN';
    final angle = _toAngle(dir);

    return DashCard(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel('Unit Orientation'),
        const SizedBox(height: 14),
        Center(child: SizedBox(
          width: 160, height: 160,
          child: Stack(alignment: Alignment.center, children: [
            CustomPaint(size: const Size(160, 160), painter: _RingPainter()),
            ...[
              ('N', Alignment.topCenter),
              ('E', Alignment.centerRight),
              ('S', Alignment.bottomCenter),
              ('W', Alignment.centerLeft),
            ].map((t) => Align(
              alignment: t.$2,
              child: Padding(padding: const EdgeInsets.all(6),
                child: Text(t.$1, style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: AppColors.zinc400,
                )),
              ),
            )),
            Transform.rotate(
              angle: angle * math.pi / 180,
              child: CustomPaint(size: const Size(160, 160), painter: _NeedlePainter()),
            ),
          ]),
        )),
        const SizedBox(height: 14),
        Center(child: Column(children: [
          Text(
            data?.isMoving == true ? 'MOVING FORWARD' : 'STATIONARY',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(dir, style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600,
            letterSpacing: 1.2, color: AppColors.zinc400,
          )),
        ])),
      ],
    ));
  }

  double _toAngle(String d) {
    if (d.contains('NE') || d.contains('045')) return 45;
    if (d.contains('SE') || d.contains('135')) return 135;
    if (d.contains('SW') || d.contains('225')) return 225;
    if (d.contains('NW') || d.contains('315')) return 315;
    if (d.contains('UP')  || d.contains('N'))  return 0;
    if (d.contains('E'))                        return 90;
    if (d.contains('DOWN') || d.contains('S'))  return 180;
    if (d.contains('W'))                        return 270;
    return 0;
  }
}

class _RingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    canvas.drawCircle(c, r - 2, Paint()
      ..color = AppColors.zinc700..style = PaintingStyle.stroke..strokeWidth = 3);
    canvas.drawCircle(c, r - 10, Paint()
      ..color = AppColors.zinc700.withOpacity(0.3)..style = PaintingStyle.stroke..strokeWidth = 1);

    for (int i = 0; i < 36; i++) {
      final a = i * 10 * math.pi / 180;
      final cardinal = i % 9 == 0;
      final inner = r - (cardinal ? 18 : 13);
      canvas.drawLine(
        Offset(c.dx + inner * math.sin(a), c.dy - inner * math.cos(a)),
        Offset(c.dx + (r - 6) * math.sin(a), c.dy - (r - 6) * math.cos(a)),
        Paint()
          ..color = cardinal ? AppColors.zinc500 : AppColors.zinc700
          ..strokeWidth = cardinal ? 2 : 1,
      );
    }
  }
  @override bool shouldRepaint(_) => false;
}

class _NeedlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final n = Path()..moveTo(c.dx, c.dy - 55)..lineTo(c.dx - 6, c.dy)..lineTo(c.dx + 6, c.dy)..close();
    final s = Path()..moveTo(c.dx, c.dy + 55)..lineTo(c.dx - 6, c.dy)..lineTo(c.dx + 6, c.dy)..close();
    canvas.drawPath(n, Paint()..color = AppColors.primary..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    canvas.drawPath(n, Paint()..color = AppColors.primary);
    canvas.drawPath(s, Paint()..color = AppColors.zinc600);
    canvas.drawCircle(c, 5, Paint()..color = AppColors.zinc500);
    canvas.drawCircle(c, 3, Paint()..color = Colors.white);
  }
  @override bool shouldRepaint(_) => false;
}
