import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/application/auth_controller.dart';
import '../application/holiday_controller.dart';
import '../data/holiday_models.dart';
import '../data/holiday_repository.dart';

class HolidaysPage extends ConsumerStatefulWidget {
  const HolidaysPage({super.key});

  @override
  ConsumerState<HolidaysPage> createState() => _HolidaysPageState();
}

class _HolidaysPageState extends ConsumerState<HolidaysPage> {
  int _selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;
    final holidaysAsync = ref.watch(holidaysProvider(_selectedYear));
    final canManage = user?.canManageHolidays ?? false;
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            if (isDesktop)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Holiday Calendar',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Official company and public holiday schedule for the year.',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  DropdownButton<int>(
                    value: _selectedYear,
                    items: [2025, 2026, 2027].map((y) {
                      return DropdownMenuItem<int>(value: y, child: Text('$y Calendar'));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedYear = val);
                    },
                  ),
                  if (canManage) ...[
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Holiday', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () => _openAddHolidayDialog(context),
                    ),
                  ],
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Holiday Calendar',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Official company and public holiday schedule for the year.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      DropdownButton<int>(
                        value: _selectedYear,
                        items: [2025, 2026, 2027].map((y) {
                          return DropdownMenuItem<int>(value: y, child: Text('$y Calendar'));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedYear = val);
                        },
                      ),
                      const Spacer(),
                      if (canManage)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Holiday', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          onPressed: () => _openAddHolidayDialog(context),
                        ),
                    ],
                  ),
                ],
              ),
            const SizedBox(height: 20),

            // Holidays List
            holidaysAsync.when(
              data: (holidays) {
                if (holidays.isEmpty) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Text('No holidays scheduled for this year.'),
                  ));
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: holidays.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) {
                    final h = holidays[idx];
                    return _HolidayCard(
                      holiday: h,
                      canManage: canManage,
                      onDelete: () async {
                        await ref.read(holidayRepositoryProvider).deleteHoliday(h.id);
                        ref.invalidate(holidaysProvider(_selectedYear));
                      },
                    );
                  },
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Center(child: Text('Error loading holidays: $e')),
            ),
          ],
        ),
      ),
    );
  }

  void _openAddHolidayDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final dateController = TextEditingController(text: '$_selectedYear-01-01');
    final descController = TextEditingController();
    String type = 'company';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Company Holiday'),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Holiday Name', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: dateController,
                      decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: type,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Holiday Type', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'national', child: Text('National Holiday')),
                        DropdownMenuItem(value: 'festival', child: Text('Festival Holiday')),
                        DropdownMenuItem(value: 'company', child: Text('Company Holiday')),
                        DropdownMenuItem(value: 'optional', child: Text('Optional / Floating')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => type = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: 'Description (optional)', border: OutlineInputBorder()),
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
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                try {
                  await ref.read(holidayRepositoryProvider).createHoliday({
                    'name': nameController.text.trim(),
                    'date': dateController.text.trim(),
                    'holiday_type': type,
                    if (descController.text.trim().isNotEmpty) 'description': descController.text.trim(),
                  });
                  ref.invalidate(holidaysProvider(_selectedYear));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Holiday added successfully!')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.rose),
                    );
                  }
                }
              },
              child: const Text('Add Holiday'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HolidayCard extends StatelessWidget {
  const _HolidayCard({
    required this.holiday,
    required this.canManage,
    required this.onDelete,
  });

  final HolidayItem holiday;
  final bool canManage;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    Color typeBg;
    Color typeFg;
    switch (holiday.holidayType) {
      case 'national':
        typeBg = AppColors.primaryContainer;
        typeFg = AppColors.primary;
        break;
      case 'festival':
        typeBg = AppColors.purpleContainer;
        typeFg = AppColors.purple;
        break;
      case 'optional':
        typeBg = AppColors.amberContainer;
        typeFg = AppColors.amber;
        break;
      default:
        typeBg = AppColors.emeraldContainer;
        typeFg = AppColors.emerald;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Date Block
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: holiday.isPast ? AppColors.surfaceHover : typeBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  _monthName(holiday.date),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: holiday.isPast ? AppColors.textSecondary : typeFg,
                  ),
                ),
                Text(
                  holiday.date.substring(8),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: holiday.isPast ? AppColors.textPrimary : typeFg,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Name and Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        holiday.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: holiday.isPast ? AppColors.textSecondary : AppColors.textPrimary,
                          decoration: holiday.isPast ? TextDecoration.lineThrough : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: typeBg, borderRadius: BorderRadius.circular(4)),
                      child: Text(
                        holiday.holidayType.toUpperCase(),
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: typeFg),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${holiday.dayOfWeek}${holiday.description != null ? " • ${holiday.description}" : ""}',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          if (canManage)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.rose),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }

  String _monthName(String date) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    final m = int.tryParse(date.substring(5, 7)) ?? 1;
    return months[m - 1];
  }
}
