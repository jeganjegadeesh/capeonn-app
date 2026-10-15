import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../auth/application/auth_controller.dart';
import '../application/attendance_controller.dart';
import '../data/attendance_models.dart';
import '../data/attendance_repository.dart';

class AttendancePage extends ConsumerStatefulWidget {
  const AttendancePage({super.key});

  @override
  ConsumerState<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends ConsumerState<AttendancePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _timer;
  int _liveSeconds = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _liveSeconds++;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;
    final todayAsync = ref.watch(attendanceTodayProvider);
    final summaryAsync = ref.watch(attendanceSummaryProvider((null, null)));
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    final isExemptAdmin = user != null && (!user.isAttendanceApplicable || user.isAdmin);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attendance & Time Tracking',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isExemptAdmin
                            ? 'Monitor all clock-in eligible employee records, today\'s live presence, and regularization approvals.'
                            : 'Record your daily presence, track hours, and submit regularizations.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh All Attendance Data',
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    ref.read(attendanceTodayProvider.notifier).refresh();
                    ref.invalidate(attendanceDailyStatusProvider);
                    ref.invalidate(allAttendanceRecordsProvider);
                    ref.invalidate(teamAttendanceRecordsProvider);
                    ref.invalidate(myAttendanceRecordsProvider);
                    ref.invalidate(attendanceSummaryProvider);
                    ref.invalidate(regularizationsProvider);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Hero Clock In / Clock Out Card or Admin Monitoring Banner
            todayAsync.when(
              data: (today) {
                if (today == null) return const SizedBox.shrink();
                final elapsed = today.isClockedIn ? (today.elapsedSeconds + _liveSeconds) : 0;

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: AppColors.border),
                  ),
                  color: AppColors.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            // Current Status Info
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: today.isClockedIn
                                        ? AppColors.emeraldContainer
                                        : (today.isClockedOut
                                            ? AppColors.primaryContainer
                                            : (!today.isApplicable
                                                ? AppColors.primaryLight.withValues(alpha: 0.15)
                                                : const Color(0xFFF1F5F9))),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    today.isClockedIn
                                        ? Icons.timer
                                        : (today.isClockedOut
                                            ? Icons.check_circle_outline
                                            : (!today.isApplicable
                                                ? Icons.admin_panel_settings_outlined
                                                : Icons.access_time)),
                                    color: today.isClockedIn
                                        ? AppColors.emerald
                                        : (today.isClockedOut
                                            ? AppColors.primary
                                            : (!today.isApplicable
                                                ? AppColors.primary
                                                : AppColors.textSecondary)),
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      today.isClockedIn
                                          ? 'Currently Clocked In'
                                          : (today.isClockedOut
                                              ? 'Clocked Out for Today'
                                              : (!today.isApplicable
                                                  ? 'Administrator Attendance Center'
                                                  : 'Not Clocked In Yet')),
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 2),
                                    if (!today.isApplicable)
                                      Text(
                                        'All clock-in eligible users monitored. Personal check-in is exempt for this account.',
                                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      )
                                    else if (today.attendance?.clockInAt != null)
                                      Text(
                                        'In: ${today.attendance!.clockInAt!.substring(11, 16)}'
                                        '${today.attendance?.clockOutAt != null ? " • Out: ${today.attendance!.clockOutAt!.substring(11, 16)}" : ""}',
                                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      )
                                    else
                                      Text('Today: ${today.date}', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ],
                            ),

                            // Live Timer Display (for employees)
                            if (today.isClockedIn)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.emeraldContainer,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.emerald.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.alarm, size: 18, color: AppColors.emerald),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatDuration(elapsed),
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.emerald,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Action Buttons
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (!today.isApplicable) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.emeraldContainer,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.emerald.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.people_alt, size: 16, color: AppColors.emerald),
                                        const SizedBox(width: 6),
                                        Text(
                                          'All Clock-In Users Monitored',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.emerald),
                                        ),
                                      ],
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: const Icon(Icons.refresh, size: 16),
                                    label: const Text('Refresh Status'),
                                    onPressed: () {
                                      ref.invalidate(attendanceDailyStatusProvider);
                                      ref.invalidate(allAttendanceRecordsProvider);
                                      ref.invalidate(attendanceSummaryProvider);
                                    },
                                  ),
                                ] else ...[
                                  if (!today.isClockedIn && !today.isClockedOut)
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.emerald,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      icon: const Icon(Icons.login, size: 18),
                                      label: const Text('Clock In Now', style: TextStyle(fontWeight: FontWeight.bold)),
                                      onPressed: () => _handleClockIn(context),
                                    ),
                                  if (today.isClockedIn)
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.rose,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      icon: const Icon(Icons.logout, size: 18),
                                      label: const Text('Clock Out', style: TextStyle(fontWeight: FontWeight.bold)),
                                      onPressed: () => _handleClockOut(context),
                                    ),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: const Icon(Icons.edit_calendar, size: 18),
                                    label: const Text('Regularize'),
                                    onPressed: () => _openRegularizationDialog(context),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),

                        // Office Geofence Proximity Bar
                        if (today.officeLocations.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          const Divider(height: 1),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 16, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Geofenced Location: ${today.officeLocations.first.name} (${today.officeLocations.first.radiusMeters}m radius)',
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (today.attendance != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: today.attendance!.isFlagged ? AppColors.roseContainer : AppColors.emeraldContainer,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    today.attendance!.isFlagged ? 'Out-of-office' : 'In office',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: today.attendance!.isFlagged ? AppColors.rose : AppColors.emerald,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Center(child: Text('Error loading status: $e')),
            ),
            const SizedBox(height: 20),

            // Summary Cards (Organization-wide for Admin, Personal for Employees)
            summaryAsync.when(
              data: (summary) => _buildSummaryCards(summary),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),

            // Tabs Header
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                isScrollable: !isDesktop,
                tabAlignment: !isDesktop ? TabAlignment.start : TabAlignment.fill,
                tabs: [
                  if (isExemptAdmin) ...[
                    const Tab(text: 'All Users Attendance'),
                    const Tab(text: 'Regularization Requests'),
                    const Tab(text: 'Office Locations'),
                  ] else ...[
                    const Tab(text: 'My Attendance Logs'),
                    if (user?.canManageAttendance == true)
                      const Tab(text: 'Team Records')
                    else
                      const Tab(text: 'Calendar View'),
                    const Tab(text: 'Regularization Requests'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab Content
            SizedBox(
              height: 600,
              child: TabBarView(
                controller: _tabController,
                children: [
                  if (isExemptAdmin) ...[
                    const _AllUsersAttendanceTab(),
                    const _RegularizationsList(canManage: true),
                    todayAsync.maybeWhen(
                      data: (today) => _GeofenceLocationsTab(locations: today?.officeLocations ?? const []),
                      orElse: () => const _GeofenceLocationsTab(locations: []),
                    ),
                  ] else ...[
                    _MyAttendanceList(),
                    if (user?.canManageAttendance == true)
                      const _AllUsersAttendanceTab()
                    else
                      _MyAttendanceList(),
                    _RegularizationsList(canManage: user?.canManageAttendance ?? false),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(AttendanceSummary s) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth >= 700
            ? (constraints.maxWidth - 48) / 4
            : (constraints.maxWidth >= 380 ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth);

        if (s.isOrganization) {
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _MetricCard(
                title: 'Eligible Staff',
                value: '${s.eligibleUsersCount ?? 0} Users',
                icon: Icons.people_outline,
                color: AppColors.primary,
                bg: AppColors.primaryLight.withValues(alpha: 0.15),
                width: cardWidth,
              ),
              _MetricCard(
                title: 'Clocked In Today',
                value: '${s.todayClockedInCount ?? 0} Active',
                icon: Icons.check_circle_outline,
                color: AppColors.emerald,
                bg: AppColors.emeraldContainer,
                width: cardWidth,
              ),
              _MetricCard(
                title: 'Late Today',
                value: '${s.todayLateCount ?? 0} Late',
                icon: Icons.schedule,
                color: AppColors.amber,
                bg: AppColors.amberContainer,
                width: cardWidth,
              ),
              _MetricCard(
                title: 'Pending Check-In',
                value: '${s.todayAbsentCount ?? 0} Pending',
                icon: Icons.pending_actions_outlined,
                color: const Color(0xFF64748B),
                bg: const Color(0xFFF1F5F9),
                width: cardWidth,
              ),
            ],
          );
        }

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _MetricCard(
              title: 'Days Present',
              value: '${s.daysPresent}',
              icon: Icons.check_circle_outline,
              color: AppColors.emerald,
              bg: AppColors.emeraldContainer,
              width: cardWidth,
            ),
            _MetricCard(
              title: 'Days Late',
              value: '${s.daysLate}',
              icon: Icons.schedule,
              color: AppColors.amber,
              bg: AppColors.amberContainer,
              width: cardWidth,
            ),
            _MetricCard(
              title: 'Half Days',
              value: '${s.daysHalfDay}',
              icon: Icons.timelapse,
              color: const Color(0xFFF97316),
              bg: const Color(0xFFFFF7ED),
              width: cardWidth,
            ),
            _MetricCard(
              title: 'Total Hours',
              value: '${s.totalHours} hrs',
              icon: Icons.hourglass_bottom,
              color: AppColors.secondary,
              bg: AppColors.primaryContainer,
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }

  void _handleClockIn(BuildContext context) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Clock-In'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your check-in time and office GPS coordinates will be verified.'),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'e.g., Working from Bangalore office',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.emerald, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(attendanceTodayProvider.notifier).clockIn(
                  latitude: 12.9716,
                  longitude: 77.5946,
                  locationName: 'Bangalore Office',
                  notes: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Clocked in successfully!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Clock-in failed: $e'), backgroundColor: AppColors.rose),
                  );
                }
              }
            },
            child: const Text('Clock In'),
          ),
        ],
      ),
    );
  }

  void _handleClockOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clock Out'),
        content: const Text('Are you sure you want to clock out for today? Total hours will be calculated.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.rose, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(attendanceTodayProvider.notifier).clockOut();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Clocked out successfully!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Clock-out failed: $e'), backgroundColor: AppColors.rose),
                  );
                }
              }
            },
            child: const Text('Clock Out'),
          ),
        ],
      ),
    );
  }

  void _openRegularizationDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final dateController = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
    final inTimeController = TextEditingController(text: '09:00');
    final outTimeController = TextEditingController(text: '18:00');
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request Regularization'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: dateController,
                decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)', border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: inTimeController,
                decoration: const InputDecoration(labelText: 'Clock-In Time (HH:MM)', border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: outTimeController,
                decoration: const InputDecoration(labelText: 'Clock-Out Time (HH:MM)', border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: reasonController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Reason for Adjustment', border: OutlineInputBorder()),
                validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a valid reason' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              try {
                final date = dateController.text.trim();
                final reqIn = '$date ${inTimeController.text.trim()}:00';
                final reqOut = '$date ${outTimeController.text.trim()}:00';
                await ref.read(attendanceRepositoryProvider).requestRegularization(
                  date: date,
                  requestedClockIn: reqIn,
                  requestedClockOut: reqOut,
                  reason: reasonController.text.trim(),
                );
                ref.invalidate(regularizationsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Regularization request submitted!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.rose),
                  );
                }
              }
            },
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.bg,
    required this.width,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color bg;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AllUsersAttendanceTab extends ConsumerStatefulWidget {
  const _AllUsersAttendanceTab();

  @override
  ConsumerState<_AllUsersAttendanceTab> createState() => _AllUsersAttendanceTabState();
}

class _AllUsersAttendanceTabState extends ConsumerState<_AllUsersAttendanceTab> {
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';
  String? _statusFilter;
  bool _isRosterView = true;

  String get _dateStr => _selectedDate.toIso8601String().substring(0, 10);
  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2027),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Toolbar: View switcher, date controls, quick jump
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Mode Segmented Buttons
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _modeButton(
                    title: 'All Users Live Roster',
                    icon: Icons.group_outlined,
                    isActive: _isRosterView,
                    onTap: () => setState(() => _isRosterView = true),
                  ),
                  _modeButton(
                    title: 'Punch History Logs',
                    icon: Icons.list_alt,
                    isActive: !_isRosterView,
                    onTap: () => setState(() => _isRosterView = false),
                  ),
                ],
              ),
            ),

            // Date Navigation Controls
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Previous Day',
                  icon: const Icon(Icons.chevron_left, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => _changeDate(-1),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.calendar_today, size: 14),
                  label: Text(
                    _isToday ? 'Today ($_dateStr)' : _dateStr,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  onPressed: () => _pickDate(context),
                ),
                IconButton(
                  tooltip: 'Next Day',
                  icon: const Icon(Icons.chevron_right, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => _changeDate(1),
                ),
                if (!_isToday) ...[
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: () => setState(() => _selectedDate = DateTime.now()),
                    child: const Text('Today', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Search & Filter Bar
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 260,
              height: 38,
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search employee by name/code...',
                  hintStyle: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.search, size: 18),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _filterChip(label: 'All', value: null),
                _filterChip(label: 'Present', value: 'present'),
                _filterChip(label: 'Late', value: 'late'),
                _filterChip(label: 'Not Clocked In', value: 'absent'),
                _filterChip(label: 'Flagged', value: 'flagged'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Body Content
        Expanded(
          child: _isRosterView ? _buildRosterView() : _buildLogsView(),
        ),
      ],
    );
  }

  Widget _modeButton({
    required String title,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isActive ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1))] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: isActive ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip({required String label, required String? value}) {
    final isSelected = _statusFilter == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      onSelected: (_) => setState(() => _statusFilter = value),
      selectedColor: AppColors.primaryLight.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildRosterView() {
    final dailyAsync = ref.watch(attendanceDailyStatusProvider((_dateStr, null)));

    return dailyAsync.when(
      data: (result) {
        var users = result.users;

        // Apply search query
        if (_searchQuery.isNotEmpty) {
          users = users.where((u) {
            final nameMatch = u.userName.toLowerCase().contains(_searchQuery);
            final codeMatch = (u.employeeCode ?? '').toLowerCase().contains(_searchQuery);
            final deptMatch = (u.departmentName ?? '').toLowerCase().contains(_searchQuery);
            return nameMatch || codeMatch || deptMatch;
          }).toList();
        }

        // Apply status filter
        if (_statusFilter != null) {
          if (_statusFilter == 'flagged') {
            users = users.where((u) => u.isFlagged).toList();
          } else if (_statusFilter == 'present') {
            users = users.where((u) => u.status == 'present' || u.isClockedIn).toList();
          } else {
            users = users.where((u) => u.status == _statusFilter).toList();
          }
        }

        return Column(
          children: [
            // Quick Status Strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${result.totalUsers} Clock-in Eligible Staff: ${result.presentCount} Present, ${result.lateCount} Late, ${result.absentCount} Not Clocked In, ${result.flaggedCount} Flagged',
                      style: TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            if (users.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('No employees match your search or filter criteria.'),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: users.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final u = users[idx];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: AppColors.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            UserAvatar(
                              name: u.userName,
                              avatarUrl: u.avatarUrl,
                              radius: 22,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 2,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Text(u.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      if (u.employeeCode != null)
                                        Text('(${u.employeeCode})', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${u.departmentName ?? "Department"} • ${u.designationName ?? "Role"}',
                                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 4),
                                  if (u.clockInAt != null)
                                    Text(
                                      'In: ${u.clockInAt!.substring(11, 16)}'
                                      '${u.clockOutAt != null ? " • Out: ${u.clockOutAt!.substring(11, 16)}" : " • Active Now"}'
                                      '${u.clockInLocationName != null ? " • Loc: ${u.clockInLocationName}" : ""}',
                                      style: TextStyle(fontSize: 11, color: AppColors.textPrimary),
                                    )
                                  else
                                    Text(
                                      'Not clocked in for $_dateStr',
                                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _statusBadge(u.status, isClockedIn: u.isClockedIn),
                                if (u.isFlagged) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: AppColors.roseContainer, borderRadius: BorderRadius.circular(4)),
                                    child: Text(
                                      'OUT-OF-OFFICE',
                                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.rose),
                                    ),
                                  ),
                                ],
                                if (u.totalMinutes > 0) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    u.totalHoursFormatted,
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading daily status: $e')),
    );
  }

  Widget _buildLogsView() {
    final recordsAsync = ref.watch(allAttendanceRecordsProvider((
      date: _dateStr,
      departmentId: null,
      userId: null,
      status: _statusFilter == 'flagged' ? null : _statusFilter,
      isFlagged: _statusFilter == 'flagged' ? true : null,
    )));

    return recordsAsync.when(
      data: (records) {
        var filtered = records;
        if (_searchQuery.isNotEmpty) {
          filtered = filtered.where((r) {
            final nameMatch = (r.userName ?? '').toLowerCase().contains(_searchQuery);
            final codeMatch = (r.employeeCode ?? '').toLowerCase().contains(_searchQuery);
            return nameMatch || codeMatch;
          }).toList();
        }

        if (filtered.isEmpty) {
          return Center(
            child: Text('No attendance punch records found for $_dateStr.'),
          );
        }

        return ListView.separated(
          itemCount: filtered.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, idx) {
            final r = filtered[idx];
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: AppColors.border),
              ),
              child: ListTile(
                leading: UserAvatar(
                  name: r.userName ?? 'Employee',
                  avatarUrl: r.avatarUrl,
                  radius: 20,
                ),
                title: Wrap(
                  spacing: 8,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(r.userName ?? 'Employee', style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (r.employeeCode != null)
                      Text('(${r.employeeCode})', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
                subtitle: Text(
                  'Date: ${r.date} • In: ${r.clockInAt != null ? r.clockInAt!.substring(11, 16) : "--"} • Out: ${r.clockOutAt != null ? r.clockOutAt!.substring(11, 16) : "--"}'
                  '${r.clockInLocationName != null ? " • ${r.clockInLocationName}" : ""}'
                  '${r.flaggedReason != null ? " • [Flag: ${r.flaggedReason}]" : ""}',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      r.status.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: r.isFlagged ? AppColors.rose : (r.status == 'present' ? AppColors.emerald : AppColors.amber),
                      ),
                    ),
                    if (r.totalMinutes > 0)
                      Text(
                        r.totalHoursFormatted,
                        style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading punch logs: $e')),
    );
  }

  Widget _statusBadge(String status, {bool isClockedIn = false}) {
    Color bg;
    Color fg;
    String label = status.toUpperCase();

    switch (status) {
      case 'present':
        bg = AppColors.emeraldContainer;
        fg = AppColors.emerald;
        if (isClockedIn) label = 'CLOCKED IN';
        break;
      case 'late':
        bg = AppColors.amberContainer;
        fg = AppColors.amber;
        break;
      case 'half_day':
        bg = const Color(0xFFFFF7ED);
        fg = const Color(0xFFF97316);
        break;
      case 'absent':
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
        label = 'NOT CLOCKED IN';
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        fg = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}

class _MyAttendanceList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(myAttendanceRecordsProvider((null, null)));

    return recordsAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return const Center(child: Text('No attendance records found for this period.'));
        }

        return ListView.separated(
          itemCount: records.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, idx) {
            final r = records[idx];
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: AppColors.border),
              ),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: r.status == 'present'
                        ? AppColors.emeraldContainer
                        : (r.status == 'late' ? AppColors.amberContainer : const Color(0xFFFFF7ED)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      r.date.substring(8),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: r.status == 'present'
                            ? AppColors.emerald
                            : (r.status == 'late' ? AppColors.amber : const Color(0xFFF97316)),
                      ),
                    ),
                  ),
                ),
                title: Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(r.date, style: const TextStyle(fontWeight: FontWeight.bold)),
                    _statusBadge(r.status),
                    if (r.isFlagged)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.roseContainer, borderRadius: BorderRadius.circular(4)),
                        child: const Text('FLAGGED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.rose)),
                      ),
                  ],
                ),
                subtitle: Text(
                  'In: ${r.clockInAt != null ? r.clockInAt!.substring(11, 16) : "--"} • Out: ${r.clockOutAt != null ? r.clockOutAt!.substring(11, 16) : "--"}'
                  '${r.notes != null ? " • Note: ${r.notes}" : ""}',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                trailing: Text(
                  r.totalHoursFormatted,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading records: $e')),
    );
  }

  Widget _statusBadge(String status) {
    Color bg;
    Color fg;
    switch (status) {
      case 'present':
        bg = AppColors.emeraldContainer;
        fg = AppColors.emerald;
        break;
      case 'late':
        bg = AppColors.amberContainer;
        fg = AppColors.amber;
        break;
      case 'half_day':
        bg = const Color(0xFFFFF7ED);
        fg = const Color(0xFFF97316);
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        fg = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}

class _RegularizationsList extends ConsumerWidget {
  const _RegularizationsList({required this.canManage});

  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final regsAsync = ref.watch(regularizationsProvider);

    return regsAsync.when(
      data: (regs) {
        if (regs.isEmpty) {
          return const Center(child: Text('No regularization requests.'));
        }

        return ListView.separated(
          itemCount: regs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, idx) {
            final r = regs[idx];
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UserAvatar(
                      name: r.userName ?? 'Employee',
                      radius: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(r.userName ?? 'Employee', style: const TextStyle(fontWeight: FontWeight.bold)),
                              if (r.employeeCode != null)
                                Text('(${r.employeeCode})', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              _statusPill(r.status),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Date: ${r.date} • Requested: ${r.requestedClockIn.substring(11, 16)} to ${r.requestedClockOut.substring(11, 16)}',
                            style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text('Reason: ${r.reason}', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    if (canManage && r.status == 'pending') ...[
                      IconButton(
                        tooltip: 'Approve Regularization',
                        icon: const Icon(Icons.check_circle, color: AppColors.emerald),
                        onPressed: () async {
                          await ref.read(attendanceRepositoryProvider).approveRegularization(r.id);
                          ref.invalidate(regularizationsProvider);
                          ref.invalidate(myAttendanceRecordsProvider);
                          ref.invalidate(allAttendanceRecordsProvider);
                          ref.invalidate(attendanceDailyStatusProvider);
                          ref.invalidate(attendanceSummaryProvider);
                          ref.read(attendanceTodayProvider.notifier).refresh();
                        },
                      ),
                      IconButton(
                        tooltip: 'Reject Regularization',
                        icon: const Icon(Icons.cancel, color: AppColors.rose),
                        onPressed: () async {
                          await ref.read(attendanceRepositoryProvider).rejectRegularization(r.id);
                          ref.invalidate(regularizationsProvider);
                        },
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading regularizations: $e')),
    );
  }

  Widget _statusPill(String status) {
    Color bg;
    Color fg;
    switch (status) {
      case 'approved':
        bg = AppColors.emeraldContainer;
        fg = AppColors.emerald;
        break;
      case 'rejected':
        bg = AppColors.roseContainer;
        fg = AppColors.rose;
        break;
      case 'pending':
      default:
        bg = AppColors.amberContainer;
        fg = AppColors.amber;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}

class _GeofenceLocationsTab extends StatelessWidget {
  const _GeofenceLocationsTab({required this.locations});

  final List<OfficeLocation> locations;

  @override
  Widget build(BuildContext context) {
    if (locations.isEmpty) {
      return const Center(child: Text('No office geofence locations configured.'));
    }

    return ListView.separated(
      itemCount: locations.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, idx) {
        final loc = locations[idx];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: AppColors.border),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.location_on, color: AppColors.primary, size: 22),
            ),
            title: Text(loc.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (loc.address != null) Text(loc.address!, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text(
                  'GPS: ${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)} • Radius: ${loc.radiusMeters}m',
                  style: TextStyle(fontSize: 11, color: AppColors.textPrimary),
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.emeraldContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('ACTIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.emerald)),
            ),
          ),
        );
      },
    );
  }
}
