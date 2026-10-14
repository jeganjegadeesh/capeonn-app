import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/models/audit_log_item.dart';

final auditLogRepositoryProvider = Provider<AuditLogRepository>((ref) {
  return AuditLogRepository(ref.read(dioProvider));
});

class AuditLogRepository {
  const AuditLogRepository(this._dio);

  final Dio _dio;

  Future<List<AuditLogItem>> getAuditLogs({
    String? severity,
    String? event,
    String? search,
    int page = 1,
    int perPage = 30,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };

    if (severity != null && severity.isNotEmpty && severity != 'all') {
      query['severity'] = severity;
    }
    if (event != null && event.isNotEmpty) {
      query['event'] = event;
    }
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }

    final res = await _dio.get('/admin/audit-logs', queryParameters: query);
    final data = res.data['data'] as List<dynamic>? ?? [];

    return data
        .map((item) => AuditLogItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<String> exportCsv({String? severity, String? event}) async {
    final query = <String, dynamic>{};
    if (severity != null && severity.isNotEmpty && severity != 'all') {
      query['severity'] = severity;
    }
    if (event != null && event.isNotEmpty) {
      query['event'] = event;
    }

    final res = await _dio.get(
      '/admin/audit-logs/export',
      queryParameters: query,
      options: Options(
        responseType: ResponseType.plain,
        headers: {'Accept': 'text/csv, text/plain, */*'},
      ),
    );

    return res.data.toString();
  }
}
