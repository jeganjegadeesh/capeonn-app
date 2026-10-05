import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/task_models.dart';
import '../data/task_repository.dart';

// -----------------------------------------------------------------------------
// Project Tasks Filter & Providers
// -----------------------------------------------------------------------------

class ProjectTasksFilter {
  const ProjectTasksFilter({
    this.status,
    this.priority,
    this.assignedToId,
    this.rootOnly = true,
    this.search,
  });

  final String? status;
  final String? priority;
  final String? assignedToId;
  final bool rootOnly;
  final String? search;

  ProjectTasksFilter copyWith({
    String? status,
    String? priority,
    String? assignedToId,
    bool? rootOnly,
    String? search,
  }) {
    return ProjectTasksFilter(
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assignedToId: assignedToId ?? this.assignedToId,
      rootOnly: rootOnly ?? this.rootOnly,
      search: search ?? this.search,
    );
  }
}

class ProjectTasksFilterNotifier extends Notifier<Map<int, ProjectTasksFilter>> {
  @override
  Map<int, ProjectTasksFilter> build() => const {};

  void setFilter(int projectId, ProjectTasksFilter filter) {
    state = {...state, projectId: filter};
  }

  void clear(int projectId) {
    final next = Map<int, ProjectTasksFilter>.from(state);
    next.remove(projectId);
    state = next;
  }
}

final projectTasksFilterProvider =
    NotifierProvider<ProjectTasksFilterNotifier, Map<int, ProjectTasksFilter>>(
  ProjectTasksFilterNotifier.new,
);

final projectTasksProvider = FutureProvider.family<List<TaskItem>, int>((ref, projectId) async {
  final repo = ref.watch(taskRepositoryProvider);
  final allFilters = ref.watch(projectTasksFilterProvider);
  final filter = allFilters[projectId] ?? const ProjectTasksFilter();

  return repo.getProjectTasks(
    projectId,
    status: filter.status,
    priority: filter.priority,
    assignedToId: filter.assignedToId,
    rootOnly: filter.rootOnly,
    search: filter.search,
  );
});

// -----------------------------------------------------------------------------
// My Tasks Filter & Providers
// -----------------------------------------------------------------------------

class MyTasksFilter {
  const MyTasksFilter({
    this.status,
    this.projectId,
    this.priority,
    this.isOverdue,
  });

  final String? status;
  final int? projectId;
  final String? priority;
  final bool? isOverdue;

  MyTasksFilter copyWith({
    String? status,
    int? projectId,
    String? priority,
    bool? isOverdue,
  }) {
    return MyTasksFilter(
      status: status ?? this.status,
      projectId: projectId ?? this.projectId,
      priority: priority ?? this.priority,
      isOverdue: isOverdue ?? this.isOverdue,
    );
  }
}

class MyTasksFilterNotifier extends Notifier<MyTasksFilter> {
  @override
  MyTasksFilter build() => const MyTasksFilter();

  void setFilter(MyTasksFilter filter) => state = filter;
}

final myTasksFilterProvider =
    NotifierProvider<MyTasksFilterNotifier, MyTasksFilter>(MyTasksFilterNotifier.new);

final myTasksProvider = FutureProvider<List<TaskItem>>((ref) async {
  final repo = ref.watch(taskRepositoryProvider);
  final filter = ref.watch(myTasksFilterProvider);

  return repo.getMyTasks(
    status: filter.status,
    projectId: filter.projectId,
    priority: filter.priority,
    isOverdue: filter.isOverdue,
  );
});

// -----------------------------------------------------------------------------
// Single Task Detail Provider
// -----------------------------------------------------------------------------

final taskDetailProvider = FutureProvider.family<TaskDetail, int>((ref, taskId) async {
  final repo = ref.watch(taskRepositoryProvider);
  return repo.getTask(taskId);
});

// -----------------------------------------------------------------------------
// Active Live Timer State & Notifier (Riverpod 3 Notifier)
// -----------------------------------------------------------------------------

class ActiveTimerState {
  const ActiveTimerState({
    this.entry,
    this.elapsedSeconds = 0,
    this.isLoading = false,
  });

  final TimeEntryItem? entry;
  final int elapsedSeconds;
  final bool isLoading;

  bool get isRunning => entry != null;
  bool get isPaused => entry?.isPaused ?? false;

  String get formattedTime {
    final hours = elapsedSeconds ~/ 3600;
    final mins = (elapsedSeconds % 3600) ~/ 60;
    final secs = elapsedSeconds % 60;

    final hStr = hours.toString().padLeft(2, '0');
    final mStr = mins.toString().padLeft(2, '0');
    final sStr = secs.toString().padLeft(2, '0');
    return '$hStr:$mStr:$sStr';
  }
}

class ActiveTimerNotifier extends Notifier<ActiveTimerState> {
  Timer? _ticker;

  TaskRepository get _repo => ref.read(taskRepositoryProvider);

  @override
  ActiveTimerState build() {
    ref.onDispose(() {
      _ticker?.cancel();
    });

    // Schedule check after initial build frame
    Future.microtask(() => checkActiveTimer());
    return const ActiveTimerState();
  }

  int _calculateElapsed(TimeEntryItem entry) {
    if (entry.startedAt == null) return entry.durationSeconds;
    final start = DateTime.tryParse(entry.startedAt!);
    if (start == null) return entry.durationSeconds;

    if (entry.isPaused && entry.pausedAt != null) {
      final paused = DateTime.tryParse(entry.pausedAt!);
      if (paused != null) {
        return max(0, paused.toUtc().difference(start.toUtc()).inSeconds);
      }
    }

    return max(0, DateTime.now().toUtc().difference(start.toUtc()).inSeconds);
  }

  Future<void> checkActiveTimer() async {
    try {
      state = ActiveTimerState(entry: state.entry, elapsedSeconds: state.elapsedSeconds, isLoading: true);
      final entry = await _repo.getActiveTimer();
      if (entry != null) {
        final elapsed = _calculateElapsed(entry);
        state = ActiveTimerState(entry: entry, elapsedSeconds: elapsed, isLoading: false);
        if (!entry.isPaused) {
          _startTicker();
        } else {
          _stopTicker();
        }
      } else {
        _stopTicker();
        state = const ActiveTimerState(entry: null, elapsedSeconds: 0, isLoading: false);
      }
    } catch (_) {
      state = ActiveTimerState(entry: state.entry, elapsedSeconds: state.elapsedSeconds, isLoading: false);
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final entry = state.entry;
      if (entry != null && !entry.isPaused) {
        final elapsed = _calculateElapsed(entry);
        state = ActiveTimerState(
          entry: entry,
          elapsedSeconds: elapsed,
          isLoading: false,
        );
      }
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  Future<TimeEntryItem> startTimer(int taskId, {String? description}) async {
    state = ActiveTimerState(entry: state.entry, elapsedSeconds: state.elapsedSeconds, isLoading: true);
    try {
      final entry = await _repo.startTimer(taskId, description: description);
      final elapsed = _calculateElapsed(entry);
      state = ActiveTimerState(entry: entry, elapsedSeconds: elapsed, isLoading: false);
      _startTicker();
      return entry;
    } catch (e) {
      state = ActiveTimerState(entry: state.entry, elapsedSeconds: state.elapsedSeconds, isLoading: false);
      rethrow;
    }
  }

  Future<TimeEntryItem> pauseTimer(int taskId) async {
    state = ActiveTimerState(entry: state.entry, elapsedSeconds: state.elapsedSeconds, isLoading: true);
    try {
      final entry = await _repo.pauseTimer(taskId);
      _stopTicker();
      final elapsed = _calculateElapsed(entry);
      state = ActiveTimerState(entry: entry, elapsedSeconds: elapsed, isLoading: false);
      return entry;
    } catch (e) {
      state = ActiveTimerState(entry: state.entry, elapsedSeconds: state.elapsedSeconds, isLoading: false);
      rethrow;
    }
  }

  Future<TimeEntryItem> resumeTimer(int taskId) async {
    state = ActiveTimerState(entry: state.entry, elapsedSeconds: state.elapsedSeconds, isLoading: true);
    try {
      final entry = await _repo.resumeTimer(taskId);
      final elapsed = _calculateElapsed(entry);
      state = ActiveTimerState(entry: entry, elapsedSeconds: elapsed, isLoading: false);
      _startTicker();
      return entry;
    } catch (e) {
      state = ActiveTimerState(entry: state.entry, elapsedSeconds: state.elapsedSeconds, isLoading: false);
      rethrow;
    }
  }

  Future<TimeEntryItem> stopTimer(int taskId, {String? description}) async {
    state = ActiveTimerState(entry: state.entry, elapsedSeconds: state.elapsedSeconds, isLoading: true);
    try {
      final entry = await _repo.stopTimer(taskId, description: description);
      _stopTicker();
      state = const ActiveTimerState(entry: null, elapsedSeconds: 0, isLoading: false);
      return entry;
    } catch (e) {
      state = ActiveTimerState(entry: state.entry, elapsedSeconds: state.elapsedSeconds, isLoading: false);
      rethrow;
    }
  }
}

final activeTimerProvider =
    NotifierProvider<ActiveTimerNotifier, ActiveTimerState>(ActiveTimerNotifier.new);

// -----------------------------------------------------------------------------
// My Work Today Provider
// -----------------------------------------------------------------------------

final myWorkTodayProvider = FutureProvider<MyWorkTodaySummary>((ref) async {
  final repo = ref.watch(taskRepositoryProvider);
  return repo.getMyWorkToday();
});

