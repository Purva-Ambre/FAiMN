// lib/widgets/temperature_chart.dart
// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/sensor_data.dart';
import '../theme/app_theme.dart';
import 'common_widgets.dart';

class TemperatureChart extends StatelessWidget {
  final List<SensorData> history;
  final SensorData?      latest;
  const TemperatureChart({super.key, required this.history, this.latest});

  @override
  Widget build(BuildContext context) {
    final bodyC  = latest != null ? statusColor(latest!.bodyStatus)    : AppColors.primary;
    final ambC   = latest != null ? statusColor(latest!.ambientStatus) : AppColors.secondary;
    final bodyPts = _spots(history, (d) => d.tempBody);
    final ambPts  = _spots(history, (d) => d.tempAmbient);

    return DashCard(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SectionLabel('Core vs Ambient Temperature'),
            const SizedBox(height: 4),
            Text('Thermal Gradient', style: GoogleFonts.spaceGrotesk(
              fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white,
            )),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (latest != null) ...[
              Text('${latest!.tempBody.toStringAsFixed(1)}°C',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 16,
                      fontWeight: FontWeight.w700, color: bodyC)),
              Text('${latest!.tempAmbient.toStringAsFixed(1)}°C',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 16,
                      fontWeight: FontWeight.w700, color: ambC)),
              const SizedBox(height: 6),
            ],
            Row(children: [
              _Legend(color: bodyC,  label: 'BODY'),
              const SizedBox(width: 12),
              _Legend(color: ambC,   label: 'AMBIENT'),
            ]),
          ]),
        ]),
        const SizedBox(height: 20),
        SizedBox(
          height: 200,
          child: history.isEmpty
              ? Center(child: Text('Waiting for data…',
                  style: TextStyle(color: AppColors.zinc500)))
              : LineChart(LineChartData(
                  backgroundColor: Colors.transparent,
                  gridData: FlGridData(
                    show: true, drawVerticalLine: false,
                    horizontalInterval: 10,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: AppColors.zinc700, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(
                      showTitles: true, reservedSize: 34,
                      getTitlesWidget: (v, _) => Text('${v.toInt()}°',
                          style: TextStyle(fontSize: 9, color: AppColors.zinc500)),
                    )),
                    rightTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  minY: 20, maxY: 100,
                  lineBarsData: [_line(bodyPts, bodyC), _line(ambPts, ambC)],
                )),
        ),
      ],
    ));
  }

  List<FlSpot> _spots(List<SensorData> d, double Function(SensorData) f) =>
      d.asMap().entries.map((e) => FlSpot(e.key.toDouble(), f(e.value))).toList();

  LineChartBarData _line(List<FlSpot> spots, Color color) => LineChartBarData(
    spots: spots, isCurved: true, color: color, barWidth: 2.5,
    isStrokeCapRound: true,
    dotData: FlDotData(show: false),
    belowBarData: BarAreaData(show: true, color: color.withOpacity(0.05)),
  );
}

class _Legend extends StatelessWidget {
  final Color color; final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 9, height: 9,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 5),
    Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
        letterSpacing: 1, color: AppColors.zinc400)),
  ]);
}
