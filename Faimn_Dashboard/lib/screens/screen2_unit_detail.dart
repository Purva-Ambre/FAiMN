// lib/screens/screen2_unit_detail.dart
// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/sensor_data.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/temperature_chart.dart';
import '../widgets/co_gauge.dart';
import '../widgets/compass_widget.dart';
import '../widgets/floor_indicator.dart';
import '../widgets/critical_diagnostics.dart';

// ════════════════════════════════════════════════════════════════════════════
//  Screen2UnitDetail — now a StatefulWidget with its OWN Firebase streams
//
//  ROOT CAUSE OF THE BUG:
//  Previously this was a StatelessWidget that received `latest` and `history`
//  as constructor params — frozen snapshots from the moment you tapped the
//  card. New packets arrived in Firebase and updated Screen1, but Screen2
//  had no listener so it never rebuilt. You had to pop back and re-enter.
//
//  FIX:
//  Screen2 now creates its own FirebaseService + cached streams in initState,
//  exactly like Screen1. Every Firebase push triggers a rebuild here too.
//  The constructor params are kept as `initialLatest` / `initialHistory` so
//  the UI is populated instantly on open (no blank flash) while the stream
//  catches up.
// ════════════════════════════════════════════════════════════════════════════

class Screen2UnitDetail extends StatefulWidget {
  /// Seed data shown immediately on open — replaced by live stream within ms
  final SensorData? initialLatest;
  final List<SensorData> initialHistory;

  const Screen2UnitDetail({
    super.key,
    SensorData? latest,
    List<SensorData> history = const [],
  }) : initialLatest = latest,
       initialHistory = history;

  @override
  State<Screen2UnitDetail> createState() => _Screen2UnitDetailState();
}

class _Screen2UnitDetailState extends State<Screen2UnitDetail>
    with SingleTickerProviderStateMixin {
  final _svc = FirebaseService();

  late final Stream<SensorData?> _latestStream;
  late final Stream<List<SensorData>> _historyStream;

  SensorData? _latest;
  List<SensorData> _history = [];

  // For the packet-flash animation
  late final AnimationController _flashCtrl;
  late final Animation<Color?> _flashAnim;
  int _lastPacket = -1;

  @override
  void initState() {
    super.initState();

    // Seed with passed-in data so screen isn't blank on open
    _latest = widget.initialLatest;
    _history = widget.initialHistory;

    // Own Firebase streams — cached so StreamBuilder never re-subscribes
    _latestStream = _svc.latestStream;
    _historyStream = _svc.historyStream;

    // Flash animation: packet number badge briefly glows green on new packet
    _flashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flashAnim = ColorTween(
      begin: AppColors.primary,
      end: AppColors.zinc700,
    ).animate(CurvedAnimation(parent: _flashCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _flashCtrl.dispose();
    super.dispose();
  }

  void _onNewLatest(SensorData? data) {
    if (data == null) return;
    // Trigger flash animation whenever packet number increments
    if (data.packet != _lastPacket) {
      _lastPacket = data.packet;
      _flashCtrl.forward(from: 0);
    }
    _latest = data;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SensorData?>(
      stream: _latestStream,
      builder: (ctx, snap) {
        if (snap.hasData) _onNewLatest(snap.data);

        return StreamBuilder<List<SensorData>>(
          stream: _historyStream,
          builder: (ctx2, hSnap) {
            if (hSnap.hasData) _history = hSnap.data!;

            return Scaffold(
              backgroundColor: AppColors.background,
              body: Row(
                children: [
                  _DetailSidebar(onBack: () => Navigator.pop(context)),
                  Expanded(
                    child: Column(
                      children: [
                        _DetailTopBar(latest: _latest),
                        Expanded(
                          child: _DetailBody(
                            latest: _latest,
                            history: _history,
                            flashAnim: _flashAnim,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  LEFT SIDEBAR
// ════════════════════════════════════════════════════════════════════════════

class _DetailSidebar extends StatelessWidget {
  final VoidCallback onBack;
  const _DetailSidebar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: AppColors.sidebarBg,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.zinc800)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onBack,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.zinc800,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.zinc700),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      color: AppColors.zinc400,
                      size: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sector Alpha',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      'UNIT DETAIL',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                        color: AppColors.zinc400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  _SideItem(
                    icon: Icons.dashboard_outlined,
                    label: 'Overview',
                    active: true,
                    onTap: onBack,
                  ),
                  _SideItem(
                    icon: Icons.people_outline,
                    label: 'Personnel Log',
                    active: false,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.zinc800)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'LIVE DATA',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SideItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _SideItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: active ? AppColors.primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: active ? AppColors.primary : AppColors.zinc500,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? AppColors.primary : AppColors.zinc400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  TOP BAR
// ════════════════════════════════════════════════════════════════════════════

class _DetailTopBar extends StatelessWidget {
  final SensorData? latest;
  const _DetailTopBar({this.latest});

  @override
  Widget build(BuildContext context) {
    final status = latest?.overallStatus ?? SafetyStatus.unknown;
    final isDanger = status == SafetyStatus.danger;
    final isWarn = status == SafetyStatus.warning;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.zinc800)),
      ),
      child: Row(
        children: [
          Text(
            'FAiMN',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.onSurface,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 28),
          _Counter(count: 1, label: 'ACTIVE', color: AppColors.primary),
          const SizedBox(width: 14),
          _Counter(
            count: isWarn ? 1 : 0,
            label: 'WARNING',
            color: AppColors.warning,
          ),
          const SizedBox(width: 14),
          _Counter(
            count: isDanger ? 1 : 0,
            label: 'DANGER',
            color: AppColors.danger,
          ),
          const Spacer(),
          if (latest != null) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.5),
                    blurRadius: 5,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'LIVE',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(width: 18),
          ],
          GestureDetector(
            onTap: () => _showRecallDialog(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.dangerContainer,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                'EMERGENCY_RECALL',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.danger,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Icon(
            Icons.notifications_outlined,
            color: AppColors.zinc400,
            size: 18,
          ),
          const SizedBox(width: 12),
          Icon(Icons.settings_outlined, color: AppColors.zinc400, size: 18),
          const SizedBox(width: 12),
          Icon(
            Icons.account_circle_outlined,
            color: AppColors.zinc400,
            size: 18,
          ),
        ],
      ),
    );
  }

  void _showRecallDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceHighlight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppColors.danger.withOpacity(0.3)),
        ),
        title: Text(
          'EMERGENCY RECALL',
          style: GoogleFonts.spaceGrotesk(
            color: AppColors.danger,
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 1.5,
          ),
        ),
        content: Text(
          'Issue emergency recall for all active units in Sector Alpha?',
          style: TextStyle(color: AppColors.zinc400),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL',
              style: TextStyle(color: AppColors.zinc500, fontSize: 12),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dangerContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'EMERGENCY RECALL ISSUED',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  backgroundColor: AppColors.dangerContainer,
                ),
              );
            },
            child: Text(
              'CONFIRM RECALL',
              style: TextStyle(
                color: AppColors.danger,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  const _Counter({
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final zero = count == 0;
    return Text(
      '${count.toString().padLeft(2, '0')} $label',
      style: GoogleFonts.spaceGrotesk(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: zero ? AppColors.zinc500 : color,
        letterSpacing: 0.8,
        decoration: zero ? null : TextDecoration.underline,
        decorationColor: color,
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  DETAIL BODY
// ════════════════════════════════════════════════════════════════════════════

class _DetailBody extends StatelessWidget {
  final SensorData? latest;
  final List<SensorData> history;
  final Animation<Color?> flashAnim; // packet-flash colour animation

  const _DetailBody({
    this.latest,
    required this.history,
    required this.flashAnim,
  });

  @override
  Widget build(BuildContext context) {
    final status = latest?.overallStatus ?? SafetyStatus.unknown;
    final sColor = statusColor(status);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Unit header ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.only(left: 16),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: sColor, width: 4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'UNIT ID: #F-2901',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.3,
                        color: AppColors.zinc400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'USER 1',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: AppColors.primary,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'SECTOR 1',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.zinc400,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                _UnitStatusBadge(status),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Row 1: Temperature chart + CO gauge ──────────────────────────
          LayoutBuilder(
            builder: (ctx, constraints) {
              if (constraints.maxWidth > 700) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: TemperatureChart(history: history, latest: latest),
                    ),
                    const SizedBox(width: 14),
                    Expanded(flex: 3, child: CoGauge(data: latest)),
                  ],
                );
              }
              return Column(
                children: [
                  TemperatureChart(history: history, latest: latest),
                  const SizedBox(height: 14),
                  CoGauge(data: latest),
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          // ── Row 2: Compass + Floor + Diagnostics ─────────────────────────
          LayoutBuilder(
            builder: (ctx, constraints) {
              if (constraints.maxWidth > 700) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: CompassWidget(data: latest)),
                    const SizedBox(width: 14),
                    Expanded(flex: 3, child: FloorIndicator(data: latest)),
                    const SizedBox(width: 14),
                    Expanded(flex: 4, child: CriticalDiagnostics(data: latest)),
                  ],
                );
              }
              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: CompassWidget(data: latest)),
                      const SizedBox(width: 14),
                      Expanded(child: FloorIndicator(data: latest)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  CriticalDiagnostics(data: latest),
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          // ── Environmental banner ─────────────────────────────────────────
          _EnvBanner(data: latest, flashAnim: flashAnim),
        ],
      ),
    );
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────
class _UnitStatusBadge extends StatelessWidget {
  final SafetyStatus status;
  const _UnitStatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final c = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.withOpacity(0.35)),
        boxShadow: [BoxShadow(color: c.withOpacity(0.15), blurRadius: 14)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STATUS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.3,
              color: c.withOpacity(0.65),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            status.name.toUpperCase(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Environmental banner with animated PACKET counter ────────────────────────
class _EnvBanner extends StatelessWidget {
  final SensorData? data;
  final Animation<Color?> flashAnim;
  const _EnvBanner({this.data, required this.flashAnim});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionLabel(
                  'Live Environmental Mapping',
                  color: AppColors.primary,
                ),
                const SizedBox(height: 4),
                Text(
                  'THERMAL OPTICS ACTIVE',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Visualizing structural integrity within 20m radius.',
                  style: TextStyle(fontSize: 12, color: AppColors.zinc400),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _Chip('SIGNAL', 'OPTIMAL', AppColors.primary),
          const SizedBox(width: 8),
          _Chip('ENCRYPTION', 'AES-256', AppColors.onSurface),
          const SizedBox(width: 8),
          // Animated packet counter — flashes green on every new packet
          AnimatedBuilder(
            animation: flashAnim,
            builder: (_, __) => _Chip(
              'PACKET',
              '${data?.packet ?? "--"}',
              flashAnim.value ?? AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Chip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.background.withOpacity(0.4),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: AppColors.zinc700),
    ),
    child: Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            color: AppColors.zinc500,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    ),
  );
}
