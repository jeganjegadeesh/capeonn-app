import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../organization/application/organization_controller.dart';
import '../../application/report_controller.dart';

class ReportFilterBar extends ConsumerWidget {
  final VoidCallback? onExportPressed;

  const ReportFilterBar({
    super.key,
    this.onExportPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(reportFilterProvider);
    final departmentsAsync = ref.watch(departmentsListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final presets = [
      {'key': 'today', 'label': 'Today'},
      {'key': 'this_week', 'label': 'This Week'},
      {'key': 'this_month', 'label': 'This Month'},
      {'key': 'this_quarter', 'label': 'Quarter'},
      {'key': 'all_time', 'label': 'All Time'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131C2E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Presets row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final p in presets) ...[
                  Builder(builder: (context) {
                    final isSelected = filter.preset == p['key'] && filter.startDate == null;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InkWell(
                        onTap: () {
                          ref.read(reportFilterProvider.notifier).setFilter(
                            filter.copyWith(
                              preset: p['key']!,
                              clearDates: true,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            p['label']!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
                // Custom Date Range
                InkWell(
                  onTap: () async {
                    final now = DateTime.now();
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(now.year - 3),
                      lastDate: DateTime(now.year + 2),
                      initialDateRange: filter.startDate != null && filter.endDate != null
                          ? DateTimeRange(
                              start: DateTime.parse(filter.startDate!),
                              end: DateTime.parse(filter.endDate!),
                            )
                          : null,
                    );

                    if (picked != null) {
                      ref.read(reportFilterProvider.notifier).setFilter(
                        filter.copyWith(
                          preset: '',
                          startDate: picked.start.toIso8601String().substring(0, 10),
                          endDate: picked.end.toIso8601String().substring(0, 10),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: filter.startDate != null
                          ? AppColors.primary
                          : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.date_range_outlined,
                          size: 14,
                          color: filter.startDate != null
                              ? Colors.white
                              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          filter.startDate != null
                              ? '${filter.startDate} - ${filter.endDate}'
                              : 'Custom Range',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: filter.startDate != null ? FontWeight.bold : FontWeight.w500,
                            color: filter.startDate != null
                                ? Colors.white
                                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filters and Export
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Department Selector
              departmentsAsync.when(
                data: (depts) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int?>(
                        value: filter.departmentId,
                        hint: Text(
                          'All Departments',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        isDense: true,
                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('All Departments', style: TextStyle(fontSize: 12)),
                          ),
                          ...depts.map((d) => DropdownMenuItem<int?>(
                                value: d.id,
                                child: Text(d.name, style: const TextStyle(fontSize: 12)),
                              )),
                        ],
                        onChanged: (val) {
                          ref.read(reportFilterProvider.notifier).setFilter(
                            filter.copyWith(departmentId: val, clearDepartment: val == null),
                          );
                        },
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (err, _) => const SizedBox.shrink(),
              ),

              const SizedBox(width: 10),

              // Export CSV Button
              ElevatedButton.icon(
                onPressed: onExportPressed,
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text('Export CSV', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
