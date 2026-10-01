import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/application/auth_controller.dart';
import '../application/employee_controller.dart';
import '../application/employee_details_controller.dart';
import '../data/employee_details_repository.dart';
import '../data/employee_model.dart';
import 'employee_form_dialog.dart';

class EmployeeDetailPage extends ConsumerStatefulWidget {
  const EmployeeDetailPage({super.key, required this.employeeId});

  final int employeeId;

  @override
  ConsumerState<EmployeeDetailPage> createState() => _EmployeeDetailPageState();
}

class _EmployeeDetailPageState extends ConsumerState<EmployeeDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;
    final employeeAsync = ref.watch(employeeDetailProvider(widget.employeeId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: employeeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.rose),
              const SizedBox(height: 12),
              Text(
                err is ApiException ? err.displayMessage : 'Failed to load employee details',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => ref.invalidate(employeeDetailProvider(widget.employeeId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (emp) {
          final (roleBg, roleFg) = AppColors.rolePillColors(emp.roleSlug);
          final (statusBg, statusFg) = AppColors.statusPillColors(emp.isActive);
          final isMobile = MediaQuery.sizeOf(context).width < 768;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header Card
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(isMobile ? 16 : 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: isMobile ? 28 : 36,
                                  backgroundColor: roleBg,
                                  child: Text(
                                    emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '?',
                                    style: TextStyle(
                                      color: roleFg,
                                      fontSize: isMobile ? 22 : 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          Text(
                                            emp.name,
                                            style: TextStyle(
                                              fontSize: isMobile ? 18 : 22,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: statusBg,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              emp.isActive ? 'Active' : 'Inactive',
                                              style: TextStyle(color: statusFg, fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(emp.email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(color: roleBg, borderRadius: BorderRadius.circular(6)),
                                            child: Text(
                                              emp.roleName,
                                              style: TextStyle(color: roleFg, fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          if (emp.employeeCode != null)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppColors.background,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: AppColors.border),
                                              ),
                                              child: Text(emp.employeeCode!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (user?.canManageEmployees == true)
                                  IconButton(
                                    tooltip: 'Edit Organization Setup',
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () => showDialog(context: context, builder: (ctx) => EmployeeFormDialog(employee: emp)),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tabs Header
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicatorColor: AppColors.primary,
                        labelColor: AppColors.primary,
                        unselectedLabelColor: AppColors.textSecondary,
                        tabs: const [
                          Tab(text: 'Profile & Skills'),
                          Tab(text: 'Documents'),
                          Tab(text: 'Career History'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tab View
                    SizedBox(
                      height: 520,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _OverviewTab(emp: emp, canEdit: (user?.id == emp.id) || (user?.canManageEmployees ?? false)),
                          _DocumentsTab(employeeId: emp.id, canManage: user?.canManageDocuments ?? false),
                          _HistoryTab(employeeId: emp.id, canManage: user?.canManageEmployees ?? false),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab({required this.emp, required this.canEdit});

  final Employee emp;
  final bool canEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Position & Organization
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.border)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Position & Organization', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),
                  _InfoRow('Department', emp.departmentName),
                  const SizedBox(height: 10),
                  _InfoRow('Designation', emp.designationName),
                  const SizedBox(height: 10),
                  _InfoRow('Reports To', emp.reportsToName),
                  const SizedBox(height: 10),
                  _InfoRow('Employment Type', (emp.employmentType ?? 'full_time').replaceAll('_', ' ').toUpperCase()),
                  const SizedBox(height: 10),
                  _InfoRow('Date Joined', emp.joinedOn ?? '—'),
                  const SizedBox(height: 10),
                  _InfoRow('Probation End', emp.probationEndDate ?? 'Confirmed'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Personal & Emergency Contact Details
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.border)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Personal & Emergency Contact', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      if (canEdit)
                        TextButton.icon(
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Edit Details'),
                          onPressed: () => _openEditProfileDialog(context, ref),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _InfoRow('Contact Phone', emp.phone ?? 'Not provided'),
                  const SizedBox(height: 10),
                  _InfoRow('Date of Birth', emp.dob ?? '—'),
                  const SizedBox(height: 10),
                  _InfoRow('Gender', emp.gender != null ? emp.gender!.toUpperCase() : '—'),
                  const SizedBox(height: 10),
                  _InfoRow('Address', emp.address ?? 'Not provided'),
                  const SizedBox(height: 10),
                  _InfoRow('Emergency Contact', '${emp.emergencyContactName ?? "—"} (${emp.emergencyContactPhone ?? "—"})'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Skills & Certifications
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.border)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Skills & Competencies', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (emp.skills.isEmpty)
                    Text('No skills added yet.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: emp.skills.map((s) {
                        return Chip(
                          backgroundColor: AppColors.primaryContainer,
                          label: Text(s, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 16),
                  const Text('Certifications', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (emp.certifications.isEmpty)
                    Text('No certifications logged.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))
                  else
                    ...emp.certifications.map((c) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.verified, color: AppColors.emerald, size: 20),
                          title: Text(c['name']?.toString() ?? 'Certificate', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Issuer: ${c["issuer"] ?? "—"} • Date: ${c["date"] ?? "—"}'),
                        )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openEditProfileDialog(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final phoneController = TextEditingController(text: emp.phone ?? '');
    final dobController = TextEditingController(text: emp.dob ?? '');
    final addressController = TextEditingController(text: emp.address ?? '');
    final emNameController = TextEditingController(text: emp.emergencyContactName ?? '');
    final emPhoneController = TextEditingController(text: emp.emergencyContactPhone ?? '');
    final skillsController = TextEditingController(text: emp.skills.join(', '));
    String gender = emp.gender ?? 'prefer_not_to_say';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Personal & Contact Info'),
          content: SizedBox(
            width: 440,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder())),
                    const SizedBox(height: 10),
                    TextFormField(controller: dobController, decoration: const InputDecoration(labelText: 'DOB (YYYY-MM-DD)', border: OutlineInputBorder())),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: gender,
                      decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'male', child: Text('Male')),
                        DropdownMenuItem(value: 'female', child: Text('Female')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                        DropdownMenuItem(value: 'prefer_not_to_say', child: Text('Prefer not to say')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => gender = val);
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(controller: addressController, decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder())),
                    const SizedBox(height: 10),
                    TextFormField(controller: emNameController, decoration: const InputDecoration(labelText: 'Emergency Contact Name', border: OutlineInputBorder())),
                    const SizedBox(height: 10),
                    TextFormField(controller: emPhoneController, decoration: const InputDecoration(labelText: 'Emergency Contact Phone', border: OutlineInputBorder())),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: skillsController,
                      decoration: const InputDecoration(labelText: 'Skills (comma-separated)', hintText: 'Flutter, Dart, SQL', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  final skillsList = skillsController.text
                      .split(',')
                      .map((s) => s.trim())
                      .where((s) => s.isNotEmpty)
                      .toList();

                  await ref.read(employeeDetailsRepositoryProvider).updateProfile(emp.id, {
                    'phone': phoneController.text.trim(),
                    'dob': dobController.text.trim().isEmpty ? null : dobController.text.trim(),
                    'gender': gender,
                    'address': addressController.text.trim(),
                    'emergency_contact_name': emNameController.text.trim(),
                    'emergency_contact_phone': emPhoneController.text.trim(),
                    'skills': skillsList,
                  });
                  ref.invalidate(employeeDetailProvider(emp.id));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!')));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e'), backgroundColor: AppColors.rose));
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentsTab extends ConsumerWidget {
  const _DocumentsTab({required this.employeeId, required this.canManage});

  final int employeeId;
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(employeeDocumentsProvider(employeeId));

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Official Documents & Records', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              icon: const Icon(Icons.upload_file, size: 16),
              label: const Text('Upload Document'),
              onPressed: () => _openUploadDocDialog(context, ref),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: docsAsync.when(
            data: (docs) {
              if (docs.isEmpty) {
                return const Center(child: Text('No documents uploaded for this employee.'));
              }

              return ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, idx) {
                  final d = docs[idx];
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: AppColors.border)),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.description_outlined, color: AppColors.primary),
                      ),
                      title: Text(d.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${d.documentType.toUpperCase()} • ${d.fileName} (${d.fileSizeFormatted})'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.rose, size: 20),
                        onPressed: () async {
                          await ref.read(employeeDetailsRepositoryProvider).deleteDocument(d.id);
                          ref.invalidate(employeeDocumentsProvider(employeeId));
                        },
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error loading documents: $e')),
          ),
        ),
      ],
    );
  }

  void _openUploadDocDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    String type = 'resume';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Employee Document'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Document Title', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'resume', child: Text('Resume / CV')),
                  DropdownMenuItem(value: 'id_proof', child: Text('Government ID Proof')),
                  DropdownMenuItem(value: 'contract', child: Text('Offer / Employment Contract')),
                  DropdownMenuItem(value: 'certificate', child: Text('Degree / Certification')),
                  DropdownMenuItem(value: 'other', child: Text('Other Document')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => type = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              onPressed: () async {
                if (titleController.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await ref.read(employeeDetailsRepositoryProvider).uploadDocument(employeeId, {
                    'title': titleController.text.trim(),
                    'document_type': type,
                    'file_path': 'documents/$type.pdf',
                    'file_name': '${titleController.text.trim().toLowerCase().replaceAll(" ", "_")}.pdf',
                    'file_size': 2048,
                    'mime_type': 'application/pdf',
                  });
                  ref.invalidate(employeeDocumentsProvider(employeeId));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document uploaded!')));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e'), backgroundColor: AppColors.rose));
                  }
                }
              },
              child: const Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab({required this.employeeId, required this.canManage});

  final int employeeId;
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historiesAsync = ref.watch(employeeHistoriesProvider(employeeId));

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Career Milestones & Audit Trail', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            if (canManage)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Milestone'),
                onPressed: () => _openAddHistoryDialog(context, ref),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: historiesAsync.when(
            data: (histories) {
              if (histories.isEmpty) {
                return const Center(child: Text('No career events recorded yet.'));
              }

              return ListView.separated(
                itemCount: histories.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, idx) {
                  final h = histories[idx];
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: AppColors.border)),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.emeraldContainer, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.timeline, color: AppColors.emerald),
                      ),
                      title: Text(h.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${h.effectiveDate} • ${h.description ?? h.eventType}'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                        child: Text(h.eventType.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error loading history: $e')),
          ),
        ),
      ],
    );
  }

  void _openAddHistoryDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final dateController = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
    String eventType = 'promotion';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Career Milestone'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title', hintText: 'e.g. Promoted to Senior Developer', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: dateController, decoration: const InputDecoration(labelText: 'Effective Date (YYYY-MM-DD)', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: eventType,
                decoration: const InputDecoration(labelText: 'Event Type', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'promotion', child: Text('Promotion')),
                  DropdownMenuItem(value: 'designation_change', child: Text('Designation Change')),
                  DropdownMenuItem(value: 'department_change', child: Text('Department Transfer')),
                  DropdownMenuItem(value: 'role_change', child: Text('Role Change')),
                  DropdownMenuItem(value: 'note', child: Text('General Note')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => eventType = val);
                },
              ),
              const SizedBox(height: 10),
              TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description / Remarks', border: OutlineInputBorder())),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              onPressed: () async {
                if (titleController.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await ref.read(employeeDetailsRepositoryProvider).addHistory(employeeId, {
                    'title': titleController.text.trim(),
                    'effective_date': dateController.text.trim(),
                    'event_type': eventType,
                    'description': descController.text.trim().isEmpty ? null : descController.text.trim(),
                  });
                  ref.invalidate(employeeHistoriesProvider(employeeId));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Milestone recorded!')));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.rose));
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 550;
    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 180,
          child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ),
      ],
    );
  }
}
