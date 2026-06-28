// lib/widgets/floor_indicator.dart
// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../models/sensor_data.dart';
import '../theme/app_theme.dart';
import 'common_widgets.dart';

class FloorIndicator extends StatelessWidget {
  final SensorData? data;
  const FloorIndicator({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    final cur = data?.floorNumber ?? 1;

    return DashCard(
      child: Row(
        children: [
          // Vertical bar
          Container(
            width: 36,
            height: 180,
            decoration: BoxDecoration(
              color: AppColors.zinc800,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.zinc700),
            ),
            padding: const EdgeInsets.all(3),
            child: Column(
              children: List.generate(5, (i) {
                final fn = 5 - i;
                final active = fn == cur;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.primary
                          : AppColors.zinc700.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.45),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                    child: active
                        ? Center(
                            child: Text(
                              '$fn',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppColors.background,
                              ),
                            ),
                          )
                        : null,
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SectionLabel('Current Elevation'),
                const SizedBox(height: 6),
                Text(
                  data != null ? data!.floorLabel : 'F-??',
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -1,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Structure: Warehouse B',
                  style: TextStyle(fontSize: 13, color: AppColors.zinc400),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.trending_flat,
                      color: AppColors.primary,
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      data?.floor.toUpperCase().contains('SAME') == true
                          ? 'STABLE LEVEL'
                          : 'LEVEL CHANGE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
