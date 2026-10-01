import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/attendance_models.dart';
import '../data/attendance_repository.dart';

final attendanceTodayProvider = AsyncNotifierProvider<AttendanceTodayNotifier, AttendanceToday?>(() {
  return AttendanceTodayNotifier();
});

class AttendanceTodayNotifier extends AsyncNotifier<AttendanceToday?> {
  @override
  Future<AttendanceToday?> build() async {
    return ref.watch(attendanceRepositoryProvider).getToday();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(attendanceRepositoryProvider).getToday());
  }

  Future<void> clockIn({
    double? latitude,
    double? longitude,
    String? locationName,
    String? notes,
  }) async {
    await ref.read(attendanceRepositoryProvider).clockIn(
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
      notes: notes,
    );
    await refresh();
  }

  Future<void> clockOut({
    double? latitude,
    double? longitude,
    String? locationName,
    String? notes,
  }) async {
    await ref.read(attendanceRepositoryProvider).clockOut(
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
      notes: notes,
    );
    await refresh();
  }
}

final attendanceSummaryProvider = FutureProvider.family<AttendanceSummary, (int?, int?)>((ref, arg) async {
  final (month, year) = arg;
  return ref.watch(attendanceRepositoryProvider).getSummary(month: month, year: year);
});

final myAttendanceRecordsProvider = FutureProvider.family<List<AttendanceRecord>, (int?, int?)>((ref, arg) async {
  final (month, year) = arg;
  return ref.watch(attendanceRepositoryProvider).getMyRecords(month: month, year: year);
});

final teamAttendanceRecordsProvider = FutureProvider.autoDispose<List<AttendanceRecord>>((ref) async {
  return ref.watch(attendanceRepositoryProvider).getRecords();
});

final regularizationsProvider = FutureProvider.autoDispose<List<AttendanceRegularization>>((ref) async {
  return ref.watch(attendanceRepositoryProvider).getRegularizations();
});
