import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
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
    if (user != null && user.isSuperAdmin) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.block, size: 48, color: AppColors.textMuted),
                const SizedBox(height: 12),
                Text(
                  'Attendance tracking is not applicable for Super Admin accounts.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final todayAsync = ref.watch(attendanceTodayProvider);
    final summaryAsync = ref.watch(attendanceSummaryProvider((null, null)));
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

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
                        'Record your daily presence, track hours, and submit regularizations.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    ref.read(attendanceTodayProvider.notifier).refresh();
                    ref.invalidate(myAttendanceRecordsProvider);
                    ref.invalidate(attendanceSummaryProvider);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Hero Clock In / Clock Out Card
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
                                        : (today.isClockedOut ? AppColors.primaryContainer : const Color(0xFFF1F5F9)),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    today.isClockedIn
                                        ? Icons.timer
                                        : (today.isClockedOut ? Icons.check_circle_outline : Icons.access_time),
                                    color: today.isClockedIn
                                        ? AppColors.emerald
                                        : (today.isClockedOut ? AppColors.primary : AppColors.textSecondary),
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
                                          : (today.isClockedOut ? 'Clocked Out for Today' : 'Not Clocked In Yet'),
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 2),
                                    if (today.attendance?.clockInAt != null)
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

                            // Live Timer Display
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
                                if (today.isApplicable && !today.isClockedIn && !today.isClockedOut)
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

            // Monthly Summary Cards
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
                tabs: [
                  const Tab(text: 'My Attendance Logs'),
                  if (user?.canManageAttendance == true)
                    const Tab(text: 'Team Records')
                  else
                    const Tab(text: 'Calendar View'),
                  const Tab(text: 'Regularization Requests'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab Content
            SizedBox(
              height: 480,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _MyAttendanceList(),
                  if (user?.canManageAttendance == true)
                    _TeamAttendanceList()
                  else
                    _MyAttendanceList(),
                  _RegularizationsList(canManage: user?.canManageAttendance ?? false),
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
        final cardWidth = constraints.maxWidth >= 700 ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2;

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
                // Use office coordinate as fallback if browser/device GPS permission not requested
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
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: dateController,
                  decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: inTimeController,
                        decoration: const InputDecoration(labelText: 'In Time (HH:MM)', border: OutlineInputBorder()),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: outTimeController,
                        decoration: const InputDecoration(labelText: 'Out Time (HH:MM)', border: OutlineInputBorder()),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: reasonController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Reason for Regularization', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.isEmpty ? 'Please enter a reason' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              try {
                final d = dateController.text.trim();
                await ref.read(attendanceRepositoryProvider).requestRegularization(
                  date: d,
                  requestedClockIn: '$d ${inTimeController.text.trim()}:00',
                  requestedClockOut: '$d ${outTimeController.text.trim()}:00',
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
                Text(title, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
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
                title: Row(
                  children: [
                    Text(r.date, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    _statusBadge(r.status),
                    if (r.isFlagged) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.roseContainer, borderRadius: BorderRadius.circular(4)),
                        child: const Text('FLAGGED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.rose)),
                      ),
                    ],
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

class _TeamAttendanceList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamAttendanceRecordsProvider);

    return teamAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return const Center(child: Text('No team records found.'));
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
                title: Row(
                  children: [
                    Text(r.userName ?? 'Employee', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    if (r.employeeCode != null)
                      Text('(${r.employeeCode})', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
                subtitle: Text(
                  'Date: ${r.date} • In: ${r.clockInAt != null ? r.clockInAt!.substring(11, 16) : "--"} • Out: ${r.clockOutAt != null ? r.clockOutAt!.substring(11, 16) : "--"}'
                  '${r.flaggedReason != null ? " • ${r.flaggedReason}" : ""}',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                trailing: Text(
                  r.status.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: r.isFlagged ? AppColors.rose : (r.status == 'present' ? AppColors.emerald : AppColors.amber),
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading team records: $e')),
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(r.date, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              _statusPill(r.status),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Requested: ${r.requestedClockIn.substring(11, 16)} to ${r.requestedClockOut.substring(11, 16)}', style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                          const SizedBox(height: 2),
                          Text('Reason: ${r.reason}', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    if (canManage && r.status == 'pending') ...[
                      IconButton(
                        tooltip: 'Approve',
                        icon: const Icon(Icons.check_circle, color: AppColors.emerald),
                        onPressed: () async {
                          await ref.read(attendanceRepositoryProvider).approveRegularization(r.id);
                          ref.invalidate(regularizationsProvider);
                          ref.invalidate(myAttendanceRecordsProvider);
                          ref.read(attendanceTodayProvider.notifier).refresh();
                        },
                      ),
                      IconButton(
                        tooltip: 'Reject',
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
