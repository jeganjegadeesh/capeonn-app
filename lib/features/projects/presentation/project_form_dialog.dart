import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/application/auth_controller.dart';
import '../../employees/application/employee_controller.dart';
import '../../organization/application/organization_controller.dart';
import '../application/projects_controller.dart';
import '../data/project_models.dart';

class ProjectFormDialog extends ConsumerStatefulWidget {
  const ProjectFormDialog({super.key, this.project});

  final ProjectItem? project;

  @override
  ConsumerState<ProjectFormDialog> createState() => _ProjectFormDialogState();
}

class _ProjectFormDialogState extends ConsumerState<ProjectFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _codeCtrl;
  late final TextEditingController _clientCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _estimatedHoursCtrl;
  late final TextEditingController _budgetCtrl;

  int? _selectedDepartmentId;
  int? _selectedTeamLeadId;
  String _status = 'planning';
  String _priority = 'medium';
  DateTime? _startDate;
  DateTime? _deadline;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final p = widget.project;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _codeCtrl = TextEditingController(text: p?.code ?? '');
    _clientCtrl = TextEditingController(text: p?.clientName ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _estimatedHoursCtrl = TextEditingController(text: p?.estimatedHours?.toString() ?? '');
    _budgetCtrl = TextEditingController(text: p?.budget?.toString() ?? '');

    _selectedDepartmentId = p?.departmentId;
    _selectedTeamLeadId = p?.teamLeadId;
    _status = p?.status ?? 'planning';
    _priority = p?.priority ?? 'medium';

    if (p?.startDate != null) {
      _startDate = DateTime.tryParse(p!.startDate!);
    }
    if (p?.deadline != null) {
      _deadline = DateTime.tryParse(p!.deadline!);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _clientCtrl.dispose();
    _descCtrl.dispose();
    _estimatedHoursCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initialDate = isStart
        ? (_startDate ?? DateTime.now())
        : (_deadline ?? (_startDate ?? DateTime.now()).add(const Duration(days: 30)));

    final firstDate = DateTime(2020);
    final lastDate = DateTime(2035);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_deadline != null && _deadline!.isBefore(_startDate!)) {
            _deadline = _startDate;
          }
        } else {
          _deadline = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDepartmentId == null) {
      setState(() => _errorMessage = 'Please select a department');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final payload = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'department_id': _selectedDepartmentId,
      'priority': _priority,
    };

    if (widget.project == null) {
      payload['status'] = _status;
    }

    if (_codeCtrl.text.trim().isNotEmpty) {
      payload['code'] = _codeCtrl.text.trim();
    }
    if (_clientCtrl.text.trim().isNotEmpty) {
      payload['client_name'] = _clientCtrl.text.trim();
    }
    if (_descCtrl.text.trim().isNotEmpty) {
      payload['description'] = _descCtrl.text.trim();
    }
    if (_estimatedHoursCtrl.text.trim().isNotEmpty) {
      payload['estimated_hours'] = double.tryParse(_estimatedHoursCtrl.text.trim());
    }
    if (_budgetCtrl.text.trim().isNotEmpty) {
      payload['budget'] = double.tryParse(_budgetCtrl.text.trim());
    }
    if (_selectedTeamLeadId != null) {
      payload['team_lead_id'] = _selectedTeamLeadId;
    }
    if (_startDate != null) {
      payload['start_date'] = _startDate!.toIso8601String().substring(0, 10);
    }
    if (_deadline != null) {
      payload['deadline'] = _deadline!.toIso8601String().substring(0, 10);
    }

    try {
      final ctrl = ref.read(projectsControllerProvider);
      if (widget.project == null) {
        await ctrl.createProject(payload);
      } else {
        await ctrl.updateProject(widget.project!.id, payload);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        AppToast.success(
          context,
          widget.project == null ? 'Project created successfully' : 'Project updated successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = ApiException.cleanMessage(e);
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.project != null;
    final departmentsAsync = ref.watch(departmentsListProvider);
    final supervisorsAsync = ref.watch(potentialSupervisorsProvider);
    final currentUser = ref.watch(authControllerProvider).value;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 780),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isEdit ? Icons.edit_note : Icons.add_chart,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEdit ? 'Edit Project' : 'Create New Project',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            isEdit
                                ? 'Update project scope, dates, and assignments'
                                : 'Define project requirements and assign a Team Lead',
                            style: TextStyle(
                              fontSize: 13,
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

                // Error alert
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.rose.withValues(alpha: 0.1),
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
                ],

                // Scrollable Form Body
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Name and Code
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _nameCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Project Name *',
                                  hintText: 'e.g. Mobile App Redesign',
                                  prefixIcon: Icon(Icons.folder_outlined, size: 20),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Project name is required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _codeCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Code (Optional)',
                                  hintText: 'PRJ-001',
                                  prefixIcon: Icon(Icons.tag, size: 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Row 2: Department and Client Name
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: departmentsAsync.when(
                                data: (depts) {
                                  if (_selectedDepartmentId == null && depts.isNotEmpty) {
                                    if (currentUser?.isManager == true && currentUser?.departmentName != null) {
                                      final myDept = depts.firstWhere(
                                        (d) => d.name == currentUser!.departmentName,
                                        orElse: () => depts.first,
                                      );
                                      _selectedDepartmentId = myDept.id;
                                    } else {
                                      _selectedDepartmentId = depts.first.id;
                                    }
                                  }
                                  return DropdownButtonFormField<int>(
                                    initialValue: _selectedDepartmentId,
                                    decoration: const InputDecoration(
                                      labelText: 'Department *',
                                      prefixIcon: Icon(Icons.apartment_outlined, size: 20),
                                    ),
                                    items: depts.map((d) {
                                      return DropdownMenuItem<int>(
                                        value: d.id,
                                        child: Text(d.name),
                                      );
                                    }).toList(),
                                    onChanged: (val) => setState(() => _selectedDepartmentId = val),
                                    validator: (val) => val == null ? 'Select department' : null,
                                  );
                                },
                                loading: () => const LinearProgressIndicator(),
                                error: (_, _) => const Text('Failed to load departments'),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: TextFormField(
                                controller: _clientCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Client Name (Optional)',
                                  hintText: 'e.g. Acme Corp',
                                  prefixIcon: Icon(Icons.business_center_outlined, size: 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Row 3: Team Lead Picker (strictly Team Lead role)
                        supervisorsAsync.when(
                          data: (supervisors) {
                            final teamLeads = supervisors.where((s) => s.role?.slug == 'team_lead' || s.id == _selectedTeamLeadId).toList();
                            return DropdownButtonFormField<int?>(
                              initialValue: _selectedTeamLeadId,
                              decoration: const InputDecoration(
                                labelText: 'Assigned Team Lead',
                                hintText: 'Select Team Lead (Team Lead role only)',
                                prefixIcon: Icon(Icons.person_pin_outlined, size: 20),
                              ),
                              items: [
                                const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text('None (Unassigned)'),
                                ),
                                ...teamLeads.map((s) {
                                  return DropdownMenuItem<int?>(
                                    value: s.id,
                                    child: Text('${s.name} (${s.role?.name ?? 'Team Lead'})'),
                                  );
                                }),
                              ],
                              onChanged: (val) => setState(() => _selectedTeamLeadId = val),
                            );
                          },
                          loading: () => const LinearProgressIndicator(),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 16),

                        // Row 4: Status (on create only) and Priority
                        Row(
                          children: [
                            if (!isEdit) ...[
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _status == 'in_progress' ? 'active' : (_status == 'planning' ? 'planned' : _status),
                                  decoration: const InputDecoration(
                                    labelText: 'Initial Status',
                                    prefixIcon: Icon(Icons.timelapse, size: 20),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'planned', child: Text('Planned')),
                                    DropdownMenuItem(value: 'active', child: Text('Active')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setState(() => _status = val);
                                  },
                                ),
                              ),
                              const SizedBox(width: 14),
                            ],
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _priority,
                                decoration: const InputDecoration(
                                  labelText: 'Priority',
                                  prefixIcon: Icon(Icons.flag_outlined, size: 20),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'low', child: Text('Low')),
                                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                                  DropdownMenuItem(value: 'high', child: Text('High')),
                                  DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _priority = val);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Row 5: Dates
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _pickDate(isStart: true),
                                borderRadius: BorderRadius.circular(8),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Start Date',
                                    prefixIcon: Icon(Icons.calendar_today_outlined, size: 20),
                                  ),
                                  child: Text(
                                    _startDate != null
                                        ? '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}'
                                        : 'Select date',
                                    style: TextStyle(
                                      color: _startDate != null ? AppColors.textPrimary : AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: InkWell(
                                onTap: () => _pickDate(isStart: false),
                                borderRadius: BorderRadius.circular(8),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Deadline',
                                    prefixIcon: Icon(Icons.event_available_outlined, size: 20),
                                  ),
                                  child: Text(
                                    _deadline != null
                                        ? '${_deadline!.year}-${_deadline!.month.toString().padLeft(2, '0')}-${_deadline!.day.toString().padLeft(2, '0')}'
                                        : 'Select date',
                                    style: TextStyle(
                                      color: _deadline != null ? AppColors.textPrimary : AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Row 6: Estimated Hours & Budget
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _estimatedHoursCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Estimated Hours',
                                  hintText: 'e.g. 120.0',
                                  prefixIcon: Icon(Icons.hourglass_bottom, size: 20),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: TextFormField(
                                controller: _budgetCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Budget (USD)',
                                  hintText: 'e.g. 15000',
                                  prefixIcon: Icon(Icons.attach_money, size: 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Progress & Task Metrics Info
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 18, color: AppColors.textMuted),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Task metrics & progress calculation will be automatically computed in Phase 5 based on task completion.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Description
                        TextFormField(
                          controller: _descCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Project Scope & Description',
                            hintText: 'Describe project goals, architecture, key deliverables...',
                            alignLabelWithHint: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Footer Buttons
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
                          : Icon(isEdit ? Icons.check : Icons.add),
                      label: Text(isEdit ? 'Update Project' : 'Create Project'),
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
