import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../organization/application/organization_controller.dart';
import '../application/employee_controller.dart';
import '../data/employee_model.dart';
import '../data/employee_repository.dart';

class EmployeeFormDialog extends ConsumerStatefulWidget {
  const EmployeeFormDialog({super.key, this.employee});

  final Employee? employee;

  @override
  ConsumerState<EmployeeFormDialog> createState() => _EmployeeFormDialogState();
}

class _EmployeeFormDialogState extends ConsumerState<EmployeeFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _phoneController;
  late final TextEditingController _employeeCodeController;
  late final TextEditingController _joinedOnController;

  int? _roleId;
  int? _departmentId;
  int? _designationId;
  int? _reportsToId;
  bool _isActive = true;

  bool _isSaving = false;
  String? _errorMessage;
  final Map<String, String> _fieldErrors = {};

  bool get _isEditing => widget.employee != null;

  @override
  void initState() {
    super.initState();
    final emp = widget.employee;
    _nameController = TextEditingController(text: emp?.name ?? '');
    _emailController = TextEditingController(text: emp?.email ?? '');
    _passwordController = TextEditingController();
    _phoneController = TextEditingController(text: emp?.phone ?? '');
    _employeeCodeController = TextEditingController(text: emp?.employeeCode ?? '');
    _joinedOnController = TextEditingController(
      text: emp?.joinedOn ?? DateTime.now().toIso8601String().split('T').first,
    );

    _roleId = emp?.roleId;
    _departmentId = emp?.departmentId;
    _designationId = emp?.designationId;
    _reportsToId = emp?.reportsToId;
    _isActive = emp?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _employeeCodeController.dispose();
    _joinedOnController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    _fieldErrors.clear();
    if (!_formKey.currentState!.validate()) return;

    if (_roleId == null) {
      setState(() => _errorMessage = 'Please select a role for this employee.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'role_id': _roleId,
      'department_id': _departmentId,
      'designation_id': _designationId,
      'reports_to_id': _reportsToId,
      'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      'employee_code': _employeeCodeController.text.trim().isEmpty ? null : _employeeCodeController.text.trim(),
      'joined_on': _joinedOnController.text.trim().isEmpty ? null : _joinedOnController.text.trim(),
    };

    if (!_isEditing) {
      data['password'] = _passwordController.text;
    } else {
      data['is_active'] = _isActive;
    }

    try {
      if (!_isEditing) {
        await ref.read(employeeRepositoryProvider).createEmployee(data);
      } else {
        await ref.read(employeeRepositoryProvider).updateEmployee(widget.employee!.id, data);
      }

      ref.invalidate(employeesListProvider);
      ref.invalidate(potentialSupervisorsProvider);
      ref.invalidate(hierarchyListProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Employee updated successfully' : 'Employee created successfully'),
          ),
        );
      }
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.displayMessage;
        for (final entry in e.errors.entries) {
          if (entry.value.isNotEmpty) {
            _fieldErrors[entry.key] = entry.value.first;
          }
        }
      });
    } catch (_) {
      setState(() => _errorMessage = 'An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rolesAsync = ref.watch(assignableRolesProvider);
    final departmentsAsync = ref.watch(departmentsListProvider);
    final designationsAsync = ref.watch(designationsListProvider);
    final supervisorsAsync = ref.watch(potentialSupervisorsProvider);
    final isMobile = MediaQuery.sizeOf(context).width < 500;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 720),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'Edit Employee Details' : 'Add New Employee',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.roseContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.rose.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.rose, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppColors.rose, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                Expanded(
                  child: ListView(
                    children: [
                      // Full Name
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name *',
                          errorText: _fieldErrors['name'],
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),

                      // Email & Phone
                      if (isMobile) ...[
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email Address *',
                            errorText: _fieldErrors['email'],
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: 'Phone',
                            errorText: _fieldErrors['phone'],
                          ),
                        ),
                      ] else
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: 'Email Address *',
                                  errorText: _fieldErrors['email'],
                                ),
                                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _phoneController,
                                decoration: InputDecoration(
                                  labelText: 'Phone',
                                  errorText: _fieldErrors['phone'],
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 12),

                      // Password (only when creating)
                      if (!_isEditing) ...[
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Initial Password *',
                            hintText: 'Must be at least 8 characters',
                            errorText: _fieldErrors['password'],
                          ),
                          validator: (v) => v == null || v.length < 8
                              ? 'Password must have at least 8 characters'
                              : null,
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Employee Code & Joined Date
                      if (isMobile) ...[
                        TextFormField(
                          controller: _employeeCodeController,
                          decoration: InputDecoration(
                            labelText: 'Employee Code',
                            hintText: 'Auto-generated if empty',
                            errorText: _fieldErrors['employee_code'],
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _joinedOnController,
                          decoration: InputDecoration(
                            labelText: 'Joining Date',
                            hintText: 'YYYY-MM-DD',
                            errorText: _fieldErrors['joined_on'],
                          ),
                        ),
                      ] else
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _employeeCodeController,
                                decoration: InputDecoration(
                                  labelText: 'Employee Code',
                                  hintText: 'Auto-generated if empty',
                                  errorText: _fieldErrors['employee_code'],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _joinedOnController,
                                decoration: InputDecoration(
                                  labelText: 'Joining Date',
                                  hintText: 'YYYY-MM-DD',
                                  errorText: _fieldErrors['joined_on'],
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 12),

                      // Role Dropdown
                      rolesAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (_, _) => const Text('Failed to load roles'),
                        data: (roles) {
                          // If current roleId not in list, add null fallback
                          final hasMatch = roles.any((r) => r.id == _roleId);
                          final selectedVal = hasMatch ? _roleId : null;

                          return DropdownButtonFormField<int>(
                            initialValue: selectedVal,
                            decoration: InputDecoration(
                              labelText: 'System Role *',
                              errorText: _fieldErrors['role_id'],
                            ),
                            items: [
                              for (final r in roles)
                                DropdownMenuItem(
                                  value: r.id,
                                  child: Text('${r.name} (${r.slug})'),
                                ),
                            ],
                            onChanged: (val) => setState(() => _roleId = val),
                          );
                        },
                      ),
                      const SizedBox(height: 12),

                      // Department Dropdown
                      departmentsAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (_, _) => const SizedBox.shrink(),
                        data: (depts) {
                          return DropdownButtonFormField<int?>(
                            initialValue: _departmentId,
                            decoration: InputDecoration(
                              labelText: 'Department',
                              errorText: _fieldErrors['department_id'],
                            ),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('No Department')),
                              for (final d in depts)
                                DropdownMenuItem(
                                  value: d.id,
                                  child: Text('${d.name} (${d.code})'),
                                ),
                            ],
                            onChanged: (val) => setState(() => _departmentId = val),
                          );
                        },
                      ),
                      const SizedBox(height: 12),

                      // Designation Dropdown
                      designationsAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (_, _) => const SizedBox.shrink(),
                        data: (desigs) {
                          return DropdownButtonFormField<int?>(
                            initialValue: _designationId,
                            decoration: InputDecoration(
                              labelText: 'Designation',
                              errorText: _fieldErrors['designation_id'],
                            ),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('No Designation')),
                              for (final d in desigs)
                                DropdownMenuItem(
                                  value: d.id,
                                  child: Text(d.name),
                                ),
                            ],
                            onChanged: (val) => setState(() => _designationId = val),
                          );
                        },
                      ),
                      const SizedBox(height: 12),

                      // Reports To Supervisor Dropdown
                      supervisorsAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (_, _) => const SizedBox.shrink(),
                        data: (supervisors) {
                          // Exclude current employee from reporting to self
                          final filtered = supervisors.where((s) => s.id != widget.employee?.id).toList();

                          return DropdownButtonFormField<int?>(
                            initialValue: _reportsToId,
                            decoration: InputDecoration(
                              labelText: 'Reports To (Supervisor)',
                              errorText: _fieldErrors['reports_to_id'],
                            ),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('None (Reports to Company Head)')),
                              for (final s in filtered)
                                DropdownMenuItem(
                                  value: s.id,
                                  child: Text('${s.name} · ${s.roleName} (${s.departmentName})'),
                                ),
                            ],
                            onChanged: (val) => setState(() => _reportsToId = val),
                          );
                        },
                      ),

                      if (_isEditing) ...[
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Account Active'),
                          subtitle: const Text('Deactivating signs user out immediately on all devices'),
                          value: _isActive,
                          onChanged: (val) => setState(() => _isActive = val),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

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
                          : Text(_isEditing ? 'Save Changes' : 'Create Employee'),
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
