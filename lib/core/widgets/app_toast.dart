import 'package:flutter/material.dart';

import '../network/api_exception.dart';
import '../theme/app_theme.dart';

enum AppToastType {
  success,
  error,
  warning,
  info,
}

/// Global modern floating toast notification helper.
/// Delivers sleek, floating toast banners with distinct color coding,
/// crisp icons, and automatic stripping of raw exception / framework prefixes.
class AppToast {
  AppToast._();

  /// Show a floating success toast
  static void success(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    show(
      context,
      message: message,
      title: title,
      type: AppToastType.success,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Show a floating error toast, automatically stripping "Unhandled Exception:",
  /// "ApiException(xxx):", "Exception:", etc.
  static void error(
    BuildContext context,
    dynamic error, {
    String? title,
    Duration duration = const Duration(seconds: 5),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    final cleanMsg = ApiException.cleanMessage(error);
    show(
      context,
      message: cleanMsg,
      title: title,
      type: AppToastType.error,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Show a floating warning toast
  static void warning(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    show(
      context,
      message: message,
      title: title,
      type: AppToastType.warning,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Show a floating info toast
  static void info(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    show(
      context,
      message: message,
      title: title,
      type: AppToastType.info,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Show a clickable foreground notification banner
  static void showNotificationToast(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onTap,
    IconData? icon,
    Color? color,
    Duration duration = const Duration(seconds: 5),
  }) {
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = color ?? (isDark ? AppColors.primaryLight : AppColors.primary);

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.only(top: 16, bottom: 24, left: 16, right: 16),
        duration: duration,
        content: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  messenger.hideCurrentSnackBar();
                  onTap?.call();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          icon ?? Icons.notifications_active_rounded,
                          color: primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              message,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Base floating toast builder
  static void show(
    BuildContext context, {
    required String message,
    String? title,
    AppToastType type = AppToastType.info,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Harmonious colors tailored for both dark & light palettes
    final (
      Color bgColor,
      Color borderColor,
      Color iconColor,
      Color iconBgColor,
      Color textColor,
      IconData iconData,
    ) = switch (type) {
      AppToastType.error => isDark
          ? (
              const Color(0xFF2C1518),
              const Color(0xFF7F1D1D),
              const Color(0xFFF87171),
              const Color(0xFF450A0A),
              const Color(0xFFFEE2E2),
              Icons.error_outline_rounded,
            )
          : (
              const Color(0xFFFEF2F2),
              const Color(0xFFFECACA),
              AppColors.rose,
              const Color(0xFFFEE2E2),
              const Color(0xFF991B1B),
              Icons.error_outline_rounded,
            ),
      AppToastType.success => isDark
          ? (
              const Color(0xFF062A1F),
              const Color(0xFF065F46),
              const Color(0xFF34D399),
              const Color(0xFF042F2E),
              const Color(0xFFD1FAE5),
              Icons.check_circle_outline_rounded,
            )
          : (
              const Color(0xFFECFDF5),
              const Color(0xFFA7F3D0),
              AppColors.emerald,
              const Color(0xFFD1FAE5),
              const Color(0xFF065F46),
              Icons.check_circle_outline_rounded,
            ),
      AppToastType.warning => isDark
          ? (
              const Color(0xFF2E1C07),
              const Color(0xFF78350F),
              const Color(0xFFFBBF24),
              const Color(0xFF451A03),
              const Color(0xFFFEF3C7),
              Icons.warning_amber_rounded,
            )
          : (
              const Color(0xFFFFFBEB),
              const Color(0xFFFDE68A),
              AppColors.amber,
              const Color(0xFFFEF3C7),
              const Color(0xFF92400E),
              Icons.warning_amber_rounded,
            ),
      AppToastType.info => isDark
          ? (
              const Color(0xFF111D38),
              const Color(0xFF1E3A8A),
              AppColors.primaryLight,
              const Color(0xFF1E3A8A).withValues(alpha: 0.6),
              const Color(0xFFDBEAFE),
              Icons.info_outline_rounded,
            )
          : (
              const Color(0xFFEFF6FF),
              const Color(0xFFBFDBFE),
              AppColors.primary,
              const Color(0xFFDBEAFE),
              const Color(0xFF1E40AF),
              Icons.info_outline_rounded,
            ),
    };

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
        duration: duration,
        content: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.10),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon pill
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(iconData, color: iconColor, size: 18),
                    ),
                    const SizedBox(width: 12),

                    // Content text
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (title != null && title.isNotEmpty) ...[
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                          ],
                          Text(
                            message,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Action button if supplied
                    if (onAction != null && actionLabel != null) ...[
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          messenger.hideCurrentSnackBar();
                          onAction();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: iconColor,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          actionLabel,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],

                    // Close button
                    const SizedBox(width: 6),
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => messenger.hideCurrentSnackBar(),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: textColor.withValues(alpha: 0.65),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
