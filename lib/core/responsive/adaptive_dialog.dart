import 'package:flutter/material.dart';

import 'responsive_layout.dart';

/// Utility to show dialogs adaptively:
/// - On Mobile (< 600px): Opens a styled Draggable / Modal Bottom Sheet.
/// - On Tablet / Desktop (>= 600px): Opens a centered Material Dialog with max width.
class AdaptiveDialog {
  const AdaptiveDialog._();

  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    String? title,
    double desktopMaxWidth = 580.0,
    bool barrierDismissible = true,
  }) {
    if (context.isMobile) {
      return showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (bottomSheetContext) {
          final theme = Theme.of(bottomSheetContext);
          return Container(
            margin: EdgeInsets.only(
              top: MediaQuery.paddingOf(bottomSheetContext).top + 40,
            ),
            decoration: BoxDecoration(
              color: theme.dialogTheme.backgroundColor ?? theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 16,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  if (title != null) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => Navigator.of(bottomSheetContext).pop(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                  ],
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.viewInsetsOf(bottomSheetContext).bottom,
                      ),
                      child: builder(bottomSheetContext),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: desktopMaxWidth),
            child: builder(dialogContext),
          ),
        );
      },
    );
  }
}
