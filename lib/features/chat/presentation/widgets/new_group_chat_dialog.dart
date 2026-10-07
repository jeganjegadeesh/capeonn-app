import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../employees/data/employee_model.dart';
import '../../application/chat_controller.dart';
import '../../data/chat_repository.dart';

class NewGroupChatDialog extends ConsumerStatefulWidget {
  const NewGroupChatDialog({super.key});

  @override
  ConsumerState<NewGroupChatDialog> createState() => _NewGroupChatDialogState();
}

class _NewGroupChatDialogState extends ConsumerState<NewGroupChatDialog> {
  final _titleController = TextEditingController();
  final _searchController = TextEditingController();
  final Set<int> _selectedIds = {};
  List<Employee> _employees = [];
  bool _isLoading = true;
  String? _error;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees([String? query]) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final chatRepo = ref.read(chatRepositoryProvider);
      final res = await chatRepo.getColleagues(
        search: query,
        perPage: 50,
      );

      final currentUserId = ref.read(authControllerProvider).value?.id;
      final filtered = res.items.where((e) => e.id != currentUserId).toList();

      if (mounted) {
        setState(() {
          _employees = filtered;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createGroup() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      AppToast.error(context, 'Please enter a group title');
      return;
    }

    if (_selectedIds.isEmpty) {
      AppToast.error(context, 'Please select at least one participant');
      return;
    }

    setState(() => _isCreating = true);

    try {
      final chatRepo = ref.read(chatRepositoryProvider);
      final conv = await chatRepo.createGroupConversation(title, _selectedIds.toList());

      ref.invalidate(conversationsListProvider);

      if (mounted) {
        Navigator.pop(context);
        context.push('/chat/${conv.id}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        AppToast.error(context, 'Failed to create group: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Create Group Chat',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Group Title *',
                  hintText: 'e.g. Design Team, Launch Squad',
                  prefixIcon: const Icon(Icons.group_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Members (${_selectedIds.length} selected)',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  if (_selectedIds.isNotEmpty)
                    TextButton(
                      onPressed: () => setState(() => _selectedIds.clear()),
                      child: const Text('Clear', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Filter members...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  filled: true,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) => _loadEmployees(val.trim()),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _buildMemberList(),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _isCreating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check),
                  label: Text(_isCreating ? 'Creating Group...' : 'Create Group Chat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isCreating ? null : _createGroup,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text('Failed to load members', style: TextStyle(color: AppColors.rose)),
      );
    }

    if (_employees.isEmpty) {
      return const Center(
        child: Text('No colleagues found', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      itemCount: _employees.length,
      itemBuilder: (context, index) {
        final emp = _employees[index];
        final isSelected = _selectedIds.contains(emp.id);

        return CheckboxListTile(
          value: isSelected,
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          title: Text(emp.name, style: const TextStyle(fontWeight: FontWeight.w500)),
          subtitle: emp.departmentName != '—' ? Text(emp.departmentName) : null,
          secondary: CircleAvatar(
            radius: 18,
            backgroundColor: isSelected
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              emp.name.isNotEmpty ? emp.name[0].toUpperCase() : 'U',
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          onChanged: (checked) {
            setState(() {
              if (checked == true) {
                _selectedIds.add(emp.id);
              } else {
                _selectedIds.remove(emp.id);
              }
            });
          },
        );
      },
    );
  }
}
