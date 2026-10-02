import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/application/auth_controller.dart';
import '../application/leave_controller.dart';
import '../data/leave_models.dart';
import '../data/leave_repository.dart';

class LeavesPage extends ConsumerStatefulWidget {
  const LeavesPage({super.key});

  @override
  ConsumerState<LeavesPage> createState() => _LeavesPageState();
}

class _LeavesPageState extends ConsumerState<LeavesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                  'Leave management is not applicable for Super Admin accounts.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final balancesAsync = ref.watch(leaveBalancesProvider);
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    final canApprove = user?.canApproveLeave ?? false;

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
                        'Leave Management',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Track leave quotas, apply for time off, and manage team approvals.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Apply for Leave', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => _openApplyLeaveDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Balances Row
            balancesAsync.when(
              data: (balances) => _buildBalanceCards(balances),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error loading balances: $e'),
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
                  const Tab(text: 'My Leave Applications'),
                  Tab(text: canApprove ? 'Team Approvals' : 'Holiday Summary'),
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
                  _MyLeavesList(),
                  if (canApprove)
                    _ApprovalLeavesList()
                  else
                    const Center(child: Text('Visit Holidays page for the annual holiday schedule.')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCards(List<LeaveBalance> balances) {
    if (balances.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth >= 700 ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: balances.map((b) {
            Color accentColor;
            Color bg;
            switch (b.code) {
              case 'CL':
                accentColor = AppColors.primary;
                bg = AppColors.primaryContainer;
                break;
              case 'SL':
                accentColor = AppColors.emerald;
                bg = AppColors.emeraldContainer;
                break;
              case 'PL':
                accentColor = AppColors.purple;
                bg = AppColors.purpleContainer;
                break;
              default:
                accentColor = AppColors.amber;
                bg = AppColors.amberContainer;
            }

            return Container(
              width: cardWidth,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          b.code,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: accentColor),
                        ),
                      ),
                      Text(
                        'Total: ${b.totalDays.toInt()}d',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    b.name,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        b.remainingDays.toStringAsFixed(b.remainingDays.truncateToDouble() == b.remainingDays ? 0 : 1),
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: accentColor),
                      ),
                      const SizedBox(width: 4),
                      Text('days left', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: b.totalDays > 0 ? (b.usedDays / b.totalDays).clamp(0.0, 1.0) : 0.0,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Used: ${b.usedDays.toInt()}d • Pending: ${b.pendingDays.toInt()}d',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _openApplyLeaveDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final balances = ref.read(leaveBalancesProvider).value ?? [];
    if (balances.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No leave types available.')),
      );
      return;
    }

    int selectedTypeId = balances.first.leaveTypeId;
    final startDateController = TextEditingController(text: DateTime.now().add(const Duration(days: 1)).toIso8601String().substring(0, 10));
    final endDateController = TextEditingController(text: DateTime.now().add(const Duration(days: 1)).toIso8601String().substring(0, 10));
    final reasonController = TextEditingController();
    bool isHalfDay = false;
    String halfDayType = 'first_half';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Apply for Leave'),
          content: SizedBox(
            width: 440,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Leave Type Dropdown
                    DropdownButtonFormField<int>(
                      initialValue: selectedTypeId,
                      decoration: const InputDecoration(labelText: 'Leave Type', border: OutlineInputBorder()),
                      items: balances.map((b) {
                        return DropdownMenuItem<int>(
                          value: b.leaveTypeId,
                          child: Text('${b.name} (${b.remainingDays} days remaining)'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedTypeId = val);
                      },
                    ),
                    const SizedBox(height: 14),

                    // Date Pickers
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: startDateController,
                            decoration: const InputDecoration(labelText: 'Start Date (YYYY-MM-DD)', border: OutlineInputBorder()),
                            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: endDateController,
                            decoration: const InputDecoration(labelText: 'End Date (YYYY-MM-DD)', border: OutlineInputBorder()),
                            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Half-day checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: isHalfDay,
                          onChanged: (val) => setDialogState(() => isHalfDay = val ?? false),
                        ),
                        const Text('Half-Day Leave'),
                        if (isHalfDay) ...[
                          const SizedBox(width: 12),
                          DropdownButton<String>(
                            value: halfDayType,
                            items: const [
                              DropdownMenuItem(value: 'first_half', child: Text('First Half')),
                              DropdownMenuItem(value: 'second_half', child: Text('Second Half')),
                            ],
                            onChanged: (val) {
                              if (val != null) setDialogState(() => halfDayType = val);
                            },
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: reasonController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Reason for Leave',
                        hintText: 'Provide details for manager review...',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Please enter a reason' : null,
                    ),
                  ],
                ),
              ),
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
                  await ref.read(leaveRepositoryProvider).applyLeave(
                    leaveTypeId: selectedTypeId,
                    startDate: startDateController.text.trim(),
                    endDate: endDateController.text.trim(),
                    isHalfDay: isHalfDay,
                    halfDayType: isHalfDay ? halfDayType : null,
                    reason: reasonController.text.trim(),
                  );
                  ref.invalidate(leaveBalancesProvider);
                  ref.invalidate(myLeaveRequestsProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Leave applied successfully!')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Application failed: $e'), backgroundColor: AppColors.rose),
                    );
                  }
                }
              },
              child: const Text('Submit Application'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyLeavesList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leavesAsync = ref.watch(myLeaveRequestsProvider);

    return leavesAsync.when(
      data: (leaves) {
        if (leaves.isEmpty) {
          return const Center(child: Text('No leave applications yet. Click "Apply for Leave" above.'));
        }

        return ListView.separated(
          itemCount: leaves.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, idx) {
            final l = leaves[idx];
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: AppColors.border),
              ),
              child: ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      l.leaveTypeCode,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                    ),
                  ),
                ),
                title: Row(
                  children: [
                    Text('${l.startDate} ${l.startDate != l.endDate ? "to ${l.endDate}" : ""}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    _statusBadge(l.status),
                  ],
                ),
                subtitle: Text(
                  '${l.daysCount} day(s) • ${l.leaveTypeName} • Reason: ${l.reason}'
                  '${l.actionRemarks != null ? " • Remarks: ${l.actionRemarks}" : ""}',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                trailing: l.status == 'pending'
                    ? TextButton(
                        onPressed: () async {
                          await ref.read(leaveRepositoryProvider).cancelRequest(l.id);
                          ref.invalidate(leaveBalancesProvider);
                          ref.invalidate(myLeaveRequestsProvider);
                        },
                        child: const Text('Cancel', style: TextStyle(color: AppColors.rose)),
                      )
                    : null,
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _statusBadge(String status) {
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
      case 'cancelled':
        bg = const Color(0xFFF1F5F9);
        fg = AppColors.textSecondary;
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

class _ApprovalLeavesList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final listAsync = ref.watch(approvalLeaveRequestsProvider);

    return listAsync.when(
      data: (leaves) {
        // Filter requests assigned to current user, or all if Super Admin
        final assignedLeaves = leaves.where((l) {
          if (user == null) return false;
          if (user.isSuperAdmin) return true;
          // Show if assigned to me as approver, or if unassigned and I have approval permission
          return l.approverId == user.id || (l.approverId == null && user.canApproveLeave);
        }).toList();

        if (assignedLeaves.isEmpty) {
          return const Center(child: Text('No leave requests assigned to you for approval.'));
        }

        return ListView.separated(
          itemCount: assignedLeaves.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, idx) {
            final l = assignedLeaves[idx];
            final isOwnRequest = user != null && l.userId == user.id;

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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(l.userName ?? 'Employee', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Text('${l.daysCount}d (${l.leaveTypeCode})',
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                              if (l.finalApprover) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: const Color(0xFFBFDBFE)),
                                  ),
                                  child: const Text('Final Approval', style: TextStyle(fontSize: 9, color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('${l.startDate} to ${l.endDate} • ${l.reason}', style: TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                    if (l.status == 'pending') ...[
                      if (isOwnRequest)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            'Self-Approval Blocked',
                            style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                          ),
                        )
                      else ...[
                        IconButton(
                          tooltip: 'Approve',
                          icon: const Icon(Icons.check_circle, color: AppColors.emerald),
                          onPressed: () async {
                            await ref.read(leaveRepositoryProvider).approveRequest(l.id, remarks: 'Approved');
                            ref.invalidate(approvalLeaveRequestsProvider);
                            ref.invalidate(leaveBalancesProvider);
                          },
                        ),
                        IconButton(
                          tooltip: 'Reject',
                          icon: const Icon(Icons.cancel, color: AppColors.rose),
                          onPressed: () async {
                            await ref.read(leaveRepositoryProvider).rejectRequest(l.id, remarks: 'Rejected');
                            ref.invalidate(approvalLeaveRequestsProvider);
                            ref.invalidate(leaveBalancesProvider);
                          },
                        ),
                      ],
                    ] else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: l.status == 'approved' ? AppColors.emeraldContainer : AppColors.roseContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          l.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: l.status == 'approved' ? AppColors.emerald : AppColors.rose,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading approvals: $e')),
    );
  }
}
