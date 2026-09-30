import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/application/auth_controller.dart';
import '../application/organization_controller.dart';
import '../data/designation_model.dart';
import '../data/organization_repository.dart';

class DesignationsPage extends ConsumerWidget {
  const DesignationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final designationsAsync = ref.watch(designationsListProvider);
    final filter = ref.watch(designationsFilterProvider);

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
                // Header Row
                if (isMobile)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Designations',
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
                              label: const Text('Add', style: TextStyle(fontSize: 13)),
                              onPressed: () => _openDesignationDialog(context, ref, null),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Job titles and operational designations in the company',
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
                            const Text(
                              'Designations',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Job titles and operational designations in the company',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      if (user?.canManageOrganization == true)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Designation'),
                          onPressed: () => _openDesignationDialog(context, ref, null),
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
                                  const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      decoration: const InputDecoration(
                                        hintText: 'Search designations...',
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        filled: false,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      onChanged: (val) {
                                        ref.read(designationsFilterProvider.notifier).setFilter(
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
                                    ref.read(designationsFilterProvider.notifier).setFilter(
                                          filter.copyWith(isActive: () => set.first),
                                        );
                                  },
                                  showSelectedIcon: false,
                                  style: SegmentedButton.styleFrom(visualDensity: VisualDensity.compact),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  decoration: const InputDecoration(
                                    hintText: 'Search designations...',
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    filled: false,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: (val) {
                                    ref.read(designationsFilterProvider.notifier).setFilter(
                                          filter.copyWith(search: val.trim()),
                                        );
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              SegmentedButton<bool?>(
                                segments: const [
                                  ButtonSegment(value: null, label: Text('All')),
                                  ButtonSegment(value: true, label: Text('Active')),
                                  ButtonSegment(value: false, label: Text('Inactive')),
                                ],
                                selected: {filter.isActive},
                                onSelectionChanged: (set) {
                                  ref.read(designationsFilterProvider.notifier).setFilter(
                                        filter.copyWith(isActive: () => set.first),
                                      );
                                },
                                showSelectedIcon: false,
                                style: SegmentedButton.styleFrom(visualDensity: VisualDensity.compact),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Designations List
                designationsAsync.when(
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
                          Text(err is ApiException ? err.displayMessage : 'Failed to load designations'),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () => ref.invalidate(designationsListProvider),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (designations) {
                    if (designations.isEmpty) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(48),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(Icons.badge_outlined, size: 48, color: AppColors.textMuted),
                                const SizedBox(height: 12),
                                const Text(
                                  'No designations found',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  filter.search.isNotEmpty
                                      ? 'Try searching with a different term'
                                      : 'Create job titles for employees to hold.',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
                        itemCount: designations.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, idx) {
                          final desig = designations[idx];
                          final (statusBg, statusFg) = AppColors.statusPillColors(desig.isActive);

                          if (isMobile) {
                            return Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.emeraldContainer,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Icon(Icons.badge_outlined, color: AppColors.emerald, size: 18),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          desig.name,
                                          style: const TextStyle(
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
                                          desig.isActive ? 'Active' : 'Inactive',
                                          style: TextStyle(color: statusFg, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.background,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: AppColors.border),
                                        ),
                                        child: Text(
                                          '${desig.employeesCount ?? 0} assigned',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      const Spacer(),
                                      if (user?.canManageOrganization == true) ...[
                                        TextButton.icon(
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            visualDensity: VisualDensity.compact,
                                          ),
                                          icon: const Icon(Icons.edit_outlined, size: 16),
                                          label: const Text('Edit', style: TextStyle(fontSize: 12)),
                                          onPressed: () => _openDesignationDialog(context, ref, desig),
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
                                          onPressed: () => _confirmDelete(context, ref, desig),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.emeraldContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.badge_outlined, color: AppColors.emerald, size: 20),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    desig.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: AppColors.textPrimary,
                                    ),
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
                                  child: Text(
                                    '${desig.employeesCount ?? 0} assigned',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
                                    desig.isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(color: statusFg, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                if (user?.canManageOrganization == true) ...[
                                  const SizedBox(width: 12),
                                  IconButton(
                                    tooltip: 'Edit Designation',
                                    icon: const Icon(Icons.edit_outlined, size: 18),
                                    onPressed: () => _openDesignationDialog(context, ref, desig),
                                  ),
                                  IconButton(
                                    tooltip: 'Delete Designation',
                                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.rose),
                                    onPressed: () => _confirmDelete(context, ref, desig),
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

  void _openDesignationDialog(BuildContext context, WidgetRef ref, Designation? desig) {
    showDialog(
      context: context,
      builder: (ctx) => _DesignationFormDialog(designation: desig),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Designation desig) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Designation'),
        content: Text('Are you sure you want to delete "${desig.name}"? '
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
                await ref.read(organizationRepositoryProvider).deleteDesignation(desig.id);
                ref.invalidate(designationsListProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Designation "${desig.name}" deleted')),
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

class _DesignationFormDialog extends ConsumerStatefulWidget {
  const _DesignationFormDialog({this.designation});

  final Designation? designation;

  @override
  ConsumerState<_DesignationFormDialog> createState() => _DesignationFormDialogState();
}

class _DesignationFormDialogState extends ConsumerState<_DesignationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  bool _isActive = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.designation?.name ?? '');
    _isActive = widget.designation?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
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
      'is_active': _isActive,
    };

    try {
      if (widget.designation == null) {
        await ref.read(organizationRepositoryProvider).createDesignation(data);
      } else {
        await ref.read(organizationRepositoryProvider).updateDesignation(widget.designation!.id, data);
      }
      ref.invalidate(designationsListProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.designation == null ? 'Designation created' : 'Designation updated'),
          ),
        );
      }
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.displayMessage);
    } catch (_) {
      setState(() => _errorMessage = 'Failed to save designation.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.designation == null ? 'Create Designation' : 'Edit Designation',
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
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Designation Name *', hintText: 'e.g. Senior Software Engineer'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active Status'),
                  subtitle: const Text('Inactive designations cannot be assigned to new hires'),
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
                          : Text(widget.designation == null ? 'Create' : 'Save'),
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
