import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/api_exception.dart';
import '../../../projects/data/project_models.dart';
import '../../data/task_models.dart';
import '../../data/task_repository.dart';
import '../../application/tasks_providers.dart';

class TaskFormDialog extends ConsumerStatefulWidget {
  const TaskFormDialog({
    super.key,
    required this.projectId,
    this.parentTaskId,
    this.taskToEdit,
    this.projectMembers = const [],
    this.teamLead,
  });

  final int projectId;
  final int? parentTaskId;
  final TaskItem? taskToEdit;
  final List<ProjectMemberItem> projectMembers;
  final TaskUserItem? teamLead;

  @override
  ConsumerState<TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends ConsumerState<TaskFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _estimatedHoursController;
  late String _priority;
  DateTime? _dueDate;
  int? _assignedToId;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isEdit => widget.taskToEdit != null;
  bool get isSubtask => widget.parentTaskId != null;

  @override
  void initState() {
    super.initState();
    final t = widget.taskToEdit;
    _titleController = TextEditingController(text: t?.title ?? '');
    _descController = TextEditingController(text: t?.description ?? '');
    _estimatedHoursController = TextEditingController(
      text: t?.estimatedHours != null ? t!.estimatedHours.toString() : '',
    );
    _priority = t?.priority ?? TaskPriority.medium;
    if (t?.dueDate != null) {
      _dueDate = DateTime.tryParse(t!.dueDate!);
    }
    _assignedToId = t?.assignedTo?.id;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _estimatedHoursController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now.add(const Duration(days: 7)),
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final data = <String, dynamic>{
      'title': _titleController.text.trim(),
      'description': _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
      'priority': _priority,
      'estimated_hours': _estimatedHoursController.text.isNotEmpty
          ? double.tryParse(_estimatedHoursController.text.trim())
          : null,
      'due_date': _dueDate?.toIso8601String().split('T').first,
      'assigned_to_id': _assignedToId,
    };

    if (isSubtask) {
      data['parent_task_id'] = widget.parentTaskId;
    }

    try {
      final repo = ref.read(taskRepositoryProvider);
      TaskItem result;

      if (isEdit) {
        result = await repo.updateTask(widget.taskToEdit!.id, data);
        ref.invalidate(taskDetailProvider(widget.taskToEdit!.id));
      } else if (isSubtask) {
        result = await repo.createSubtask(widget.parentTaskId!, data);
        ref.invalidate(taskDetailProvider(widget.parentTaskId!));
      } else {
        result = await repo.createTask(widget.projectId, data);
      }

      ref.invalidate(projectTasksProvider(widget.projectId));
      ref.invalidate(myTasksProvider);

      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = ApiException.cleanMessage(e);
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Compile selectable assignees: Team Lead + Project Members
    final assignees = <_AssigneeOption>[];
    if (widget.teamLead != null) {
      assignees.add(_AssigneeOption(
        id: widget.teamLead!.id,
        name: '${widget.teamLead!.name} (Team Lead)',
      ));
    }
    for (final m in widget.projectMembers) {
      if (widget.teamLead?.id != m.userId) {
        assignees.add(_AssigneeOption(
          id: m.userId,
          name: '${m.name} (${m.projectRole})',
        ));
      }
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.surface,
      title: Row(
        children: [
          Icon(
            isEdit ? Icons.edit_note : (isSubtask ? Icons.subdirectory_arrow_right : Icons.add_task),
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Text(
            isEdit ? 'Edit Task' : (isSubtask ? 'Create Subtask' : 'New Task'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text('Task Title *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Implement OAuth2 client login screen',
                    hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surfaceHover,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Task title is required';
                    return null;
                  },
                ),

                const SizedBox(height: 14),

                // Description
                Text('Description', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Detailed requirements, acceptance criteria, or links...',
                    hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surfaceHover,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),

                const SizedBox(height: 14),

                // Assignee & Priority in a Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Priority
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Priority', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _priority,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.surfaceHover,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                            items: TaskPriority.all.map((p) {
                              return DropdownMenuItem(
                                value: p,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(color: TaskPriority.color(p), shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(TaskPriority.label(p), style: const TextStyle(fontSize: 13)),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _priority = val);
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Assignee
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Assignee', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<int?>(
                            initialValue: _assignedToId,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.surfaceHover,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('Unassigned (Backlog)', style: TextStyle(fontSize: 13, color: Colors.grey)),
                              ),
                              ...assignees.map((a) {
                                return DropdownMenuItem<int?>(
                                  value: a.id,
                                  child: Text(
                                    a.name,
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }),
                            ],
                            onChanged: (val) {
                              setState(() => _assignedToId = val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Estimated Hours & Due Date Row
                Row(
                  children: [
                    // Estimated Hours
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Estimated Hours', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _estimatedHoursController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              hintText: 'e.g. 8.5',
                              suffixText: 'hrs',
                              hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted),
                              filled: true,
                              fillColor: AppColors.surfaceHover,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Due Date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Due Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: _pickDate,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceHover,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _dueDate != null
                                          ? _dueDate!.toIso8601String().split('T').first
                                          : 'Select deadline',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: _dueDate != null ? AppColors.textPrimary : AppColors.textMuted,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (_dueDate != null)
                                    InkWell(
                                      onTap: () => setState(() => _dueDate = null),
                                      child: Icon(Icons.close, size: 14, color: AppColors.textMuted),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.roseContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(fontSize: 12, color: AppColors.rose, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(isEdit ? 'Save Changes' : 'Create Task'),
        ),
      ],
    );
  }
}

class _AssigneeOption {
  const _AssigneeOption({required this.id, required this.name});
  final int id;
  final String name;
}
