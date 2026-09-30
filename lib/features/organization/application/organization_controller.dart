import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/company_model.dart';
import '../data/department_model.dart';
import '../data/designation_model.dart';
import '../data/hierarchy_model.dart';
import '../data/organization_repository.dart';

// --- Company State ---

final companyProvider = AsyncNotifierProvider<CompanyNotifier, Company>(CompanyNotifier.new);

class CompanyNotifier extends AsyncNotifier<Company> {
  @override
  Future<Company> build() {
    return ref.watch(organizationRepositoryProvider).getCompany();
  }

  Future<void> updateCompany(Map<String, dynamic> data) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return ref.read(organizationRepositoryProvider).updateCompany(data);
    });
  }

  void refresh() {
    ref.invalidateSelf();
  }
}

// --- Departments Filter & State ---

class DepartmentsFilter {
  const DepartmentsFilter({this.search = '', this.isActive});
  final String search;
  final bool? isActive;

  DepartmentsFilter copyWith({String? search, bool? Function()? isActive}) {
    return DepartmentsFilter(
      search: search ?? this.search,
      isActive: isActive != null ? isActive() : this.isActive,
    );
  }
}

final departmentsFilterProvider =
    NotifierProvider<DepartmentsFilterNotifier, DepartmentsFilter>(DepartmentsFilterNotifier.new);

class DepartmentsFilterNotifier extends Notifier<DepartmentsFilter> {
  @override
  DepartmentsFilter build() => const DepartmentsFilter();

  void setFilter(DepartmentsFilter filter) => state = filter;
  void setSearch(String search) => state = state.copyWith(search: search);
  void setIsActive(bool? Function() isActive) => state = state.copyWith(isActive: isActive);
}

final departmentsListProvider = FutureProvider<List<Department>>((ref) async {
  final filter = ref.watch(departmentsFilterProvider);
  return ref.watch(organizationRepositoryProvider).getDepartments(
    search: filter.search,
    isActive: filter.isActive,
  );
});

// --- Designations Filter & State ---

class DesignationsFilter {
  const DesignationsFilter({this.search = '', this.isActive});
  final String search;
  final bool? isActive;

  DesignationsFilter copyWith({String? search, bool? Function()? isActive}) {
    return DesignationsFilter(
      search: search ?? this.search,
      isActive: isActive != null ? isActive() : this.isActive,
    );
  }
}

final designationsFilterProvider =
    NotifierProvider<DesignationsFilterNotifier, DesignationsFilter>(DesignationsFilterNotifier.new);

class DesignationsFilterNotifier extends Notifier<DesignationsFilter> {
  @override
  DesignationsFilter build() => const DesignationsFilter();

  void setFilter(DesignationsFilter filter) => state = filter;
  void setSearch(String search) => state = state.copyWith(search: search);
  void setIsActive(bool? Function() isActive) => state = state.copyWith(isActive: isActive);
}

final designationsListProvider = FutureProvider<List<Designation>>((ref) async {
  final filter = ref.watch(designationsFilterProvider);
  return ref.watch(organizationRepositoryProvider).getDesignations(
    search: filter.search,
    isActive: filter.isActive,
  );
});

// --- Hierarchy State ---

final hierarchyIncludeInactiveProvider =
    NotifierProvider<HierarchyIncludeInactiveNotifier, bool>(HierarchyIncludeInactiveNotifier.new);

class HierarchyIncludeInactiveNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle(bool value) => state = value;
}

final hierarchyListProvider = FutureProvider<List<HierarchyNode>>((ref) async {
  final includeInactive = ref.watch(hierarchyIncludeInactiveProvider);
  return ref.watch(organizationRepositoryProvider).getHierarchy(includeInactive: includeInactive);
});
