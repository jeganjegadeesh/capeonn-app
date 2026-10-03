import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../employees/application/employee_controller.dart';
import '../application/projects_controller.dart';

class AddProjectMemberDialog extends ConsumerStatefulWidget {
  const AddProjectMemberDialog({
    super.key,
    required this.projectId,
    required this.existingMemberUserIds,
  });

  final int projectId;
  final Set<int> existingMemberUserIds;

  @override
  ConsumerState<AddProjectMemberDialog> createState() => _AddProjectMemberDialogState();
}

class _AddProjectMemberDialogState extends ConsumerState<AddProjectMemberDialog> {
  int? _selectedUserId;
  String _selectedRole = 'Developer';
  final _customRoleCtrl = TextEditingController();
  bool _useCustomRole = false;
  bool _isSaving = false;
  String? _errorMessage;

  final _commonRoles = const [
    'Developer',
    'Frontend Developer',
    'Backend Developer',
    'Mobile Developer',
    'Flutter Developer',
    'UI/UX Designer',
    'QA Engineer',
    'DevOps Engineer',
    'Business Analyst',
    'Tech Lead',
    'Member',
  ];

  @override
  void dispose() {
    _customRoleCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedUserId == null) {
      setState(() => _errorMessage = 'Please select an employee');
      return;
    }

    final role = _useCustomRole
        ? _customRoleCtrl.text.trim()
        : _selectedRole;

    if (role.isEmpty) {
      setState(() => _errorMessage = 'Please enter a project role');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final res = await ref.read(projectsControllerProvider).addMember(
            widget.projectId,
            _selectedUserId!,
            role,
          );

      if (mounted) {
        Navigator.of(context).pop(true);
        if (res.warnings.isNotEmpty) {
          final warningMsg = res.warnings.join('\n');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Member added with warnings:\n$warningMsg'),
              backgroundColor: AppColors.amber,
              duration: const Duration(seconds: 5),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Member added to project team'),
              backgroundColor: AppColors.emerald,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final supervisorsAsync = ref.watch(potentialSupervisorsProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.person_add_alt_1, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Team Member',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Assign an employee to this project team',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.rose.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.rose.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.rose, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.rose, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Employee Selector
              supervisorsAsync.when(
                data: (employees) {
                  final eligible = employees
                      .where((e) => !widget.existingMemberUserIds.contains(e.id))
                      .toList();

                  if (eligible.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'All active employees are already members of this project.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    );
                  }

                  return DropdownButtonFormField<int>(
                    initialValue: _selectedUserId,
                    decoration: const InputDecoration(
                      labelText: 'Select Employee *',
                      prefixIcon: Icon(Icons.badge_outlined, size: 20),
                    ),
                    items: eligible.map((e) {
                      return DropdownMenuItem<int>(
                        value: e.id,
                        child: Text('${e.name} (${e.role?.name ?? 'Employee'})'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedUserId = val),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const Text('Failed to load employees'),
              ),
              const SizedBox(height: 16),

              // Role Selector
              if (!_useCustomRole) ...[
                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Project Role *',
                    prefixIcon: Icon(Icons.assignment_ind_outlined, size: 20),
                  ),
                  items: _commonRoles.map((r) {
                    return DropdownMenuItem(value: r, child: Text(r));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedRole = val);
                  },
                ),
              ] else ...[
                TextFormField(
                  controller: _customRoleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Custom Project Role *',
                    hintText: 'e.g. Lead Cloud Architect',
                    prefixIcon: Icon(Icons.edit_outlined, size: 20),
                  ),
                ),
              ],
              const SizedBox(height: 8),

              // Toggle custom role
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _useCustomRole = !_useCustomRole;
                        if (_useCustomRole && _customRoleCtrl.text.isEmpty) {
                          _customRoleCtrl.text = _selectedRole;
                        }
                      });
                    },
                    icon: Icon(_useCustomRole ? Icons.list : Icons.edit, size: 16),
                    label: Text(
                      _useCustomRole ? 'Pick from standard roles' : 'Enter custom role',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _submit,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.person_add, size: 18),
                    label: const Text('Add Member'),
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
