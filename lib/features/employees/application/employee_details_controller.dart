import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/employee_details_models.dart';
import '../data/employee_details_repository.dart';

final employeeDocumentsProvider = FutureProvider.family<List<EmployeeDocumentItem>, int>((ref, employeeId) async {
  return ref.watch(employeeDetailsRepositoryProvider).getDocuments(employeeId);
});

final employeeHistoriesProvider = FutureProvider.family<List<EmployeeHistoryItem>, int>((ref, employeeId) async {
  return ref.watch(employeeDetailsRepositoryProvider).getHistories(employeeId);
});
