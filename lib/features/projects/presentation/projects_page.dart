import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../../auth/application/auth_controller.dart';
import '../../organization/application/organization_controller.dart';
import '../application/projects_controller.dart';
import '../data/project_models.dart';
import 'project_form_dialog.dart';

class ProjectsPage extends ConsumerStatefulWidget {
  const ProjectsPage({super.key});

  @override
  ConsumerState<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends ConsumerState<ProjectsPage> {
  final _searchCtrl = TextEditingController();
  bool _isGridView = true;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    ref.read(projectsFilterProvider.notifier).update((cur) => cur.copyWith(
          search: val,
          page: 1,
        ));
  }

  void _onStatusFilter(String? status) {
    ref.read(projectsFilterProvider.notifier).update((cur) => cur.copyWith(
          status: () => status,
          isOverdue: status == 'overdue',
          includeArchived: status == 'archived',
          page: 1,
        ));
  }

  void _onPriorityFilter(String? priority) {
    ref.read(projectsFilterProvider.notifier).update((cur) => cur.copyWith(
          priority: () => priority,
          page: 1,
        ));
  }

  void _toggleMyProjects(bool val) {
    ref.read(projectsFilterProvider.notifier).update((cur) => cur.copyWith(
          myProjects: val,
          page: 1,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;
    final canManage = user?.canManageProjects ?? false;
    final filter = ref.watch(projectsFilterProvider);
    final projectsAsync = ref.watch(projectsListProvider);
    final dashboardAsync = ref.watch(projectDashboardProvider);
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Top Header & Dashboard Metrics
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isDesktop ? 28 : 16,
                isDesktop ? 24 : 16,
                isDesktop ? 28 : 16,
                12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Title & Primary Actions
                  if (isDesktop)
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Projects',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Track client projects, deadlines, workloads and team assignments',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // View toggle
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.grid_view_rounded,
                                  size: 20,
                                  color: _isGridView ? AppColors.primary : AppColors.textMuted,
                                ),
                                tooltip: 'Grid view',
                                onPressed: () => setState(() => _isGridView = true),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.view_agenda_outlined,
                                  size: 20,
                                  color: !_isGridView ? AppColors.primary : AppColors.textMuted,
                                ),
                                tooltip: 'List view',
                                onPressed: () => setState(() => _isGridView = false),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Refresh button
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Refresh',
                          onPressed: () {
                            ref.invalidate(projectsListProvider);
                            ref.invalidate(projectDashboardProvider);
                          },
                        ),
                        const SizedBox(width: 8),
                        // Create Project Button
                        if (canManage) ...[
                          ElevatedButton.icon(
                            onPressed: () async {
                              final res = await showDialog<bool>(
                                context: context,
                                builder: (_) => const ProjectFormDialog(),
                              );
                              if (res == true) {
                                ref.invalidate(projectsListProvider);
                                ref.invalidate(projectDashboardProvider);
                              }
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('New Project'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Projects',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Track client projects and team workloads',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              tooltip: 'Refresh',
                              onPressed: () {
                                ref.invalidate(projectsListProvider);
                                ref.invalidate(projectDashboardProvider);
                              },
                            ),
                          ],
                        ),
                        if (canManage) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final res = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => const ProjectFormDialog(),
                                );
                                if (res == true) {
                                  ref.invalidate(projectsListProvider);
                                  ref.invalidate(projectDashboardProvider);
                                }
                              },
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('New Project'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  const SizedBox(height: 20),

                  // KPI Cards Bar (from dashboard API)
                  dashboardAsync.when(
                    data: (stats) => _buildKpiCards(context, stats, filter),
                    loading: () => const LinearProgressIndicator(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 20),

                  // Search and Filter Bar
                  _buildFilterBar(context, filter),
                ],
              ),
            ),
          ),

          // Main Project Listing (Sliver)
          projectsAsync.when(
            data: (paginated) {
              if (paginated.items.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(context, canManage),
                );
              }

              if (_isGridView && isDesktop) {
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 440,
                      mainAxisSpacing: 18,
                      crossAxisSpacing: 18,
                      mainAxisExtent: 275,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final project = paginated.items[index];
                        return _ProjectCard(
                          project: project,
                          canManage: canManage,
                          onTap: () => context.push('/projects/${project.id}'),
                        );
                      },
                      childCount: paginated.items.length,
                    ),
                  ),
                );
              }

              // List view (Mobile or selected List mode)
              return SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  isDesktop ? 28 : 16,
                  0,
                  isDesktop ? 28 : 16,
                  28,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final project = paginated.items[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ProjectListItem(
                          project: project,
                          canManage: canManage,
                          onTap: () => context.push('/projects/${project.id}'),
                        ),
                      );
                    },
                    childCount: paginated.items.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.rose),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load projects',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      Text(err.toString(), style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(projectsListProvider),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCards(BuildContext context, ProjectDashboardStats stats, ProjectsFilter filter) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final isWide = width >= 750;

      final cards = [
        _KpiCard(
          title: 'Total Projects',
          value: stats.totalProjects.toString(),
          icon: Icons.folder_outlined,
          color: AppColors.primary,
          isSelected: filter.status == null && !filter.isOverdue,
          onTap: () => _onStatusFilter(null),
        ),
        _KpiCard(
          title: 'In Progress',
          value: stats.inProgressCount.toString(),
          icon: Icons.timelapse,
          color: const Color(0xFF2563EB),
          isSelected: filter.status == 'in_progress',
          onTap: () => _onStatusFilter('in_progress'),
        ),
        _KpiCard(
          title: 'Overdue',
          value: stats.overdueCount.toString(),
          icon: Icons.warning_amber_rounded,
          color: AppColors.rose,
          isAlert: stats.overdueCount > 0,
          isSelected: filter.isOverdue,
          onTap: () => _onStatusFilter('overdue'),
        ),
        _KpiCard(
          title: 'Planning',
          value: stats.planningCount.toString(),
          icon: Icons.assignment_outlined,
          color: const Color(0xFF6B7280),
          isSelected: filter.status == 'planning',
          onTap: () => _onStatusFilter('planning'),
        ),
        _KpiCard(
          title: 'Completed',
          value: stats.completedCount.toString(),
          icon: Icons.check_circle_outline,
          color: AppColors.emerald,
          isSelected: filter.status == 'completed',
          onTap: () => _onStatusFilter('completed'),
        ),
      ];

      if (isWide) {
        return Row(
          children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: c))).toList(),
        );
      }

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: cards.map((c) => SizedBox(width: 150, child: Padding(padding: const EdgeInsets.only(right: 8), child: c))).toList(),
        ),
      );
    });
  }

  Widget _buildFilterBar(BuildContext context, ProjectsFilter filter) {
    final departmentsAsync = ref.watch(departmentsListProvider);
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    final searchField = TextField(
      controller: _searchCtrl,
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Search projects by name, code or client...',
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: _searchCtrl.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  _searchCtrl.clear();
                  _onSearchChanged('');
                },
              )
            : null,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );

    final priorityDropdown = DropdownButton<String>(
      value: filter.priority ?? 'all',
      isExpanded: !isDesktop,
      underline: const SizedBox.shrink(),
      items: const [
        DropdownMenuItem(value: 'all', child: Text('All Priorities')),
        DropdownMenuItem(value: 'urgent', child: Text('🔴 Urgent')),
        DropdownMenuItem(value: 'high', child: Text('🟠 High')),
        DropdownMenuItem(value: 'medium', child: Text('🔵 Medium')),
        DropdownMenuItem(value: 'low', child: Text('⚪ Low')),
      ],
      onChanged: (val) => _onPriorityFilter(val == 'all' ? null : val),
    );

    final deptDropdown = departmentsAsync.when(
      data: (depts) => DropdownButton<int?>(
        value: filter.departmentId,
        isExpanded: !isDesktop,
        underline: const SizedBox.shrink(),
        hint: const Text('All Departments'),
        items: [
          const DropdownMenuItem<int?>(value: null, child: Text('All Departments')),
          ...depts.map((d) => DropdownMenuItem<int?>(value: d.id, child: Text(d.name))),
        ],
        onChanged: (val) {
          ref.read(projectsFilterProvider.notifier).update((cur) => cur.copyWith(
                departmentId: () => val,
                page: 1,
              ));
        },
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          if (isDesktop)
            Row(
              children: [
                Expanded(child: searchField),
                const SizedBox(width: 12),
                priorityDropdown,
                const SizedBox(width: 12),
                deptDropdown,
              ],
            )
          else ...[
            searchField,
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: priorityDropdown),
                const SizedBox(width: 8),
                Expanded(child: deptDropdown),
              ],
            ),
          ],
          const SizedBox(height: 12),

          // Secondary Filter Chips Row: Status chips & My Projects toggle
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Assigned to Me'),
                  selected: filter.myProjects,
                  onSelected: _toggleMyProjects,
                  selectedColor: AppColors.primaryContainer,
                  checkmarkColor: AppColors.primary,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'All Statuses',
                  isSelected: filter.status == null && !filter.isOverdue && !filter.includeArchived,
                  onTap: () => _onStatusFilter(null),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: 'Active',
                  isSelected: filter.status == 'active' || filter.status == 'in_progress',
                  onTap: () => _onStatusFilter('active'),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: 'Planning',
                  isSelected: filter.status == 'planned' || filter.status == 'planning',
                  onTap: () => _onStatusFilter('planned'),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: 'On Hold',
                  isSelected: filter.status == 'on_hold',
                  onTap: () => _onStatusFilter('on_hold'),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: 'Completed',
                  isSelected: filter.status == 'completed',
                  onTap: () => _onStatusFilter('completed'),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: 'Archived',
                  isSelected: filter.status == 'archived' || filter.includeArchived,
                  onTap: () {
                    final willSelect = !(filter.status == 'archived');
                    ref.read(projectsFilterProvider.notifier).update((cur) => cur.copyWith(
                          status: () => willSelect ? 'archived' : null,
                          includeArchived: willSelect,
                          page: 1,
                        ));
                  },
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: '⚠️ Overdue',
                  isSelected: filter.isOverdue,
                  color: AppColors.rose,
                  onTap: () => _onStatusFilter('overdue'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool canManage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.folder_open_outlined, size: 54, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              'No projects found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Try changing your filters or create a new project to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            if (canManage) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => showDialog<bool>(
                  context: context,
                  builder: (_) => const ProjectFormDialog(),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Create First Project'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isSelected = false,
    this.isAlert = false,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isSelected;
  final bool isAlert;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.18), blurRadius: 10, offset: const Offset(0, 4))] : AppColors.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isAlert ? AppColors.rose : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? activeColor : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _ProjectCard extends ConsumerWidget {
  const _ProjectCard({
    required this.project,
    required this.canManage,
    required this.onTap,
  });

  final ProjectItem project;
  final bool canManage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: project.isOverdue ? AppColors.rose.withValues(alpha: 0.5) : AppColors.border,
          width: project.isOverdue ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top tags: Code, Status badge, Priority badge, Menu
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (project.code != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              project.code!,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: project.statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            project.statusDisplay,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: project.statusColor,
                            ),
                          ),
                        ),
                        if (project.healthLabel.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: project.healthLabelColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              project.healthLabelDisplay,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: project.healthLabelColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Priority indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: project.priorityColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      project.priorityDisplay,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: project.priorityColor,
                      ),
                    ),
                  ),
                  if (canManage) ...[
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 18),
                      padding: EdgeInsets.zero,
                      onSelected: (action) async {
                        if (action == 'edit') {
                          await showDialog<bool>(
                            context: context,
                            builder: (_) => ProjectFormDialog(project: project),
                          );
                        } else if (action == 'archive') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Archive Project?'),
                              content: Text('Archive "${project.name}"?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Archive'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await ref
                                .read(projectsControllerProvider)
                                .updateStatus(project.id, status: 'archived', reason: 'Archived by manager');
                          }
                        } else if (action == 'delete') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Project?'),
                              content: Text(
                                  'Are you sure you want to delete "${project.name}"? Only empty projects with no members can be deleted.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.rose),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            try {
                              await ref.read(projectsControllerProvider).deleteProject(project.id);
                            } catch (e) {
                              if (context.mounted) {
                                AppToast.error(context, e);
                              }
                            }
                          }
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit Project')),
                        if (project.status != 'archived')
                          const PopupMenuItem(value: 'archive', child: Text('Archive Project')),
                        const PopupMenuItem(
                            value: 'delete', child: Text('Delete Project', style: TextStyle(color: AppColors.rose))),
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),

              // Project Name
              Text(
                project.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              // Department & Client
              const SizedBox(height: 4),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  if (project.departmentName != null) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.apartment_outlined, size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          project.departmentName!,
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                  if (project.clientName != null) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.business_center_outlined, size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          project.clientName!,
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 12),

              // Task Metrics & Dynamic Progress
              if (project.taskMetricsAvailable && project.taskMetrics != null && project.taskMetrics!.totalTasks > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, size: 13, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${project.taskMetrics!.completedTasks}/${project.taskMetrics!.totalTasks} tasks (${project.progress}%)',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (project.taskMetrics!.overdueTasks > 0)
                        Text(
                          '${project.taskMetrics!.overdueTasks} overdue',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.rose),
                        ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHover,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.checklist_rtl, size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'No tasks created yet',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

              const Spacer(),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Footer: Team Lead & Deadline
              Row(
                children: [
                  // Team Lead
                  Expanded(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                          child: Text(
                            project.teamLeadName != null && project.teamLeadName!.isNotEmpty
                                ? project.teamLeadName![0].toUpperCase()
                                : '?',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            project.teamLeadName ?? 'Unassigned Lead',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: project.teamLeadName != null ? AppColors.textPrimary : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Deadline Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: project.isOverdue
                          ? AppColors.rose.withValues(alpha: 0.12)
                          : AppColors.surfaceHover,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          project.isOverdue ? Icons.error_outline : Icons.access_time,
                          size: 12,
                          color: project.isOverdue ? AppColors.rose : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          project.deadlineDisplay,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: project.isOverdue ? AppColors.rose : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectListItem extends StatelessWidget {
  const _ProjectListItem({
    required this.project,
    required this.canManage,
    required this.onTap,
  });

  final ProjectItem project;
  final bool canManage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    if (!isDesktop) {
      return Card(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: project.isOverdue ? AppColors.rose.withValues(alpha: 0.5) : AppColors.border,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: code, status, health, priority
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (project.code != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                project.code!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: project.statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              project.statusDisplay,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: project.statusColor,
                              ),
                            ),
                          ),
                          if (project.healthLabel.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: project.healthLabelColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                project.healthLabelDisplay,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: project.healthLabelColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: project.priorityColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        project.priorityDisplay,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: project.priorityColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Title
                Text(
                  project.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),

                // Department / Client
                Text(
                  '${project.departmentName ?? 'General'} • ${project.clientName ?? 'Internal'}',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),

                // Footer: Team Lead & Deadline
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 11,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                            child: Text(
                              project.teamLeadName != null && project.teamLeadName!.isNotEmpty
                                  ? project.teamLeadName![0].toUpperCase()
                                  : '?',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              project.teamLeadName ?? 'Unassigned Lead',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: project.isOverdue
                            ? AppColors.rose.withValues(alpha: 0.12)
                            : AppColors.surfaceHover,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        project.deadlineDisplay,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: project.isOverdue ? AppColors.rose : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: project.isOverdue ? AppColors.rose.withValues(alpha: 0.5) : AppColors.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              // Status Pill
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: project.statusColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 14),

              // Title and Department
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (project.code != null) ...[
                          Text(
                            project.code!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            project.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (project.healthLabel.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: project.healthLabelColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              project.healthLabelDisplay,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: project.healthLabelColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${project.departmentName ?? 'General'} • ${project.clientName ?? 'Internal'}',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),

              // Team Lead
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      child: Text(
                        project.teamLeadName != null && project.teamLeadName!.isNotEmpty
                            ? project.teamLeadName![0].toUpperCase()
                            : '?',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        project.teamLeadName ?? 'No Lead',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),

              // Task Metrics Display
              Expanded(
                flex: 2,
                child: (project.taskMetricsAvailable && project.taskMetrics != null && project.taskMetrics!.totalTasks > 0)
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline, size: 12, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '${project.taskMetrics!.completedTasks}/${project.taskMetrics!.totalTasks} tasks (${project.progress}%)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHover,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.checklist_rtl, size: 12, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'No tasks yet',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(width: 16),

              // Deadline
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: project.isOverdue
                      ? AppColors.rose.withValues(alpha: 0.12)
                      : AppColors.surfaceHover,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  project.deadlineDisplay,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: project.isOverdue ? AppColors.rose : AppColors.textSecondary,
                  ),
                ),
              ),

              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
