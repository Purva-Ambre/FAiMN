// lib/screens/screen1_overview.dart
// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/sensor_data.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/unit_card.dart';
import '../main.dart';
import 'screen2_unit_detail.dart';

class Screen1Overview extends StatefulWidget {
  const Screen1Overview({super.key});

  @override
  State<Screen1Overview> createState() => _Screen1OverviewState();
}

class _Screen1OverviewState extends State<Screen1Overview> {
  final _svc = FirebaseService();
  int _navIndex = 0; // 0 = Overview, 1 = Personnel Log

  SensorData? _latest;
  List<SensorData> _history = [];

  @override
  void initState() {
    super.initState();
    // Rebuild when theme changes so sidebar colours update immediately
    themeNotifier.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SensorData?>(
      stream: _svc.latestStream,
      builder: (ctx, snap) {
        if (snap.hasData) _latest = snap.data;
        return StreamBuilder<List<SensorData>>(
          stream: _svc.historyStream,
          builder: (ctx2, hSnap) {
            if (hSnap.hasData) _history = hSnap.data!;
            return Scaffold(
              backgroundColor: AppColors.background,
              body: Row(
                children: [
                  _Sidebar(
                    selected: _navIndex,
                    onSelect: (i) => setState(() => _navIndex = i),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        _TopBar(),
                        Expanded(
                          child: _navIndex == 0
                              ? _OverviewBody(
                                  latest: _latest,
                                  history: _history,
                                  onUnitTap: _goToDetail,
                                )
                              : _PersonnelLogBody(history: _history),
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

  void _goToDetail() {
    // Do NOT change _navIndex — Overview stays highlighted in the sidebar
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Screen2UnitDetail(latest: _latest, history: _history),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  SIDEBAR
// ════════════════════════════════════════════════════════════════════════════

class _Sidebar extends StatelessWidget {
  final int selected;
  final void Function(int) onSelect;
  const _Sidebar({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: AppColors.sidebarBg,
      child: Column(
        children: [
          // Brand header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.zinc800)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Icon(
                    Icons.shield_outlined,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FAiMN',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      'ACTIVE DEPLOYMENT',
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

          // Nav items
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  _NavItem(
                    icon: Icons.dashboard_outlined,
                    label: 'Overview',
                    index: 0,
                    selected: selected,
                    onTap: () => onSelect(0),
                  ),
                  _NavItem(
                    icon: Icons.people_outline,
                    label: 'Personnel Log',
                    index: 1,
                    selected: selected,
                    onTap: () => onSelect(1),
                  ),
                ],
              ),
            ),
          ),

          // Bottom actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.zinc800)),
            ),
            child: Column(
              children: [
                // System Diagnostics (display only, no navigation)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.monitor_heart_outlined,
                        color: AppColors.zinc500,
                        size: 16,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'System Diagnostics',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          color: AppColors.zinc500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // Help (display only)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.help_outline,
                        color: AppColors.zinc500,
                        size: 16,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Help',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          color: AppColors.zinc500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Dispatch Support button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {},
                    child: Text(
                      'DISPATCH SUPPORT',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
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

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index, selected;
  final VoidCallback onTap;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = index == selected;
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
//  TOP BAR  (with dark/light toggle)
// ════════════════════════════════════════════════════════════════════════════

class _TopBar extends StatefulWidget {
  const _TopBar();

  @override
  State<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<_TopBar> {
  @override
  void initState() {
    super.initState();
    themeNotifier.addListener(_onThemeChange);
  }

  void _onThemeChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    themeNotifier.removeListener(_onThemeChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = themeNotifier.isDark;
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.zinc800)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'FAiMN',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.onSurface,
              letterSpacing: 0.5,
            ),
          ),
          Row(
            children: [
              // ── Dark / Light toggle ──────────────────────────────────────
              GestureDetector(
                onTap: () => themeNotifier.toggle(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 56,
                  height: 28,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.zinc700
                        : AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.4),
                    ),
                  ),
                  child: Stack(
                    children: [
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 250),
                        alignment: isDark
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isDark ? Icons.dark_mode : Icons.light_mode,
                            color: AppColors.background,
                            size: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              _TopBarIcon(Icons.notifications_outlined),
              const SizedBox(width: 20),
              _TopBarIcon(Icons.access_time_outlined),
              const SizedBox(width: 20),
              _TopBarIcon(Icons.settings_outlined),
              const SizedBox(width: 20),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.zinc600),
                  image: const DecorationImage(
                    image: NetworkImage('https://i.pravatar.cc/64?img=3'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopBarIcon extends StatelessWidget {
  final IconData icon;
  const _TopBarIcon(this.icon);
  @override
  Widget build(BuildContext context) =>
      Icon(icon, color: AppColors.zinc400, size: 20);
}

// ════════════════════════════════════════════════════════════════════════════
//  OVERVIEW BODY
// ════════════════════════════════════════════════════════════════════════════

// Dummy user data — shown as inactive "PENDING" slots
class _DummyUser {
  final String unitId;
  final String name;
  final String role;
  const _DummyUser(this.unitId, this.name, this.role);
}

const _dummyUsers = [
  _DummyUser('UNIT-02', 'USER 2', 'FIREFIGHTER II'),
  _DummyUser('UNIT-03', 'USER 3', 'LADDER CO.'),
  _DummyUser('UNIT-04', 'USER 4', 'RESCUE SPEC.'),
  _DummyUser('UNIT-05', 'USER 5', 'HAZ-MAT LEAD'),
];

class _OverviewBody extends StatelessWidget {
  final SensorData? latest;
  final List<SensorData> history;
  final VoidCallback onUnitTap;

  const _OverviewBody({
    this.latest,
    required this.history,
    required this.onUnitTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = latest?.overallStatus ?? SafetyStatus.unknown;
    final alertCount =
        (status == SafetyStatus.danger || status == SafetyStatus.warning)
        ? 1
        : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Summary Cards ──
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: 'TOTAL FIREFIGHTERS',
                  value: '01',
                  icon: Icons.people_outline,
                  iconColor: AppColors.zinc400,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SummaryCard(
                  label: 'ACTIVE ALERTS',
                  value: alertCount.toString().padLeft(2, '0'),
                  icon: Icons.warning_amber_outlined,
                  iconColor: alertCount > 0
                      ? AppColors.danger
                      : AppColors.zinc400,
                  valueColor: alertCount > 0 ? AppColors.danger : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SummaryCard(
                  label: 'SYSTEM HEALTH',
                  value: '100%',
                  icon: Icons.bolt_outlined,
                  iconColor: AppColors.primary,
                  valueColor: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Section label: Active Units ──
          Text(
            'ACTIVE UNITS',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: AppColors.zinc400,
            ),
          ),
          const SizedBox(height: 12),

          // ── Live Unit Card ──
          if (latest == null)
            _LoadingState()
          else
            LayoutBuilder(
              builder: (ctx, constraints) {
                final cols = constraints.maxWidth > 1000
                    ? 4
                    : constraints.maxWidth > 600
                    ? 2
                    : 1;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: 1,
                  itemBuilder: (_, i) => UnitCard(
                    unitId: 'UNIT-01',
                    name: 'USER 1',
                    data: latest!,
                    lastUpdated: history.isNotEmpty
                        ? history.last.timestamp
                        : null,
                    onTap: onUnitTap,
                  ),
                );
              },
            ),

          const SizedBox(height: 28),

          // ── Section label: Pending Units ──
          Row(
            children: [
              Text(
                'PENDING UNITS',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: AppColors.zinc400,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.zinc700,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'AWAITING DEVICE JOIN',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: AppColors.zinc400,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Dummy inactive cards grid ──
          LayoutBuilder(
            builder: (ctx, constraints) {
              final cols = constraints.maxWidth > 1000
                  ? 4
                  : constraints.maxWidth > 600
                  ? 2
                  : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.82,
                ),
                itemCount: _dummyUsers.length,
                itemBuilder: (_, i) => _InactiveUnitCard(user: _dummyUsers[i]),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Inactive (dummy) unit card ─────────────────────────────────────────────────
class _InactiveUnitCard extends StatelessWidget {
  final _DummyUser user;
  const _InactiveUnitCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                user.unitId,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.zinc500,
                  letterSpacing: 1.2,
                ),
              ),
              // Offline badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.zinc700,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.zinc500,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'OFFLINE',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: AppColors.zinc500,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Name
          Text(
            user.name,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.zinc500,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.role,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
              color: AppColors.zinc600,
            ),
          ),
          const SizedBox(height: 16),

          // Dashed placeholder rows
          _PlaceholderRow(),
          const SizedBox(height: 10),
          _PlaceholderRow(),
          const SizedBox(height: 10),
          _PlaceholderRow(),

          const Spacer(),
          Divider(color: AppColors.zinc700, height: 1),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AWAITING CONNECTION',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: AppColors.zinc600,
                  letterSpacing: 0.8,
                ),
              ),
              Icon(Icons.link_off_rounded, size: 14, color: AppColors.zinc600),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlaceholderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.zinc700.withOpacity(0.5),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.zinc700.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Summary card (Total / Alerts / Health) ────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color iconColor;
  final Color? valueColor;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: AppColors.zinc400,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: valueColor ?? AppColors.onSurface,
                  height: 1,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
          Icon(icon, color: iconColor, size: 32),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(60),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
          const SizedBox(height: 16),
          Text(
            'Connecting to Firebase…',
            style: TextStyle(color: AppColors.zinc400),
          ),
        ],
      ),
    ),
  );
}

// ════════════════════════════════════════════════════════════════════════════
//  PERSONNEL LOG BODY
// ════════════════════════════════════════════════════════════════════════════

class _PersonnelLogBody extends StatelessWidget {
  final List<SensorData> history;
  const _PersonnelLogBody({required this.history});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personnel Log',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Last ${history.length} sensor readings · device_001',
            style: TextStyle(color: AppColors.zinc400, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: history.isEmpty
                ? Center(
                    child: Text(
                      'No history data yet.',
                      style: TextStyle(color: AppColors.zinc500),
                    ),
                  )
                : ListView.separated(
                    itemCount: history.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final d = history[history.length - 1 - i];
                      return _LogRow(data: d);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  final SensorData data;
  const _LogRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final c = statusColor(data.overallStatus);
    final ts = data.timestamp;
    final timeStr = ts != null
        ? '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}:${ts.second.toString().padLeft(2, '0')}'
        : '--:--:--';
    final dateStr = ts != null
        ? '${ts.year}-${ts.month.toString().padLeft(2, '0')}-${ts.day.toString().padLeft(2, '0')}'
        : '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 38,
            decoration: BoxDecoration(
              color: c,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                timeStr,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              Text(
                dateStr,
                style: TextStyle(fontSize: 9, color: AppColors.zinc500),
              ),
            ],
          ),
          const SizedBox(width: 20),
          _Col(
            'BODY',
            '${data.tempBody.toStringAsFixed(1)}°',
            statusColor(data.bodyStatus),
          ),
          const SizedBox(width: 10),
          _Col(
            'AMB',
            '${data.tempAmbient.toStringAsFixed(1)}°',
            statusColor(data.ambientStatus),
          ),
          const SizedBox(width: 10),
          _Col('CO', '${data.co}p', statusColor(data.coStatus)),
          const SizedBox(width: 10),
          _Col('PKT', '${data.packet}', AppColors.zinc400),
          const Spacer(),
          Text(
            data.cleanMovement.isEmpty ? 'UNKNOWN' : data.cleanMovement,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.zinc400,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: c.withOpacity(0.1),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: c.withOpacity(0.2)),
            ),
            child: Text(
              data.overallStatus.name.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: c,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Col extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Col(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 8,
          color: AppColors.zinc500,
          letterSpacing: 1,
        ),
      ),
      Text(
        value,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    ],
  );
}
