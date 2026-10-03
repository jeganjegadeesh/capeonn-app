import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/project_models.dart';
import '../data/project_repository.dart';

class ProjectsFilter {
  const ProjectsFilter({
    this.search = '',
    this.departmentId,
    this.status,
    this.priority,
    this.teamLeadId,
    this.myProjects = false,
    this.isOverdue = false,
    this.includeArchived = false,
    this.page = 1,
    this.perPage = 15,
  });

  final String search;
  final int? departmentId;
  final String? status;
  final String? priority;
  final int? teamLeadId;
  final bool myProjects;
  final bool isOverdue;
  final bool includeArchived;
  final int page;
  final int perPage;

  ProjectsFilter copyWith({
    String? search,
    int? Function()? departmentId,
    String? Function()? status,
    String? Function()? priority,
    int? Function()? teamLeadId,
    bool? myProjects,
    bool? isOverdue,
    bool? includeArchived,
    int? page,
    int? perPage,
  }) {
    return ProjectsFilter(
      search: search ?? this.search,
      departmentId: departmentId != null ? departmentId() : this.departmentId,
      status: status != null ? status() : this.status,
      priority: priority != null ? priority() : this.priority,
      teamLeadId: teamLeadId != null ? teamLeadId() : this.teamLeadId,
      myProjects: myProjects ?? this.myProjects,
      isOverdue: isOverdue ?? this.isOverdue,
      includeArchived: includeArchived ?? this.includeArchived,
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
    );
  }
}

final projectsFilterProvider =
    NotifierProvider<ProjectsFilterNotifier, ProjectsFilter>(ProjectsFilterNotifier.new);

class ProjectsFilterNotifier extends Notifier<ProjectsFilter> {
  @override
  ProjectsFilter build() => const ProjectsFilter();

  void setFilter(ProjectsFilter filter) => state = filter;
  void update(ProjectsFilter Function(ProjectsFilter current) updater) => state = updater(state);
  void reset() => state = const ProjectsFilter();
}

final projectsListProvider = FutureProvider<PaginatedProjects>((ref) async {
  final filter = ref.watch(projectsFilterProvider);
  return ref.watch(projectRepositoryProvider).getProjects(
    search: filter.search,
    departmentId: filter.departmentId,
    status: filter.status,
    priority: filter.priority,
    teamLeadId: filter.teamLeadId,
    myProjects: filter.myProjects,
    isOverdue: filter.isOverdue,
    includeArchived: filter.includeArchived,
    page: filter.page,
    perPage: filter.perPage,
  );
});

final projectDashboardProvider = FutureProvider<ProjectDashboardStats>((ref) async {
  return ref.watch(projectRepositoryProvider).getDashboard();
});

final projectDetailProvider = FutureProvider.family<ProjectDetail, int>((ref, id) async {
  return ref.watch(projectRepositoryProvider).getProject(id);
});

final projectsControllerProvider = Provider<ProjectsController>((ref) {
  return ProjectsController(ref);
});

class ProjectsController {
  ProjectsController(this._ref);

  final Ref _ref;

  ProjectRepository get _repo => _ref.read(projectRepositoryProvider);

  Future<ProjectDetail> createProject(Map<String, dynamic> data) async {
    final created = await _repo.createProject(data);
    _ref.invalidate(projectsListProvider);
    _ref.invalidate(projectDashboardProvider);
    return created;
  }

  Future<ProjectDetail> updateProject(int id, Map<String, dynamic> data) async {
    final updated = await _repo.updateProject(id, data);
    _ref.invalidate(projectsListProvider);
    _ref.invalidate(projectDashboardProvider);
    _ref.invalidate(projectDetailProvider(id));
    return updated;
  }

  Future<void> deleteProject(int id) async {
    await _repo.deleteProject(id);
    _ref.invalidate(projectsListProvider);
    _ref.invalidate(projectDashboardProvider);
  }

  Future<ProjectDetail> updateStatus(int projectId, {required String status, String? reason}) async {
    final updated = await _repo.updateStatus(projectId, status: status, reason: reason);
    _ref.invalidate(projectsListProvider);
    _ref.invalidate(projectDashboardProvider);
    _ref.invalidate(projectDetailProvider(projectId));
    return updated;
  }

  Future<ProjectDetail> requestCompletion(int projectId, {String? notes}) async {
    final updated = await _repo.requestCompletion(projectId, notes: notes);
    _ref.invalidate(projectsListProvider);
    _ref.invalidate(projectDashboardProvider);
    _ref.invalidate(projectDetailProvider(projectId));
    return updated;
  }

  Future<ProjectDetail> approveCompletion(int projectId) async {
    final updated = await _repo.approveCompletion(projectId);
    _ref.invalidate(projectsListProvider);
    _ref.invalidate(projectDashboardProvider);
    _ref.invalidate(projectDetailProvider(projectId));
    return updated;
  }

  Future<ProjectDetail> rejectCompletion(int projectId, {required String reason}) async {
    final updated = await _repo.rejectCompletion(projectId, reason: reason);
    _ref.invalidate(projectsListProvider);
    _ref.invalidate(projectDashboardProvider);
    _ref.invalidate(projectDetailProvider(projectId));
    return updated;
  }

  Future<ProjectDetail> assignLead(int projectId, int? teamLeadId, {String? reason, bool keepAsMember = true}) async {
    final updated = await _repo.assignLead(projectId, teamLeadId, reason: reason, keepAsMember: keepAsMember);
    _ref.invalidate(projectsListProvider);
    _ref.invalidate(projectDashboardProvider);
    _ref.invalidate(projectDetailProvider(projectId));
    return updated;
  }

  Future<AddMemberResult> addMember(int projectId, int userId, String projectRole) async {
    final result = await _repo.addMember(projectId, userId, projectRole);
    _ref.invalidate(projectsListProvider);
    _ref.invalidate(projectDetailProvider(projectId));
    return result;
  }

  Future<void> updateMemberRole(int projectId, int memberUserId, String projectRole) async {
    await _repo.updateMemberRole(projectId, memberUserId, projectRole);
    _ref.invalidate(projectDetailProvider(projectId));
  }

  Future<void> removeMember(int projectId, int memberUserId) async {
    await _repo.removeMember(projectId, memberUserId);
    _ref.invalidate(projectsListProvider);
    _ref.invalidate(projectDetailProvider(projectId));
  }
}
