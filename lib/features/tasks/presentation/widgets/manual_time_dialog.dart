import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/task_models.dart';
import '../../data/task_repository.dart';
import '../../application/tasks_providers.dart';

class ManualTimeDialog extends ConsumerStatefulWidget {
  const ManualTimeDialog({
    super.key,
    required this.task,
  });

  final TaskItem task;

  @override
  ConsumerState<ManualTimeDialog> createState() => _ManualTimeDialogState();
}

class _ManualTimeDialogState extends ConsumerState<ManualTimeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 11, minute: 30);

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  double get _calculatedHours {
    final startMins = _startTime.hour * 60 + _startTime.minute;
    final endMins = _endTime.hour * 60 + _endTime.minute;
    final diff = endMins - startMins;
    return diff > 0 ? (diff / 60.0) : 0.0;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_calculatedHours <= 0) {
      setState(() => _errorMessage = 'End time must be after start time.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    final endDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    final data = {
      'started_at': startDateTime.toIso8601String(),
      'ended_at': endDateTime.toIso8601String(),
      'description': _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
    };

    try {
      final repo = ref.read(taskRepositoryProvider);
      final entry = await repo.storeManualTime(widget.task.id, data);

      ref.invalidate(taskDetailProvider(widget.task.id));
      ref.invalidate(projectTasksProvider(widget.task.projectId));
      ref.invalidate(myTasksProvider);

      if (mounted) {
        Navigator.of(context).pop(entry);
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
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.surface,
      title: Row(
        children: [
          Icon(Icons.more_time, color: AppColors.primary),
          const SizedBox(width: 8),
          const Text('Log Manual Time', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
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
                const SizedBox(height: 16),

                // Date Picker
                Text('Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 90)),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
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
                        Text(
                          _selectedDate.toIso8601String().split('T').first,
                          style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Start & End Time Pickers
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Start Time', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(context: context, initialTime: _startTime);
                              if (picked != null) setState(() => _startTime = picked);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceHover,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.schedule, size: 16, color: AppColors.textSecondary),
                                  const SizedBox(width: 8),
                                  Text(_startTime.format(context), style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('End Time', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(context: context, initialTime: _endTime);
                              if (picked != null) setState(() => _endTime = picked);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceHover,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.schedule, size: 16, color: AppColors.textSecondary),
                                  const SizedBox(width: 8),
                                  Text(_endTime.format(context), style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Calculated Duration Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _calculatedHours > 0 ? AppColors.primaryContainer : AppColors.roseContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Duration to log:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      Text(
                        '${_calculatedHours.toStringAsFixed(2)} hours',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _calculatedHours > 0 ? AppColors.primary : AppColors.rose,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Description
                Text('Work Description', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _descController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'What did you work on?',
                    hintStyle: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surfaceHover,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(_errorMessage!, style: TextStyle(fontSize: 12, color: AppColors.rose, fontWeight: FontWeight.w500)),
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
          ),
          child: _isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Log Hours'),
        ),
      ],
    );
  }
}
