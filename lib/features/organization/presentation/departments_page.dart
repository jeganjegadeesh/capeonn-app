import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/application/auth_controller.dart';
import '../../employees/application/employee_controller.dart';
import '../application/organization_controller.dart';
import '../data/department_model.dart';
import '../data/organization_repository.dart';

class DepartmentsPage extends ConsumerWidget {
  const DepartmentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final departmentsAsync = ref.watch(departmentsListProvider);
    final filter = ref.watch(departmentsFilterProvider);

    final isMobile = MediaQuery.sizeOf(context).width < 768;

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                if (isMobile)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Departments',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (user?.canManageOrganization == true)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add Dept', style: TextStyle(fontSize: 13)),
                              onPressed: () => _openDepartmentDialog(context, ref, null),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage organizational divisions, department heads and codes',
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
                              'Departments',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Manage organizational divisions, department heads and codes',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      if (user?.canManageOrganization == true)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Department'),
                          onPressed: () => _openDepartmentDialog(context, ref, null),
                        ),
                    ],
                  ),
                const SizedBox(height: 20),

                // Search & Filter Bar
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: isMobile
                        ? Column(
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.search, color: AppColors.textMuted, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      decoration: const InputDecoration(
                                        hintText: 'Search by department name or code...',
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        filled: false,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      onChanged: (val) {
                                        ref.read(departmentsFilterProvider.notifier).setFilter(
                                              filter.copyWith(search: val.trim()),
                                            );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: SegmentedButton<bool?>(
                                  segments: const [
                                    ButtonSegment(value: null, label: Text('All')),
                                    ButtonSegment(value: true, label: Text('Active')),
                                    ButtonSegment(value: false, label: Text('Inactive')),
                                  ],
                                  selected: {filter.isActive},
                                  onSelectionChanged: (set) {
                                    ref.read(departmentsFilterProvider.notifier).setFilter(
                                          filter.copyWith(isActive: () => set.first),
                                        );
                                  },
                                  showSelectedIcon: false,
                                  style: SegmentedButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Icon(Icons.search, color: AppColors.textMuted, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  decoration: const InputDecoration(
                                    hintText: 'Search by department name or code...',
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    filled: false,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: (val) {
                                    ref.read(departmentsFilterProvider.notifier).setFilter(
                                          filter.copyWith(search: val.trim()),
                                        );
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Active status toggle
                              SegmentedButton<bool?>(
                                segments: const [
                                  ButtonSegment(value: null, label: Text('All')),
                                  ButtonSegment(value: true, label: Text('Active')),
                                  ButtonSegment(value: false, label: Text('Inactive')),
                                ],
                                selected: {filter.isActive},
                                onSelectionChanged: (set) {
                                  ref.read(departmentsFilterProvider.notifier).setFilter(
                                        filter.copyWith(isActive: () => set.first),
                                      );
                                },
                                showSelectedIcon: false,
                                style: SegmentedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Department List
                departmentsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline, size: 40, color: AppColors.rose),
                          const SizedBox(height: 10),
                          Text(err is ApiException ? err.displayMessage : 'Failed to load departments'),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () => ref.invalidate(departmentsListProvider),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (departments) {
                    if (departments.isEmpty) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(48),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.apartment_outlined, size: 48, color: AppColors.textMuted),
                                const SizedBox(height: 12),
                                Text(
                                  'No departments found',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  filter.search.isNotEmpty
                                      ? 'Try searching with a different term'
                                      : 'Create your first department to organize employees.',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return Card(
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: departments.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, idx) {
                          final dept = departments[idx];
                          final (statusBg, statusFg) = AppColors.statusPillColors(dept.isActive);

                          if (isMobile) {
                            return Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryContainer,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          dept.code,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryDark,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          dept.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: AppColors.textPrimary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: statusBg,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          dept.isActive ? 'Active' : 'Inactive',
                                          style: TextStyle(color: statusFg, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (dept.description != null && dept.description!.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      dept.description!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                    ),
                                  ],
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 6,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.person_pin_outlined, size: 15, color: AppColors.textMuted),
                                          const SizedBox(width: 4),
                                          Text(
                                            dept.head != null ? 'Head: ${dept.head!.name}' : 'No Head assigned',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: dept.head != null ? FontWeight.w600 : FontWeight.normal,
                                              color: dept.head != null ? AppColors.textPrimary : AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.background,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: AppColors.border),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.people_outline, size: 13, color: AppColors.textSecondary),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${dept.employeesCount ?? 0} staff',
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (user?.canManageOrganization == true) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton.icon(
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            visualDensity: VisualDensity.compact,
                                          ),
                                          icon: const Icon(Icons.edit_outlined, size: 16),
                                          label: const Text('Edit', style: TextStyle(fontSize: 12)),
                                          onPressed: () => _openDepartmentDialog(context, ref, dept),
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton.icon(
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            foregroundColor: AppColors.rose,
                                            visualDensity: VisualDensity.compact,
                                          ),
                                          icon: const Icon(Icons.delete_outline, size: 16),
                                          label: const Text('Delete', style: TextStyle(fontSize: 12)),
                                          onPressed: () => _confirmDelete(context, ref, dept),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    dept.code,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryDark,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        dept.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      if (dept.description != null && dept.description!.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          dept.description!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: Row(
                                    children: [
                                      Icon(Icons.person_pin_outlined, size: 16, color: AppColors.textMuted),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          dept.head != null ? dept.head!.name : 'No Head',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: dept.head != null ? FontWeight.w600 : FontWeight.normal,
                                            color: dept.head != null ? AppColors.textPrimary : AppColors.textMuted,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.people_outline, size: 14, color: AppColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${dept.employeesCount ?? 0} staff',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: statusBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    dept.isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(color: statusFg, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                if (user?.canManageOrganization == true) ...[
                                  const SizedBox(width: 12),
                                  IconButton(
                                    tooltip: 'Edit Department',
                                    icon: const Icon(Icons.edit_outlined, size: 18),
                                    onPressed: () => _openDepartmentDialog(context, ref, dept),
                                  ),
                                  IconButton(
                                    tooltip: 'Delete Department',
                                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.rose),
                                    onPressed: () => _confirmDelete(context, ref, dept),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
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

  void _openDepartmentDialog(BuildContext context, WidgetRef ref, Department? dept) {
    showDialog(
      context: context,
      builder: (ctx) => _DepartmentFormDialog(department: dept),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Department dept) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Department'),
        content: Text('Are you sure you want to delete "${dept.name}" (${dept.code})? '
            'This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.rose),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(organizationRepositoryProvider).deleteDepartment(dept.id);
                ref.invalidate(departmentsListProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Department "${dept.name}" deleted')),
                  );
                }
              } on ApiException catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.displayMessage),
                      backgroundColor: AppColors.rose,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _DepartmentFormDialog extends ConsumerStatefulWidget {
  const _DepartmentFormDialog({this.department});

  final Department? department;

  @override
  ConsumerState<_DepartmentFormDialog> createState() => _DepartmentFormDialogState();
}

class _DepartmentFormDialogState extends ConsumerState<_DepartmentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _descriptionController;

  int? _headUserId;
  bool _isActive = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final d = widget.department;
    _nameController = TextEditingController(text: d?.name ?? '');
    _codeController = TextEditingController(text: d?.code ?? '');
    _descriptionController = TextEditingController(text: d?.description ?? '');
    _headUserId = d?.head?.id;
    _isActive = d?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'code': _codeController.text.trim().toUpperCase(),
      'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      'head_user_id': _headUserId,
      'is_active': _isActive,
    };

    try {
      if (widget.department == null) {
        await ref.read(organizationRepositoryProvider).createDepartment(data);
      } else {
        await ref.read(organizationRepositoryProvider).updateDepartment(widget.department!.id, data);
      }
      ref.invalidate(departmentsListProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.department == null ? 'Department created' : 'Department updated'),
          ),
        );
      }
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.displayMessage);
    } catch (_) {
      setState(() => _errorMessage = 'Failed to save department.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final supervisorsAsync = ref.watch(potentialSupervisorsProvider);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.department == null ? 'Create Department' : 'Edit Department',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.roseContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.rose.withValues(alpha: 0.3)),
                    ),
                    child: Text(_errorMessage!, style: const TextStyle(color: AppColors.rose, fontSize: 13)),
                  ),
                  const SizedBox(height: 14),
                ],
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Name *', hintText: 'e.g. Engineering'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _codeController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(labelText: 'Code *', hintText: 'ENG'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description (optional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                // Department Head selector
                supervisorsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (supervisors) {
                    return DropdownButtonFormField<int?>(
                      initialValue: _headUserId,
                      decoration: const InputDecoration(labelText: 'Department Head'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('No Head Assigned')),
                        for (final s in supervisors)
                          DropdownMenuItem(
                            value: s.id,
                            child: Text('${s.name} (${s.roleName})'),
                          ),
                      ],
                      onChanged: (val) => setState(() => _headUserId = val),
                    );
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Department Active'),
                  subtitle: const Text('Inactive departments are hidden from selection'),
                  value: _isActive,
                  onChanged: (val) => setState(() => _isActive = val),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _submit,
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(widget.department == null ? 'Create' : 'Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
