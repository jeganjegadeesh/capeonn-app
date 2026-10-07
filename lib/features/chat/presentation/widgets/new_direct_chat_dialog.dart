import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../employees/data/employee_model.dart';
import '../../application/chat_controller.dart';
import '../../data/chat_repository.dart';

class NewDirectChatDialog extends ConsumerStatefulWidget {
  const NewDirectChatDialog({super.key});

  @override
  ConsumerState<NewDirectChatDialog> createState() => _NewDirectChatDialogState();
}

class _NewDirectChatDialogState extends ConsumerState<NewDirectChatDialog> {
  final _searchController = TextEditingController();
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
      // Filter out self
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

  Future<void> _startChatWith(Employee employee) async {
    if (_isCreating) return;
    setState(() => _isCreating = true);

    try {
      final chatRepo = ref.read(chatRepositoryProvider);
      final conv = await chatRepo.getDirectConversation(employee.id);

      ref.invalidate(conversationsListProvider);

      if (mounted) {
        Navigator.pop(context);
        context.push('/chat/${conv.id}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        AppToast.error(context, 'Failed to start chat: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'New Direct Message',
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
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search colleagues...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _loadEmployees();
                          },
                        )
                      : null,
                  filled: true,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) {
                  _loadEmployees(val.trim());
                },
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _buildBody(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Failed to load colleagues', style: TextStyle(color: AppColors.rose)),
            const SizedBox(height: 8),
            TextButton(onPressed: () => _loadEmployees(), child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_employees.isEmpty) {
      return const Center(
        child: Text('No colleagues found', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.separated(
      itemCount: _employees.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final emp = _employees[index];
        final roleSlug = emp.roleSlug.isNotEmpty ? emp.roleSlug : 'employee';
        final (pillBg, pillFg) = AppColors.rolePillColors(roleSlug);

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          leading: CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: Text(
              emp.name.isNotEmpty ? emp.name[0].toUpperCase() : 'U',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ),
          title: Text(emp.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: emp.departmentName != '—'
              ? Text(emp.departmentName, style: const TextStyle(fontSize: 12))
              : null,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: pillBg, borderRadius: BorderRadius.circular(12)),
            child: Text(
              emp.roleName,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: pillFg),
            ),
          ),
          onTap: _isCreating ? null : () => _startChatWith(emp),
        );
      },
    );
  }
}
