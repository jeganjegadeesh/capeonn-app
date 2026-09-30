import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/employee_model.dart';
import '../data/employee_repository.dart';
import '../data/role_model.dart';

class EmployeesFilter {
  const EmployeesFilter({
    this.search = '',
    this.departmentId,
    this.reportsToId,
    this.role,
    this.isActive,
    this.page = 1,
    this.perPage = 15,
  });

  final String search;
  final int? departmentId;
  final int? reportsToId;
  final String? role;
  final bool? isActive;
  final int page;
  final int perPage;

  EmployeesFilter copyWith({
    String? search,
    int? Function()? departmentId,
    int? Function()? reportsToId,
    String? Function()? role,
    bool? Function()? isActive,
    int? page,
    int? perPage,
  }) {
    return EmployeesFilter(
      search: search ?? this.search,
      departmentId: departmentId != null ? departmentId() : this.departmentId,
      reportsToId: reportsToId != null ? reportsToId() : this.reportsToId,
      role: role != null ? role() : this.role,
      isActive: isActive != null ? isActive() : this.isActive,
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
    );
  }
}

final employeesFilterProvider =
    NotifierProvider<EmployeesFilterNotifier, EmployeesFilter>(EmployeesFilterNotifier.new);

class EmployeesFilterNotifier extends Notifier<EmployeesFilter> {
  @override
  EmployeesFilter build() => const EmployeesFilter();

  void setFilter(EmployeesFilter filter) => state = filter;
  void update(EmployeesFilter Function(EmployeesFilter current) updater) => state = updater(state);
}

final employeesListProvider = FutureProvider<PaginatedEmployees>((ref) async {
  final filter = ref.watch(employeesFilterProvider);
  return ref.watch(employeeRepositoryProvider).getEmployees(
    search: filter.search,
    departmentId: filter.departmentId,
    reportsToId: filter.reportsToId,
    role: filter.role,
    isActive: filter.isActive,
    page: filter.page,
    perPage: filter.perPage,
  );
});

final assignableRolesProvider = FutureProvider<List<RoleItem>>((ref) async {
  return ref.watch(employeeRepositoryProvider).getAssignableRoles();
});

/// Fetches active employees suitable to be chosen as a manager / team lead / supervisor
final potentialSupervisorsProvider = FutureProvider<List<Employee>>((ref) async {
  final res = await ref.watch(employeeRepositoryProvider).getEmployees(
    isActive: true,
    perPage: 100,
  );
  return res.items;
});

final employeeDetailProvider = FutureProvider.family<Employee, int>((ref, id) async {
  return ref.watch(employeeRepositoryProvider).getEmployee(id);
});
