import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Intent for global keyboard shortcuts in Capeonn.
class OpenCommandPaletteIntent extends Intent {
  const OpenCommandPaletteIntent();
}

class CreateTaskIntent extends Intent {
  const CreateTaskIntent();
}

class CreateProjectIntent extends Intent {
  const CreateProjectIntent();
}

class RefreshPageIntent extends Intent {
  const RefreshPageIntent();
}

class ShowShortcutsHelpIntent extends Intent {
  const ShowShortcutsHelpIntent();
}

class EscapeIntent extends Intent {
  const EscapeIntent();
}

/// Helper model for keyboard shortcuts documentation
class ShortcutItem {
  const ShortcutItem({
    required this.keys,
    required this.description,
    required this.category,
  });

  final String keys;
  final String description;
  final String category;
}

/// Global registry of Capeonn keyboard shortcuts
class AppShortcuts {
  const AppShortcuts._();

  static const List<ShortcutItem> all = [
    ShortcutItem(
      keys: 'Ctrl + K  /  ⌘K',
      description: 'Open Command Palette & Quick Navigation',
      category: 'Navigation',
    ),
    ShortcutItem(
      keys: 'Ctrl + N  /  ⌘N',
      description: 'Quick Create Task',
      category: 'Work Actions',
    ),
    ShortcutItem(
      keys: 'Ctrl + Shift + N',
      description: 'Quick Create Project (Admins & Managers)',
      category: 'Work Actions',
    ),
    ShortcutItem(
      keys: 'Ctrl + R  /  F5',
      description: 'Refresh Current Page Data',
      category: 'Navigation',
    ),
    ShortcutItem(
      keys: 'Ctrl + /  /  ⌘/',
      description: 'Show Keyboard Shortcuts Cheat Sheet',
      category: 'System',
    ),
    ShortcutItem(
      keys: 'Esc',
      description: 'Dismiss Dialog / Close Search Overlay',
      category: 'System',
    ),
    ShortcutItem(
      keys: 'Tab / Shift + Tab',
      description: 'Navigate Focus Across Form Fields & Tables',
      category: 'Accessibility',
    ),
  ];

  static void showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final categories = ['Navigation', 'Work Actions', 'System', 'Accessibility'];

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.keyboard, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Keyboard Shortcuts',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Desktop & Web workflow productivity',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final cat in categories) ...[
                            Padding(
                              padding: const EdgeInsets.only(top: 8, bottom: 6),
                              child: Text(
                                cat.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            ...all.where((s) => s.category == cat).map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.description,
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceHover,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: AppColors.border,
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            item.keys,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Got it'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
