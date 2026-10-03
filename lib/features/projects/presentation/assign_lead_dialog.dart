import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../employees/application/employee_controller.dart';
import '../application/projects_controller.dart';

class AssignLeadDialog extends ConsumerStatefulWidget {
  const AssignLeadDialog({
    super.key,
    required this.projectId,
    this.currentLeadId,
  });

  final int projectId;
  final int? currentLeadId;

  @override
  ConsumerState<AssignLeadDialog> createState() => _AssignLeadDialogState();
}

class _AssignLeadDialogState extends ConsumerState<AssignLeadDialog> {
  int? _selectedLeadId;
  final _reasonCtrl = TextEditingController();
  bool _keepAsMember = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedLeadId = widget.currentLeadId;
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await ref.read(projectsControllerProvider).assignLead(
            widget.projectId,
            _selectedLeadId,
            reason: _reasonCtrl.text.trim().isNotEmpty ? _reasonCtrl.text.trim() : null,
            keepAsMember: _keepAsMember,
          );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Team Lead updated successfully'),
            backgroundColor: AppColors.emerald,
          ),
        );
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
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.person_pin_outlined, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Assign Team Lead',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Select an employee with Team Lead role',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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

              supervisorsAsync.when(
                data: (supervisors) {
                  final teamLeads = supervisors.where((s) => s.role?.slug == 'team_lead' || s.id == widget.currentLeadId).toList();
                  return DropdownButtonFormField<int?>(
                    initialValue: _selectedLeadId,
                    decoration: const InputDecoration(
                      labelText: 'Team Lead',
                      hintText: 'Select active Team Lead',
                      prefixIcon: Icon(Icons.manage_accounts_outlined, size: 20),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Unassigned (No Team Lead)'),
                      ),
                      ...teamLeads.map((s) {
                        return DropdownMenuItem<int?>(
                          value: s.id,
                          child: Text('${s.name} (${s.role?.name ?? 'Team Lead'})'),
                        );
                      }),
                    ],
                    onChanged: (val) => setState(() => _selectedLeadId = val),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const Text('Failed to load eligible leads'),
              ),
              const SizedBox(height: 16),

              // Reassignment Reason
              TextField(
                controller: _reasonCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Reason for Assignment / Handover (Optional)',
                  hintText: 'e.g. Lead rotated or assigned for Phase 4 launch',
                  prefixIcon: Icon(Icons.note_alt_outlined, size: 20),
                ),
              ),

              if (widget.currentLeadId != null && _selectedLeadId != widget.currentLeadId) ...[
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _keepAsMember,
                  title: const Text('Keep previous Team Lead as project member', style: TextStyle(fontSize: 13)),
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (val) => setState(() => _keepAsMember = val ?? true),
                ),
              ],

              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _submit,
                    child: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Save Team Lead'),
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
