import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ContextMenuActionItem {
  const ContextMenuActionItem({
    required this.title,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;
}

/// A desktop and web secondary-click (right click) context menu wrapper,
/// falling back to long-press on touch mobile devices.
class DesktopContextMenu extends StatelessWidget {
  const DesktopContextMenu({
    super.key,
    required this.child,
    required this.actions,
    this.enabled = true,
  });

  final Widget child;
  final List<ContextMenuActionItem> actions;
  final bool enabled;

  void _showContextMenu(BuildContext context, Offset globalPosition) {
    if (!enabled || actions.isEmpty) return;

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    final position = RelativeRect.fromRect(
      Rect.fromPoints(globalPosition, globalPosition),
      Offset.zero & overlay.size,
    );

    showMenu<void>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border),
      ),
      elevation: 8,
      items: actions.map((action) {
        return PopupMenuItem<void>(
          onTap: action.onTap,
          height: 38,
          child: Row(
            children: [
              Icon(
                action.icon,
                size: 16,
                color: action.isDestructive ? AppColors.rose : AppColors.textSecondary,
              ),
              const SizedBox(width: 10),
              Text(
                action.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: action.isDestructive ? AppColors.rose : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapUp: (details) => _showContextMenu(context, details.globalPosition),
      onLongPressStart: (details) => _showContextMenu(context, details.globalPosition),
      child: child,
    );
  }
}
