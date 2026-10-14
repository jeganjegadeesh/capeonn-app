import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/responsive/responsive_layout.dart';
import '../../../core/services/file_download_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../application/audit_log_controller.dart';
import '../data/audit_log_repository.dart';
import '../domain/models/audit_log_item.dart';

class AuditLogsPage extends ConsumerStatefulWidget {
  const AuditLogsPage({super.key});

  @override
  ConsumerState<AuditLogsPage> createState() => _AuditLogsPageState();
}

class _AuditLogsPageState extends ConsumerState<AuditLogsPage> {
  late final TextEditingController _searchController;
  Timer? _debounceTimer;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    final currentSearch = ref.read(auditFilterProvider).search;
    _searchController = TextEditingController(text: currentSearch);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      ref.read(auditFilterProvider.notifier).setSearch(query);
    });
  }

  void _onSeverityChanged(String severity) {
    ref.read(auditFilterProvider.notifier).setSeverity(severity);
  }

  Future<void> _exportCsv() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      final filter = ref.read(auditFilterProvider);
      final repo = ref.read(auditLogRepositoryProvider);

      AppToast.info(context, 'Preparing CSV audit report...');
      final csv = await repo.exportCsv(
        severity: filter.severity,
      );

      if (csv.trim().isEmpty) {
        if (mounted) AppToast.error(context, 'Export returned no data');
        return;
      }

      final dateStr = DateTime.now().toIso8601String().substring(0, 10);
      final fileName = 'audit_logs_${filter.severity}_$dateStr.csv';
      final bom = [0xEF, 0xBB, 0xBF];
      final fileBytes = [...bom, ...utf8.encode(csv)];

      if (!mounted) return;
      await FileDownloadService.saveFileBytes(
        context: context,
        bytes: fileBytes,
        fileName: fileName,
        mimeType: 'text/csv',
        autoOpen: true,
      );

      if (mounted) {
        AppToast.success(context, 'Audit logs exported successfully');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, e, title: 'Export Failed');
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  String _formatDateTime(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min:$s';
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return AppColors.rose;
      case 'warning':
        return AppColors.amber;
      case 'info':
      default:
        return AppColors.primary;
    }
  }

  IconData _eventIcon(String event, String severity) {
    if (severity.toLowerCase() == 'critical') {
      return Icons.gpp_bad_rounded;
    }
    if (event.contains('failed')) {
      return Icons.lock_clock_rounded;
    }
    if (event.contains('login')) {
      return Icons.login_rounded;
    }
    if (event.contains('logout')) {
      return Icons.logout_rounded;
    }
    if (event.contains('password')) {
      return Icons.password_rounded;
    }
    if (event.contains('security')) {
      return Icons.shield_rounded;
    }
    if (severity.toLowerCase() == 'warning') {
      return Icons.warning_amber_rounded;
    }
    return Icons.security_rounded;
  }

  void _showLogDetailsDialog(BuildContext context, AuditLogItem log) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              _eventIcon(log.event, log.severity),
              color: _severityColor(log.severity),
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Audit Event #${log.id}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Event Tag', log.event),
                _buildDetailRow('Severity', log.severity.toUpperCase()),
                _buildDetailRow('Timestamp', '${_formatDateTime(log.createdAt)} (UTC)'),
                _buildDetailRow('Actor', log.userName != null ? '${log.userName} (${log.userEmail ?? 'No email'})' : 'System'),
                _buildDetailRow('IP Address', log.ipAddress ?? 'N/A'),
                const SizedBox(height: 12),
                const Text(
                  'Description:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHover,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    log.description,
                    style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  ),
                ),
                if (log.metadata != null && log.metadata!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'Metadata Payload:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      const JsonEncoder.withIndent('  ').convert(log.metadata),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Color(0xFF38BDF8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(auditFilterProvider);
    final logsAsync = ref.watch(auditLogsListProvider);
    final isDesktop = context.isDesktop;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ResponsiveContentContainer(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(auditLogsListProvider);
            await ref.read(auditLogsListProvider.future);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 10,
                              runSpacing: 4,
                              children: [
                                Text(
                                  'Audit & Security Logs',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                _buildTamperEvidentBadge(),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Track enterprise system events, administrator modifications, and authentication actions.',
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildExportButton(isDesktop: true),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Text(
                            'Audit & Security Logs',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          _buildTamperEvidentBadge(),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Track enterprise system events, administrator modifications, and authentication actions.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      _buildExportButton(isDesktop: false),
                    ],
                  ),
                const SizedBox(height: 20),

                // Filters bar: Search input + Severity choice chips
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: _onSearchChanged,
                                decoration: InputDecoration(
                                  hintText: 'Search by description, event, IP, or user email...',
                                  hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted),
                                  prefixIcon: const Icon(Icons.search, size: 20),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear, size: 18),
                                          onPressed: () {
                                            _searchController.clear();
                                            ref.read(auditFilterProvider.notifier).setSearch('');
                                          },
                                        )
                                      : null,
                                  isDense: true,
                                  filled: true,
                                  fillColor: AppColors.surfaceHover,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: AppColors.border),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: AppColors.border),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'Refresh Logs',
                              icon: const Icon(Icons.refresh_rounded),
                              onPressed: () => ref.refresh(auditLogsListProvider),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _buildSeverityChip('All', 'all', filter.severity),
                            _buildSeverityChip('Info', 'info', filter.severity, color: AppColors.primary),
                            _buildSeverityChip('Warning', 'warning', filter.severity, color: AppColors.amber),
                            _buildSeverityChip('Critical', 'critical', filter.severity, color: AppColors.rose),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Content Area
                logsAsync.when(
                  loading: () => Container(
                    height: 240,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(),
                  ),
                  error: (error, _) => Card(
                    elevation: 0,
                    color: AppColors.roseContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: AppColors.rose.withValues(alpha: 0.3)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline_rounded, color: AppColors.rose, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Failed to retrieve audit trail: $error',
                              style: TextStyle(color: AppColors.rose, fontSize: 13),
                            ),
                          ),
                          TextButton(
                            onPressed: () => ref.refresh(auditLogsListProvider),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (logs) {
                    if (logs.isEmpty) {
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: AppColors.border),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 16.0),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.policy_outlined,
                                  size: 48,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No audit records found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'No system events match the selected filters or query.',
                                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                ),
                                if (filter.severity != 'all' || filter.search.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      _searchController.clear();
                                      ref.read(auditFilterProvider.notifier).reset();
                                    },
                                    icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                                    label: const Text('Clear Filters'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: logs.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, idx) {
                        final log = logs[idx];
                        final color = _severityColor(log.severity);
                        final icon = _eventIcon(log.event, log.severity);

                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: AppColors.border),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => _showLogDetailsDialog(context, log),
                            child: Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(icon, color: color, size: 22),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: color.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                log.severity.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: color,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                log.event,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _timeAgo(log.createdAt),
                                              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          log.description,
                                          style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 16,
                                          runSpacing: 4,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.person_outline, size: 13, color: AppColors.textMuted),
                                                const SizedBox(width: 4),
                                                Text(
                                                  log.userName ?? 'System',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                    color: AppColors.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (log.ipAddress != null && log.ipAddress!.isNotEmpty)
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.public, size: 13, color: AppColors.textMuted),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    log.ipAddress!,
                                                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                                                  ),
                                                ],
                                              ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.schedule, size: 13, color: AppColors.textMuted),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _formatDateTime(log.createdAt),
                                                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.chevron_right,
                                    size: 18,
                                    color: AppColors.textMuted,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeverityChip(String label, String value, String currentSelected, {Color? color}) {
    final isSelected = currentSelected == value;
    final chipColor = color ?? AppColors.primary;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _onSeverityChanged(value),
      selectedColor: chipColor.withValues(alpha: 0.16),
      checkmarkColor: chipColor,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? chipColor : AppColors.textSecondary,
      ),
      side: BorderSide(
        color: isSelected ? chipColor : AppColors.border,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }

  Widget _buildTamperEvidentBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE9FE),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined, size: 14, color: Color(0xFF6D28D9)),
          SizedBox(width: 4),
          Text(
            'Tamper-Evident',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6D28D9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton({required bool isDesktop}) {
    return FilledButton.icon(
      onPressed: _isExporting ? null : _exportCsv,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 16 : 12,
          vertical: isDesktop ? 12 : 8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      icon: _isExporting
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.download_rounded, size: 18),
      label: Text(
        _isExporting ? 'Exporting...' : 'Export CSV',
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }
}

