import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/audit_log_repository.dart';
import '../domain/models/audit_log_item.dart';

class AuditFilterState {
  const AuditFilterState({
    this.severity = 'all',
    this.search = '',
  });

  final String severity;
  final String search;

  AuditFilterState copyWith({
    String? severity,
    String? search,
  }) {
    return AuditFilterState(
      severity: severity ?? this.severity,
      search: search ?? this.search,
    );
  }
}

class AuditFilterNotifier extends Notifier<AuditFilterState> {
  @override
  AuditFilterState build() => const AuditFilterState();

  void setSeverity(String severity) => state = state.copyWith(severity: severity);
  void setSearch(String search) => state = state.copyWith(search: search);
  void reset() => state = const AuditFilterState();
}

final auditFilterProvider =
    NotifierProvider<AuditFilterNotifier, AuditFilterState>(AuditFilterNotifier.new);

final auditLogsListProvider =
    FutureProvider.autoDispose<List<AuditLogItem>>((ref) async {
  final filter = ref.watch(auditFilterProvider);
  final repo = ref.watch(auditLogRepositoryProvider);

  return repo.getAuditLogs(
    severity: filter.severity,
    search: filter.search,
  );
});
