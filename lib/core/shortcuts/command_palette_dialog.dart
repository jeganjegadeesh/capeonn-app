import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/notifications/presentation/notifications_dialog.dart';
import 'app_shortcuts.dart';

class CommandAction {
  const CommandAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.category,
    required this.onExecute,
    this.badge,
    this.shortcut,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String category;
  final void Function(BuildContext context, WidgetRef ref) onExecute;
  final String? badge;
  final String? shortcut;
}

/// Global spotlight Command Palette dialog (`Ctrl + K` / `Cmd + K`).
class CommandPaletteDialog extends ConsumerStatefulWidget {
  const CommandPaletteDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: true,
      builder: (_) => const CommandPaletteDialog(),
    );
  }

  @override
  ConsumerState<CommandPaletteDialog> createState() => _CommandPaletteDialogState();
}

class _CommandPaletteDialogState extends ConsumerState<CommandPaletteDialog> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int _selectedIndex = 0;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.trim().toLowerCase();
        _selectedIndex = 0;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<CommandAction> _getAvailableActions() {
    final user = ref.read(authControllerProvider).value;
    final isSuperAdmin = user?.isSuperAdmin ?? false;
    final isManager = user?.isManager ?? false;
    final isTeamLead = user?.isTeamLead ?? false;
    final canViewReports = isSuperAdmin || isManager || isTeamLead;

    final actions = <CommandAction>[
      // --- Navigation Destinations ---
      CommandAction(
        title: 'Dashboard Overview',
        subtitle: 'Executive KPIs, project health, and attention items',
        icon: Icons.dashboard_outlined,
        category: 'Navigation',
        onExecute: (ctx, _) => ctx.go('/home'),
      ),
      CommandAction(
        title: 'Projects',
        subtitle: 'Company and department project index and workspaces',
        icon: Icons.folder_outlined,
        category: 'Navigation',
        onExecute: (ctx, _) => ctx.go('/projects'),
      ),
      CommandAction(
        title: 'My Tasks',
        subtitle: 'Personal task pipeline, timer tracking, and review status',
        icon: Icons.check_circle_outline,
        category: 'Navigation',
        shortcut: 'Ctrl+N for new',
        onExecute: (ctx, _) => ctx.go('/tasks'),
      ),
      CommandAction(
        title: 'Internal Chat',
        subtitle: 'One-on-one direct messages and project channels',
        icon: Icons.chat_bubble_outline,
        category: 'Navigation',
        onExecute: (ctx, _) => ctx.go('/chat'),
      ),
      if (canViewReports)
        CommandAction(
          title: 'Reports & Analytics',
          subtitle: 'Workload, time variance, overdue metrics, and CSV export',
          icon: Icons.bar_chart_outlined,
          category: 'Navigation',
          badge: 'Phase 9',
          onExecute: (ctx, _) => ctx.go('/reports'),
        ),
      if (!isSuperAdmin) ...[
        CommandAction(
          title: 'Attendance',
          subtitle: 'Daily check-in, check-out, and attendance history',
          icon: Icons.access_time_outlined,
          category: 'Navigation',
          onExecute: (ctx, _) => ctx.go('/attendance'),
        ),
        CommandAction(
          title: 'Leave Requests',
          subtitle: 'Apply for leave, check balance, and approval status',
          icon: Icons.event_note_outlined,
          category: 'Navigation',
          onExecute: (ctx, _) => ctx.go('/leaves'),
        ),
      ],
      CommandAction(
        title: 'Holidays Calendar',
        subtitle: 'Company holiday schedule and upcoming observances',
        icon: Icons.calendar_today_outlined,
        category: 'Navigation',
        onExecute: (ctx, _) => ctx.go('/holidays'),
      ),
      CommandAction(
        title: 'Employees Directory',
        subtitle: 'Staff contact directory and departmental records',
        icon: Icons.people_outline,
        category: 'Navigation',
        onExecute: (ctx, _) => ctx.go('/employees'),
      ),
      CommandAction(
        title: 'Organization Hierarchy',
        subtitle: 'Reporting trees: Manager → Team Lead → Members',
        icon: Icons.account_tree_outlined,
        category: 'Navigation',
        onExecute: (ctx, _) => ctx.go('/hierarchy'),
      ),
      CommandAction(
        title: 'Departments',
        subtitle: 'Company department breakdown and team leads',
        icon: Icons.business_outlined,
        category: 'Navigation',
        onExecute: (ctx, _) => ctx.go('/departments'),
      ),
      CommandAction(
        title: 'Company Profile',
        subtitle: 'Organization settings, branding, and details',
        icon: Icons.domain_outlined,
        category: 'Navigation',
        onExecute: (ctx, _) => ctx.go('/company'),
      ),
      if (isSuperAdmin) ...[
        CommandAction(
          title: 'Roles & Permissions',
          subtitle: 'Security matrix and role assignment',
          icon: Icons.security_outlined,
          category: 'Admin System',
          onExecute: (ctx, _) => ctx.go('/roles'),
        ),
        CommandAction(
          title: 'System Settings',
          subtitle: 'Application configurations and maintenance modes',
          icon: Icons.settings_outlined,
          category: 'Admin System',
          onExecute: (ctx, _) => ctx.go('/settings'),
        ),
        CommandAction(
          title: 'Audit Logs',
          subtitle: 'System-wide activity logs and change history',
          icon: Icons.history_outlined,
          category: 'Admin System',
          onExecute: (ctx, _) => ctx.go('/audit'),
        ),
      ],

      // --- Quick Actions ---
      CommandAction(
        title: 'Toggle Theme',
        subtitle: 'Switch between Obsidian Dark and Clean Light themes',
        icon: Icons.brightness_medium_outlined,
        category: 'Actions',
        onExecute: (ctx, r) => r.read(themeModeProvider.notifier).toggleTheme(ctx),
      ),
      CommandAction(
        title: 'Notifications Inbox',
        subtitle: 'Open recent notifications drawer',
        icon: Icons.notifications_outlined,
        category: 'Actions',
        onExecute: (ctx, _) => NotificationsDialog.show(ctx),
      ),
      CommandAction(
        title: 'Change Password',
        subtitle: 'Update your account credentials',
        icon: Icons.lock_outline,
        category: 'Actions',
        onExecute: (ctx, _) => ctx.push('/change-password'),
      ),
      CommandAction(
        title: 'Keyboard Shortcuts Help',
        subtitle: 'View complete hotkey reference guide',
        icon: Icons.keyboard_outlined,
        category: 'Actions',
        shortcut: 'Ctrl+/',
        onExecute: (ctx, _) => AppShortcuts.showHelpDialog(ctx),
      ),
      CommandAction(
        title: 'Sign Out',
        subtitle: 'End active session securely',
        icon: Icons.logout,
        category: 'Actions',
        onExecute: (_, r) => r.read(authControllerProvider.notifier).logout(),
      ),
    ];

    if (_query.isEmpty) return actions;

    return actions.where((a) {
      final text = '${a.title} ${a.subtitle} ${a.category}'.toLowerCase();
      return text.contains(_query);
    }).toList();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final actions = _getAvailableActions();
    if (actions.isEmpty) return;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _selectedIndex = (_selectedIndex + 1) % actions.length;
      });
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _selectedIndex = (_selectedIndex - 1 + actions.length) % actions.length;
      });
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_selectedIndex >= 0 && _selectedIndex < actions.length) {
        _executeAction(actions[_selectedIndex]);
      }
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
    }
  }

  void _executeAction(CommandAction action) {
    Navigator.of(context).pop();
    action.onExecute(context, ref);
  }

  @override
  Widget build(BuildContext context) {
    final actions = _getAvailableActions();
    final theme = Theme.of(context);

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: false,
      onKeyEvent: _handleKeyEvent,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          width: double.infinity,
          margin: const EdgeInsets.only(top: 60, left: 16, right: 16, bottom: 40),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Search Input Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: AppColors.primary, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Type a command, search pages, or jump to...',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                        ),
                      ),
                      if (_query.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _searchController.clear(),
                        ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHover,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          'ESC to close',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Command Action Results List
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: actions.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off,
                                  size: 40, color: AppColors.textMuted),
                              const SizedBox(height: 12),
                              Text(
                                'No matching commands or pages found',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          itemCount: actions.length,
                          itemBuilder: (context, index) {
                            final action = actions[index];
                            final isSelected = index == _selectedIndex;

                            return MouseRegion(
                              cursor: SystemMouseCursors.click,
                              onEnter: (_) {
                                setState(() => _selectedIndex = index);
                              },
                              child: InkWell(
                                onTap: () => _executeAction(action),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  color: isSelected
                                      ? AppColors.primaryContainer
                                      : Colors.transparent,
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.primary
                                              : AppColors.surfaceHover,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          action.icon,
                                          size: 18,
                                          color: isSelected
                                              ? Colors.white
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  action.title,
                                                  style: TextStyle(
                                                    fontWeight: isSelected
                                                        ? FontWeight.bold
                                                        : FontWeight.w600,
                                                    fontSize: 14,
                                                    color: isSelected
                                                        ? AppColors.primary
                                                        : AppColors.textPrimary,
                                                  ),
                                                ),
                                                if (action.badge != null) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 6,
                                                      vertical: 1.5,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.emeraldContainer,
                                                      borderRadius:
                                                          BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      action.badge!,
                                                      style: const TextStyle(
                                                        fontSize: 9.5,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: AppColors.emerald,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            Text(
                                              action.subtitle,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (action.shortcut != null)
                                        Container(
                                          margin: const EdgeInsets.only(left: 8),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceHover,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            border: Border.all(
                                                color: AppColors.border),
                                          ),
                                          child: Text(
                                            action.shortcut!,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontFamily: 'monospace',
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(width: 8),
                                      Text(
                                        action.category,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Footer Keyboard Hints
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHover,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: LayoutBuilder(
                    builder: (context, footerConstraints) {
                      final isMobile = footerConstraints.maxWidth < 450;
                      if (isMobile) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const _HintPill(label: '↵', text: 'Select'),
                            Text(
                              'Capeonn v1.0',
                              style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                            ),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Text(
                            'Navigation Hints: ',
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                          const _HintPill(label: '↑↓', text: 'Navigate'),
                          const SizedBox(width: 8),
                          const _HintPill(label: '↵', text: 'Select'),
                          const SizedBox(width: 8),
                          const _HintPill(label: 'esc', text: 'Dismiss'),
                          const Spacer(),
                          Text(
                            'Capeonn v1.0',
                            style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HintPill extends StatelessWidget {
  const _HintPill({required this.label, required this.text});
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 3),
        Text(text, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}
