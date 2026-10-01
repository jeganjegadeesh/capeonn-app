import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/leave_models.dart';
import '../data/leave_repository.dart';

final leaveTypesProvider = FutureProvider.autoDispose<List<LeaveType>>((ref) async {
  return ref.watch(leaveRepositoryProvider).getTypes();
});

final leaveBalancesProvider = FutureProvider.autoDispose<List<LeaveBalance>>((ref) async {
  return ref.watch(leaveRepositoryProvider).getBalances();
});

final myLeaveRequestsProvider = FutureProvider.autoDispose<List<LeaveRequestItem>>((ref) async {
  return ref.watch(leaveRepositoryProvider).getMyRequests();
});

final approvalLeaveRequestsProvider = FutureProvider.autoDispose<List<LeaveRequestItem>>((ref) async {
  return ref.watch(leaveRepositoryProvider).getRequests();
});
