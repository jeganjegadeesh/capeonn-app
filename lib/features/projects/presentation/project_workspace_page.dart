import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/application/auth_controller.dart';
import '../application/projects_controller.dart';
import '../data/project_models.dart';
import 'add_project_member_dialog.dart';
import 'assign_lead_dialog.dart';
import 'project_form_dialog.dart';

class ProjectWorkspacePage extends ConsumerStatefulWidget {
  const ProjectWorkspacePage({super.key, required this.projectId});

  final int projectId;

  @override
  ConsumerState<ProjectWorkspacePage> createState() => _ProjectWorkspacePageState();
}

class _ProjectWorkspacePageState extends ConsumerState<ProjectWorkspacePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(projectDetailProvider(widget.projectId));
    final currentUser = ref.watch(authControllerProvider).value;
    final canManage = currentUser?.canManageProjects ?? false;
    final canAssign = currentUser?.canAssignProjects ?? false;
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: detailAsync.when(
        data: (detail) {
          final p = detail.project;
          final isLocked = !p.acceptsWork;
          final isTeamLead = p.teamLeadId != null && p.teamLeadId == currentUser?.id;
          final canManageTeam = (currentUser?.canManageProjectTeam ?? false) && (isTeamLead || canManage);
          final canRequestCompletion = p.status == 'active' &&
              p.completionRequestedAt == null &&
              (canManage || isTeamLead);

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      isDesktop ? 28 : 16,
                      isDesktop ? 20 : 12,
                      isDesktop ? 28 : 16,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back navigation row
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              tooltip: 'Back to Projects',
                              onPressed: () => context.go('/projects'),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => context.go('/projects'),
                              child: const Text(
                                'Projects',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                p.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Project Header Banner
                        _buildWorkspaceHeader(
                          context,
                          p,
                          canManage,
                          canAssign,
                          isTeamLead,
                          canRequestCompletion,
                          isLocked,
                          detail.members,
                          isDesktop,
                        ),
                        const SizedBox(height: 16),

                        // Tab Bar (6 Tabs)
                        Container(
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: AppColors.border)),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            isScrollable: !isDesktop,
                            tabAlignment: !isDesktop ? TabAlignment.start : TabAlignment.fill,
                            indicatorColor: AppColors.primary,
                            indicatorWeight: 3,
                            labelColor: AppColors.primary,
                            unselectedLabelColor: AppColors.textSecondary,
                            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            tabs: [
                              const Tab(
                                icon: Icon(Icons.dashboard_outlined, size: 18),
                                text: 'Overview',
                              ),
                              Tab(
                                icon: const Icon(Icons.group_outlined, size: 18),
                                text: 'Team Members (${p.totalTeamCount > 0 ? p.totalTeamCount : detail.members.length})',
                              ),
                              Tab(
                                icon: const Icon(Icons.history_outlined, size: 18),
                                text: 'Activity History (${detail.activities.length})',
                              ),
                              const Tab(
                                icon: Icon(Icons.task_alt, size: 18),
                                text: 'Tasks & Milestones',
                              ),
                              const Tab(
                                icon: Icon(Icons.folder_open_outlined, size: 18),
                                text: 'Files & Attachments',
                              ),
                              const Tab(
                                icon: Icon(Icons.forum_outlined, size: 18),
                                text: 'Project Discussions',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                // 1. Overview Tab
                _OverviewTab(
                  detail: detail,
                  canManage: canManage,
                  canAssign: canAssign,
                  isLocked: isLocked,
                  isDesktop: isDesktop,
                ),

                // 2. Team Members Tab
                _TeamMembersTab(
                  project: p,
                  members: detail.members,
                  canManageTeam: canManageTeam,
                  isLocked: isLocked,
                ),

                // 3. Activity History Tab
                _ActivityHistoryTab(activities: detail.activities),

                // 4. Tasks & Milestones Preview Tab (Phase 5)
                _TasksPreviewTab(project: p),

                // 5. Files & Attachments Preview Tab (Phase 6)
                _FilesPlaceholderTab(project: p),

                // 6. Project Discussions Preview Tab (Phase 6)
                _DiscussionsPlaceholderTab(project: p),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.rose),
              const SizedBox(height: 12),
              Text(
                'Failed to load project workspace',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(err.toString(), style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(projectDetailProvider(widget.projectId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkspaceHeader(
    BuildContext context,
    ProjectItem p,
    bool canManage,
    bool canAssign,
    bool isTeamLead,
    bool canRequestCompletion,
    bool isLocked,
    List<ProjectMemberItem> members,
    bool isDesktop,
  ) {
    final codeBox = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        p.code ?? 'PRJ',
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          letterSpacing: 0.5,
        ),
      ),
    );

    final titleColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          p.name,
          style: TextStyle(
            fontSize: isDesktop ? 22 : 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 14,
          runSpacing: 4,
          children: [
            if (p.departmentName != null) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.apartment_outlined, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    p.departmentName!,
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
            if (p.clientName != null) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.business_center_outlined, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    p.clientName!,
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
            if (p.managerName != null) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.manage_accounts_outlined, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Manager: ${p.managerName}',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ],
        ),
      ],
    );

    final headerActionButtons = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Change Status Button
        OutlinedButton.icon(
          onPressed: () => _showChangeStatusDialog(context, p, canManage),
          icon: const Icon(Icons.swap_horiz, size: 16),
          label: const Text('Change Status'),
        ),

        // Request Completion Button
        if (canRequestCompletion) ...[
          ElevatedButton.icon(
            onPressed: () => _showRequestCompletionDialog(context, p),
            icon: const Icon(Icons.task_alt, size: 16),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.emerald),
            label: const Text('Request Completion'),
          ),
        ],

        // Edit Project Button
        if (canManage) ...[
          OutlinedButton.icon(
            onPressed: () async {
              await showDialog<bool>(
                context: context,
                builder: (_) => ProjectFormDialog(project: p),
              );
            },
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Edit Project'),
          ),
        ],

        // Add Member Button (locked on inactive/closed statuses)
        if (canAssign && !isLocked) ...[
          ElevatedButton.icon(
            onPressed: () async {
              await showDialog<bool>(
                context: context,
                builder: (_) => AddProjectMemberDialog(
                  projectId: p.id,
                  existingMemberUserIds: members.map((m) => m.userId).toSet(),
                ),
              );
            },
            icon: const Icon(Icons.person_add_outlined, size: 16),
            label: const Text('Add Member'),
          ),
        ],
      ],
    );

    return Container(
      padding: EdgeInsets.all(isDesktop ? 20 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                codeBox,
                const SizedBox(width: 14),
                Expanded(child: titleColumn),
                const SizedBox(width: 14),
                headerActionButtons,
              ],
            )
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                codeBox,
                const SizedBox(width: 12),
                Expanded(child: titleColumn),
              ],
            ),
            const SizedBox(height: 12),
            headerActionButtons,
          ],

          // Completion Requested Banner
          if (p.completionRequestedAt != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
              ),
              child: isDesktop
                  ? Row(
                      children: [
                        const Icon(Icons.hourglass_top_rounded, color: AppColors.amber, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Completion Requested',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                p.completionRequestNotes != null && p.completionRequestNotes!.isNotEmpty
                                    ? 'Notes: "${p.completionRequestNotes}"'
                                    : 'Team Lead requested project completion review.',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        if (canManage) ...[
                          OutlinedButton(
                            onPressed: () => _showRejectCompletionDialog(context, p),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.rose,
                              side: const BorderSide(color: AppColors.rose),
                            ),
                            child: const Text('Reject'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Approve Project Completion?'),
                                  content: Text('Mark "${p.name}" as completed?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.emerald),
                                      child: const Text('Approve & Complete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await ref.read(projectsControllerProvider).approveCompletion(p.id);
                              }
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.emerald),
                            child: const Text('Approve Completion'),
                          ),
                        ],
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.hourglass_top_rounded, color: AppColors.amber, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Completion Requested',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    p.completionRequestNotes != null && p.completionRequestNotes!.isNotEmpty
                                        ? 'Notes: "${p.completionRequestNotes}"'
                                        : 'Team Lead requested project completion review.',
                                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (canManage) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _showRejectCompletionDialog(context, p),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.rose,
                                    side: const BorderSide(color: AppColors.rose),
                                  ),
                                  child: const Text('Reject'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Approve Project Completion?'),
                                        content: Text('Mark "${p.name}" as completed?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                          ElevatedButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.emerald),
                                            child: const Text('Approve & Complete'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await ref.read(projectsControllerProvider).approveCompletion(p.id);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.emerald),
                                  child: const Text('Approve'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
            ),
          ],

          const SizedBox(height: 16),

          // Status, Health, Priority, Deadline & Progress Placeholder Row
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: p.statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  p.statusDisplay,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: p.statusColor,
                  ),
                ),
              ),

              // Health Label Badge
              if (p.healthLabel.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: p.healthLabelColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.monitor_heart_outlined, size: 13, color: p.healthLabelColor),
                      const SizedBox(width: 4),
                      Text(
                        p.healthLabelDisplay,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: p.healthLabelColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Priority Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: p.priorityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${p.priorityDisplay} Priority',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: p.priorityColor,
                  ),
                ),
              ),

              // Deadline Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: p.isOverdue
                      ? AppColors.rose.withValues(alpha: 0.12)
                      : AppColors.surfaceHover,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      p.isOverdue ? Icons.error_outline : Icons.calendar_today_outlined,
                      size: 13,
                      color: p.isOverdue ? AppColors.rose : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      p.deadlineDisplay,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: p.isOverdue ? AppColors.rose : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Phase 5 Progress Metrics Placeholder Container
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHover,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      isDesktop
                          ? 'Task progress metrics will be available in Phase 5'
                          : 'Task metrics in Phase 5',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showChangeStatusDialog(BuildContext context, ProjectItem p, bool canManage) async {
    final Map<String, List<String>> allowedTransitions = {
      'planned': ['active', 'cancelled'],
      'active': canManage ? ['on_hold', 'completed', 'cancelled'] : ['on_hold', 'cancelled'],
      'on_hold': ['active', 'cancelled'],
      'completed': canManage ? ['archived', 'active'] : ['active'],
      'archived': ['active'],
      'cancelled': ['active'],
    };

    final nextOptions = allowedTransitions[p.status] ?? [];
    if (nextOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No further status transitions available for "${p.statusDisplay}".')),
      );
      return;
    }

    String selected = nextOptions.first;
    final reasonCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            final isReasonRequired = selected == 'on_hold' ||
                selected == 'cancelled' ||
                (const ['completed', 'archived', 'cancelled'].contains(p.status) && selected == 'active');

            return AlertDialog(
              title: Text('Change Status: ${p.name}'),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current Status: ${p.statusDisplay}',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 12),
                    const Text('New Status:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selected,
                      decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                      items: nextOptions.map((st) {
                        String label = st.replaceAll('_', ' ').toUpperCase();
                        if (st == 'active' && const ['completed', 'archived', 'cancelled'].contains(p.status)) {
                          label = 'REOPEN (ACTIVE)';
                        }
                        return DropdownMenuItem(value: st, child: Text(label));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => selected = val);
                      },
                    ),
                    const SizedBox(height: 14),
                    Text(
                      isReasonRequired ? 'Reason for Change (Required):' : 'Reason / Notes (Optional):',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isReasonRequired ? AppColors.rose : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: reasonCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: isReasonRequired ? 'Explain why status is changing...' : 'Optional notes...',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    final reason = reasonCtrl.text.trim();
                    if (isReasonRequired && reason.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('A reason is required for this status change.')),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    try {
                      await ref.read(projectsControllerProvider).updateStatus(
                            p.id,
                            status: selected,
                            reason: reason.isNotEmpty ? reason : null,
                          );
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to update status: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Update Status'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showRequestCompletionDialog(BuildContext context, ProjectItem p) async {
    final notesCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request Project Completion'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Submit "${p.name}" to project management for final sign-off and completion review.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              const Text('Completion Notes / Handover Details:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Summary of deliverables, links to reports, or handover notes...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(projectsControllerProvider).requestCompletion(
                      p.id,
                      notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                    );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to request completion: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.emerald),
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRejectCompletionDialog(BuildContext context, ProjectItem p) async {
    final reasonCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Completion Request'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Explain what deliverables or revisions are required before this project can be marked completed.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              const Text('Rejection Reason (Required):',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.rose)),
              const SizedBox(height: 6),
              TextField(
                controller: reasonCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Pending QA sign-off on release artifacts...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonCtrl.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Please provide a rejection reason.')),
                );
                return;
              }
              Navigator.pop(ctx);
              try {
                await ref.read(projectsControllerProvider).rejectCompletion(p.id, reason: reason);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to reject completion: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.rose),
            child: const Text('Reject Request'),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 1. Overview Tab
// -----------------------------------------------------------------------------
class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.detail,
    required this.canManage,
    required this.canAssign,
    required this.isLocked,
    required this.isDesktop,
  });

  final ProjectDetail detail;
  final bool canManage;
  final bool canAssign;
  final bool isLocked;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final p = detail.project;

    final leftColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
                    // Description Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.description_outlined, size: 20, color: AppColors.primary),
                              const SizedBox(width: 10),
                              Text(
                                'Project Scope & Objectives',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            p.description != null && p.description!.isNotEmpty
                                ? p.description!
                                : 'No description provided for this project.',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: p.description != null ? AppColors.textPrimary : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Key Project Details Grid
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Project Specifications',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 24,
                            runSpacing: 18,
                            children: [
                              _specItem('Start Date', p.startDate ?? 'Not set', Icons.calendar_today_outlined),
                              _specItem('Deadline', p.deadline ?? 'Not set', Icons.event_available_outlined),
                              _specItem('Estimated Time',
                                  p.estimatedHours != null ? '${p.estimatedHours} hrs' : 'Not set', Icons.hourglass_bottom),
                              _specItem('Budget', p.budget != null ? '\$${p.budget!.toStringAsFixed(2)}' : 'Not set',
                                  Icons.attach_money),
                              _specItem('Department', p.departmentName ?? 'Unassigned', Icons.apartment_outlined),
                              _specItem('Manager', p.managerName ?? 'Unassigned', Icons.manage_accounts_outlined),
                              _specItem('Created By', p.createdByName ?? 'System', Icons.person_outline),
                            ],
                          ),
                        ],
                      ),
                    ),
      ],
    );

    final rightColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
                    // Team Lead Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person_pin_outlined, size: 20, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Project Team Lead',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              if (canAssign && !isLocked) ...[
                                TextButton(
                                  onPressed: () async {
                                    await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AssignLeadDialog(
                                        projectId: p.id,
                                        currentLeadId: p.teamLeadId,
                                      ),
                                    );
                                  },
                                  child: const Text('Change Lead', style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (p.teamLeadName != null) ...[
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                  child: Text(
                                    p.teamLeadName![0].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.teamLeadName!,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      if (p.teamLeadEmployeeCode != null) ...[
                                        Text(
                                          p.teamLeadEmployeeCode!,
                                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                        ),
                                      ],
                                      if (p.teamLeadEmail != null) ...[
                                        Text(
                                          p.teamLeadEmail!,
                                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceHover,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, size: 20, color: AppColors.textMuted),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'No Team Lead assigned yet. Assign a team lead to supervise deliverables.',
                                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Quick Team Summary Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Assigned Members (${detail.members.length})',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Icon(Icons.group_outlined, size: 18, color: AppColors.textSecondary),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (detail.members.isEmpty) ...[
                            Text(
                              'No team members assigned yet.',
                              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                            ),
                          ] else ...[
                            ...detail.members.take(4).map((m) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: AppColors.primaryContainer,
                                      child: Text(
                                        m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                                        style: const TextStyle(
                                            fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            m.name,
                                            style: TextStyle(
                                                fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                          ),
                                          Text(
                                            m.projectRole,
                                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                  ],
                );

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 28 : 16),
      child: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: leftColumn),
                const SizedBox(width: 20),
                Expanded(flex: 2, child: rightColumn),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leftColumn,
                const SizedBox(height: 18),
                rightColumn,
              ],
            ),
    );
  }

  Widget _specItem(String label, String value, IconData icon) {
    return SizedBox(
      width: isDesktop ? 170 : 135,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 2. Team Members Tab (Project Team Management)
// -----------------------------------------------------------------------------
class _TeamMembersTab extends ConsumerWidget {
  const _TeamMembersTab({
    required this.project,
    required this.members,
    required this.canManageTeam,
    required this.isLocked,
  });

  final ProjectItem project;
  final List<ProjectMemberItem> members;
  final bool canManageTeam;
  final bool isLocked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Locked Status Notice
          if (isLocked) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceHover,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_outline, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Project is ${project.statusDisplay}. Member modifications are locked and new work cannot be accepted.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Assigned Team Lead Banner/Card
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    project.teamLeadName != null && project.teamLeadName!.isNotEmpty
                        ? project.teamLeadName![0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            project.teamLeadName ?? 'No Team Lead Assigned',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Team Lead',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        project.teamLeadEmail ?? 'Assign a Team Lead to split and assign tasks (Phase 5)',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Text(
                'Project Team Roster (${members.length})',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              if (canManageTeam && !isLocked) ...[
                ElevatedButton.icon(
                  onPressed: () => showDialog<bool>(
                    context: context,
                    builder: (_) => AddProjectMemberDialog(
                      projectId: project.id,
                      existingMemberUserIds: members.map((m) => m.userId).toSet(),
                    ),
                  ),
                  icon: const Icon(Icons.person_add, size: 16),
                  label: const Text('Add Member'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          if (members.isEmpty) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people_outline, size: 48, color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      'No members assigned to this project',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Assign developers, testers, and designers to collaborate on this project.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Member Cards Grid
            LayoutBuilder(builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 700;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: members.map((m) {
                  return SizedBox(
                    width: isWide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.primaryContainer,
                            child: Text(
                              m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                              style:
                                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      m.name,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    // Project Role badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        m.projectRole,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${m.designationName ?? 'Staff'} • ${m.departmentName ?? ''}',
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                                Text(
                                  m.email,
                                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),

                          // Action menu (Update role, Remove) - only when not locked
                          if (canManageTeam && !isLocked) ...[
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, size: 20),
                              onSelected: (action) async {
                                if (action == 'role') {
                                  final newRole = await _showEditRoleDialog(context, m.projectRole);
                                  if (newRole != null && newRole.isNotEmpty) {
                                    await ref
                                        .read(projectsControllerProvider)
                                        .updateMemberRole(project.id, m.userId, newRole);
                                  }
                                } else if (action == 'remove') {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Remove Team Member?'),
                                      content: Text('Remove ${m.name} from this project?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(ctx, true),
                                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.rose),
                                          child: const Text('Remove'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await ref
                                        .read(projectsControllerProvider)
                                        .removeMember(project.id, m.userId);
                                  }
                                }
                              },
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(value: 'role', child: Text('Change Project Role')),
                                const PopupMenuItem(
                                  value: 'remove',
                                  child: Text('Remove from Project', style: TextStyle(color: AppColors.rose)),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            }),
          ],
        ],
      ),
    );
  }

  Future<String?> _showEditRoleDialog(BuildContext context, String currentRole) {
    final ctrl = TextEditingController(text: currentRole);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Project Role'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Project Role', hintText: 'e.g. Lead Developer'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Save')),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 3. Activity History Tab (Append-Only Audit Trail)
// -----------------------------------------------------------------------------
class _ActivityHistoryTab extends StatelessWidget {
  const _ActivityHistoryTab({required this.activities});

  final List<ProjectActivityItem> activities;

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text(
                'No activity records yet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                'Project events, assignments and status changes will appear here.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: activities.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final act = activities[index];

        IconData icon = Icons.info_outline;
        Color color = AppColors.primary;

        switch (act.action) {
          case 'created':
            icon = Icons.add_circle_outline;
            color = AppColors.emerald;
            break;
          case 'lead_assigned':
            icon = Icons.person_pin;
            color = AppColors.primary;
            break;
          case 'lead_removed':
            icon = Icons.person_remove;
            color = AppColors.rose;
            break;
          case 'member_added':
            icon = Icons.person_add;
            color = AppColors.secondary;
            break;
          case 'member_removed':
            icon = Icons.group_remove;
            color = AppColors.rose;
            break;
          case 'status_changed':
            icon = Icons.sync_alt;
            color = AppColors.amber;
            break;
          case 'completion_requested':
            icon = Icons.hourglass_top_rounded;
            color = AppColors.amber;
            break;
          case 'completion_approved':
            icon = Icons.check_circle_outline;
            color = AppColors.emerald;
            break;
          case 'completion_rejected':
            icon = Icons.cancel_outlined;
            color = AppColors.rose;
            break;
          case 'priority_changed':
            icon = Icons.flag;
            color = AppColors.amber;
            break;
          case 'deleted':
            icon = Icons.delete_outline;
            color = AppColors.rose;
            break;
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      act.description,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (act.field != null && (act.oldValue != null || act.newValue != null)) ...[
                      const SizedBox(height: 3),
                      Text(
                        'Changed ${act.field}: "${act.oldValue ?? 'None'}" ➔ "${act.newValue ?? 'None'}"',
                        style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                      ),
                    ],
                    if (act.reason != null && act.reason!.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHover,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Reason: ${act.reason}',
                          style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (act.userName != null) ...[
                          Text(
                            'by ${act.userName}',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 8),
                          Text('•', style: TextStyle(color: AppColors.textMuted)),
                          const SizedBox(width: 8),
                        ],
                        if (act.createdAt != null) ...[
                          Text(
                            _formatDate(act.createdAt!),
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoString;
    }
  }
}

// -----------------------------------------------------------------------------
// 4. Tasks & Milestones Preview Tab (Phase 5 Teaser)
// -----------------------------------------------------------------------------
class _TasksPreviewTab extends StatelessWidget {
  const _TasksPreviewTab({required this.project});

  final ProjectItem project;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_outline, size: 44, color: AppColors.primary),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Phase 5: Task Management & Time Tracking',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Project "${project.name}" is fully initialized! Team Leads can break down this project into tasks, subtasks, set priorities, and track start/stop timers in the upcoming Phase 5 sprint.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHover,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 14,
                      alignment: WrapAlignment.spaceEvenly,
                      children: [
                        _featurePill('Create Tasks & Subtasks', Icons.checklist),
                        _featurePill('Assign to Members', Icons.person_search),
                        _featurePill('Time Tracking Timers', Icons.timer_outlined),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _featurePill(String title, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(height: 6),
        Text(
          title,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// 5. Files & Attachments Preview Tab (Phase 6 Teaser)
// -----------------------------------------------------------------------------
class _FilesPlaceholderTab extends StatelessWidget {
  const _FilesPlaceholderTab({required this.project});

  final ProjectItem project;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.folder_open_outlined, size: 44, color: AppColors.primary),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Phase 6: Project Files & Document Storage',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Upload project briefs, design assets, client contracts, and export reports for "${project.name}". File attachment storage and version control will arrive in Phase 6.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHover,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 14,
                      alignment: WrapAlignment.spaceEvenly,
                      children: [
                        _featurePill('File Versioning', Icons.history_toggle_off),
                        _featurePill('Secure Storage', Icons.cloud_upload_outlined),
                        _featurePill('Role Access', Icons.verified_user_outlined),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _featurePill(String title, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(height: 6),
        Text(
          title,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// 6. Project Discussions Preview Tab (Phase 6 Teaser)
// -----------------------------------------------------------------------------
class _DiscussionsPlaceholderTab extends StatelessWidget {
  const _DiscussionsPlaceholderTab({required this.project});

  final ProjectItem project;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.forum_outlined, size: 44, color: AppColors.primary),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Phase 6: Project Discussions & Team Chat',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Collaborate in real-time with team threads, mention teammates (@user), and pin critical updates for "${project.name}". Discussion channels will launch in Phase 6.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHover,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 14,
                      alignment: WrapAlignment.spaceEvenly,
                      children: [
                        _featurePill('Threaded Topics', Icons.chat_bubble_outline),
                        _featurePill('Mentions & Alerts', Icons.alternate_email),
                        _featurePill('Pinned Notices', Icons.push_pin_outlined),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _featurePill(String title, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(height: 6),
        Text(
          title,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}
