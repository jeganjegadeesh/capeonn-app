import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../application/organization_controller.dart';
import '../data/hierarchy_model.dart';

class HierarchyPage extends ConsumerWidget {
  const HierarchyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hierarchyAsync = ref.watch(hierarchyListProvider);
    final includeInactive = ref.watch(hierarchyIncludeInactiveProvider);
    final isMobile = MediaQuery.sizeOf(context).width < 768;

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                if (isMobile)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Org Hierarchy',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Inactive', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              const SizedBox(width: 4),
                              Switch(
                                value: includeInactive,
                                onChanged: (val) {
                                  ref.read(hierarchyIncludeInactiveProvider.notifier).toggle(val);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Manager → Team Lead → Employee reporting chain',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Organization Hierarchy',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Reporting structure: Manager → Team Lead → Employee',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Text('Include Inactive', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          const SizedBox(width: 8),
                          Switch(
                            value: includeInactive,
                            onChanged: (val) {
                              ref.read(hierarchyIncludeInactiveProvider.notifier).toggle(val);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                const SizedBox(height: 20),

                // Org Tree View
                hierarchyAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline, size: 40, color: AppColors.rose),
                          const SizedBox(height: 10),
                          Text(err is ApiException ? err.displayMessage : 'Failed to load organization hierarchy'),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () => ref.invalidate(hierarchyListProvider),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (trees) {
                    if (trees.isEmpty) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(48),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.account_tree_outlined, size: 48, color: AppColors.textMuted),
                                const SizedBox(height: 12),
                                Text(
                                  'No hierarchy records found',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Assign reporting managers to employees to see the organization chart.',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final root in trees) ...[
                          _HierarchyTreeNode(node: root, depth: 0),
                          const SizedBox(height: 12),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HierarchyTreeNode extends StatefulWidget {
  const _HierarchyTreeNode({required this.node, required this.depth});

  final HierarchyNode node;
  final int depth;

  @override
  State<_HierarchyTreeNode> createState() => _HierarchyTreeNodeState();
}

class _HierarchyTreeNodeState extends State<_HierarchyTreeNode> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final hasChildren = node.reports.isNotEmpty;
    final (roleBg, roleFg) = AppColors.rolePillColors(node.role);
    final (statusBg, statusFg) = AppColors.statusPillColors(node.isActive);
    final isMobile = MediaQuery.sizeOf(context).width < 768;
    final indent = widget.depth * (isMobile ? 12.0 : 28.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: indent),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.depth > 0)
                Container(
                  width: isMobile ? 12 : 20,
                  height: 2,
                  color: AppColors.border,
                  margin: EdgeInsets.only(right: isMobile ? 6 : 8),
                ),
              Expanded(
                child: Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: hasChildren ? () => setState(() => _isExpanded = !_isExpanded) : null,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 12 : 16,
                        vertical: isMobile ? 10 : 14,
                      ),
                      child: isMobile
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: roleBg,
                                      child: Text(
                                        node.name.isNotEmpty ? node.name[0].toUpperCase() : '?',
                                        style: TextStyle(color: roleFg, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            node.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: AppColors.textPrimary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            node.designation ?? 'Team Member',
                                            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (hasChildren) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryContainer,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.people, size: 11, color: AppColors.primary),
                                            const SizedBox(width: 3),
                                            Text(
                                              '${node.reports.length}',
                                              style: const TextStyle(
                                                color: AppColors.primary,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                                        size: 18,
                                        color: AppColors.textMuted,
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: roleBg,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        (node.role ?? 'staff').toUpperCase(),
                                        style: TextStyle(color: roleFg, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    if (node.employeeCode != null)
                                      Text(
                                        '(${node.employeeCode})',
                                        style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                                      ),
                                    if (!node.isActive)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: statusBg,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Inactive',
                                          style: TextStyle(color: statusFg, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: roleBg,
                                  child: Text(
                                    node.name.isNotEmpty ? node.name[0].toUpperCase() : '?',
                                    style: TextStyle(color: roleFg, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              node.name,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: AppColors.textPrimary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (node.employeeCode != null) ...[
                                            const SizedBox(width: 8),
                                            Text(
                                              '(${node.employeeCode})',
                                              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        node.designation ?? 'Team Member',
                                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: roleBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    (node.role ?? 'staff').toUpperCase(),
                                    style: TextStyle(color: roleFg, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (!node.isActive)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: statusBg,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Inactive',
                                      style: TextStyle(color: statusFg, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                if (hasChildren) ...[
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.people, size: 12, color: AppColors.primary),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${node.reports.length}',
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                                    size: 20,
                                    color: AppColors.textMuted,
                                  ),
                                ],
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (hasChildren && _isExpanded) ...[
          const SizedBox(height: 8),
          for (final child in node.reports) ...[
            _HierarchyTreeNode(node: child, depth: widget.depth + 1),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }
}
