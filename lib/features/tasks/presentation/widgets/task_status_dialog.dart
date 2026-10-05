import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/api_exception.dart';
import '../../../auth/application/auth_controller.dart';
import '../../data/task_models.dart';
import '../../data/task_repository.dart';
import '../../application/tasks_providers.dart';


class TaskStatusDialog extends ConsumerStatefulWidget {
  const TaskStatusDialog({
    super.key,
    required this.task,
  });

  final TaskItem task;

  @override
  ConsumerState<TaskStatusDialog> createState() => _TaskStatusDialogState();
}

class _TaskStatusDialogState extends ConsumerState<TaskStatusDialog> {
  String? _selectedStatus;
  final _reasonController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  bool _isReasonRequired(String targetStatus) {
    if (targetStatus == TaskStatus.changesRequired) return true;
    if (widget.task.status == TaskStatus.completed && targetStatus == TaskStatus.inProgress) return true;
    return false;
  }

  String _actionLabel(String fromStatus, String toStatus) {
    if (fromStatus == TaskStatus.inProgress && toStatus == TaskStatus.review) {
      return 'Submit for Review';
    }
    if (fromStatus == TaskStatus.review && toStatus == TaskStatus.completed) {
      return 'Approve & Complete';
    }
    if (fromStatus == TaskStatus.review && toStatus == TaskStatus.changesRequired) {
      return 'Request Changes';
    }
    if (fromStatus == TaskStatus.completed && toStatus == TaskStatus.inProgress) {
      return 'Reopen Task';
    }
    if (fromStatus == TaskStatus.changesRequired && toStatus == TaskStatus.inProgress) {
      return 'Resume Working';
    }
    if (fromStatus == TaskStatus.assigned && toStatus == TaskStatus.inProgress) {
      return 'Start Working';
    }
    return 'Move to ${TaskStatus.label(toStatus)}';
  }

  Future<void> _submit(String targetStatus) async {
    if (targetStatus == widget.task.status) {
      Navigator.of(context).pop();
      return;
    }

    if (_isReasonRequired(targetStatus) && _reasonController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'A reason is required when ${_actionLabel(widget.task.status, targetStatus).toLowerCase()}.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(taskRepositoryProvider);
      final updated = await repo.updateTaskStatus(
        widget.task.id,
        targetStatus,
        reason: _reasonController.text.trim().isNotEmpty ? _reasonController.text.trim() : null,
      );

      // Invalidate relevant providers
      ref.invalidate(projectTasksProvider(widget.task.projectId));
      ref.invalidate(myTasksProvider);
      ref.invalidate(myWorkTodayProvider);
      ref.invalidate(taskDetailProvider(widget.task.id));
      ref.read(activeTimerProvider.notifier).checkActiveTimer();

      if (mounted) {
        Navigator.of(context).pop(updated);
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
    final currentUser = ref.watch(authControllerProvider).value;
    final isAssignee = widget.task.assignedTo?.id != null && widget.task.assignedTo?.id == currentUser?.id;
    final canManage = (currentUser?.isAdmin == true) ||
        (currentUser?.isManager == true) ||
        (currentUser?.isTeamLead == true);

    final allowed = TaskStatus.allowedTransitionsFor(
      currentStatus: widget.task.status,
      isAssignee: isAssignee,
      canManage: canManage,
    );

    if (_selectedStatus == null || !allowed.contains(_selectedStatus)) {
      _selectedStatus = allowed.isNotEmpty ? allowed.first : widget.task.status;
    }

    final reasonRequired = _isReasonRequired(_selectedStatus!);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.surface,
      title: Row(
        children: [
          Icon(Icons.swap_horiz, color: AppColors.primary),
          const SizedBox(width: 8),
          const Text('Update Task Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.task.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Current Status: ', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: widget.task.statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: widget.task.statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    widget.task.statusDisplay,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: widget.task.statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (allowed.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.amberContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.task.status == TaskStatus.review && isAssignee && !canManage
                      ? 'This task is in review. Only a Team Lead or Manager can review and approve it.'
                      : widget.task.status == TaskStatus.review && isAssignee && canManage
                          ? 'This task is in review. You are the assignee; another Team Lead or Manager must approve it.'
                          : 'No further status transitions are available for your role.',
                  style: TextStyle(fontSize: 12, color: AppColors.amber),
                ),
              )
            else ...[
              Text(
                'Available Actions:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: allowed.map((status) {
                  final isSelected = _selectedStatus == status;
                  final color = TaskStatus.color(status);
                  final actionText = _actionLabel(widget.task.status, status);

                  return ChoiceChip(
                    label: Text(actionText),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _selectedStatus = status;
                          _errorMessage = null;
                        });
                      }
                    },
                    selectedColor: color.withValues(alpha: 0.2),
                    backgroundColor: AppColors.surfaceHover,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? color : AppColors.textSecondary,
                    ),
                    side: BorderSide(
                      color: isSelected ? color : AppColors.border,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Reason / Notes:',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  if (reasonRequired) ...[
                    const SizedBox(width: 4),
                    Text(
                      '* (Required)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.rose),
                    ),
                  ] else ...[
                    const SizedBox(width: 4),
                    Text(
                      '(optional)',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _reasonController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: reasonRequired
                      ? 'Please specify a reason for this status change...'
                      : 'Add an audit explanation for this status change...',
                  hintStyle: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surfaceHover,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(fontSize: 12, color: AppColors.rose, fontWeight: FontWeight.w500),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
        ),
        if (allowed.isNotEmpty && _selectedStatus != null)
          ElevatedButton(
            onPressed: _isLoading ? null : () => _submit(_selectedStatus!),
            style: ElevatedButton.styleFrom(
              backgroundColor: TaskStatus.color(_selectedStatus!),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(_actionLabel(widget.task.status, _selectedStatus!)),
          ),
      ],
    );
  }
}
