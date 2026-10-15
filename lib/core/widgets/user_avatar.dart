import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../theme/app_theme.dart';
import 'app_toast.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/data/auth_user.dart';

/// A reusable avatar widget that gracefully displays a user's profile image
/// or falls back to their first initial with brand-tailored colors.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.radius = 20,
    this.backgroundColor,
    this.foregroundColor,
    this.fontSize,
    this.showEditBadge = false,
    this.onTap,
    this.onEditTap,
    this.badge,
    this.tooltip,
  });

  final String name;
  final String? avatarUrl;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? fontSize;
  final bool showEditBadge;
  final VoidCallback? onTap;
  final VoidCallback? onEditTap;
  final Widget? badge;
  final String? tooltip;

  String get _initial {
    final trimmed = name.trim();
    return trimmed.isNotEmpty ? trimmed[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ?? AppColors.primary;
    final effectiveFg = foregroundColor ?? Colors.white;
    final effectiveFontSize = fontSize ?? (radius * 0.85);
    final diameter = radius * 2;

    final resolvedUrl = (avatarUrl != null && avatarUrl!.trim().isNotEmpty)
        ? AppConfig.resolveFileUrl(avatarUrl!.trim())
        : null;

    Widget avatarContent;
    if (resolvedUrl != null && resolvedUrl.isNotEmpty) {
      avatarContent = ClipOval(
        child: Image.network(
          resolvedUrl,
          width: diameter,
          height: diameter,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallback(effectiveBg, effectiveFg, effectiveFontSize);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Stack(
              alignment: Alignment.center,
              children: [
                _buildFallback(effectiveBg, effectiveFg, effectiveFontSize),
                Positioned.fill(
                  child: Container(
                    color: Colors.black12,
                    child: Center(
                      child: SizedBox(
                        width: radius,
                        height: radius,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          color: effectiveFg,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    } else {
      avatarContent = _buildFallback(effectiveBg, effectiveFg, effectiveFontSize);
    }

    Widget result = SizedBox(
      width: diameter,
      height: diameter,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: avatarContent),
          if (badge != null)
            Positioned(
              right: 0,
              bottom: 0,
              child: badge!,
            ),
          if (showEditBadge)
            Positioned(
              right: -2,
              bottom: -2,
              child: Material(
                color: AppColors.primary,
                shape: const CircleBorder(),
                elevation: 2,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onEditTap ?? onTap,
                  child: Padding(
                    padding: EdgeInsets.all(radius > 25 ? 5 : 3),
                    child: Icon(
                      Icons.camera_alt,
                      size: radius > 25 ? 14 : 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (onTap != null) {
      result = InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: result,
      );
    }

    if (tooltip != null) {
      result = Tooltip(
        message: tooltip!,
        child: result,
      );
    }

    return result;
  }

  Widget _buildFallback(Color bg, Color fg, double fontSz) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        _initial,
        style: TextStyle(
          color: fg,
          fontSize: fontSz,
          fontWeight: FontWeight.bold,
          height: 1,
        ),
      ),
    );
  }
}

/// A modal dialog that allows the signed-in user to preview, upload, change,
/// or remove their profile image.
class AvatarEditDialog extends ConsumerStatefulWidget {
  const AvatarEditDialog({
    super.key,
    required this.user,
    this.onUpdated,
  });

  final AuthUser user;
  final ValueChanged<AuthUser>? onUpdated;

  static Future<void> show(
    BuildContext context, {
    required AuthUser user,
    ValueChanged<AuthUser>? onUpdated,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AvatarEditDialog(user: user, onUpdated: onUpdated),
    );
  }

  @override
  ConsumerState<AvatarEditDialog> createState() => _AvatarEditDialogState();
}

class _AvatarEditDialogState extends ConsumerState<AvatarEditDialog> {
  Uint8List? _selectedBytes;
  String? _selectedFileName;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    try {
      final files = await FilePicker.pickFiles(type: FileType.image);
      if (files.isNotEmpty) {
        final file = files.first;
        final bytes = await file.readAsBytes();
        setState(() {
          _selectedBytes = Uint8List.fromList(bytes);
          _selectedFileName = file.name;
        });
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Failed to pick image: $e');
      }
    }
  }

  Future<void> _saveAvatar() async {
    if (_selectedBytes == null || _selectedFileName == null) return;

    setState(() => _isLoading = true);
    try {
      final updatedUser = await ref.read(authControllerProvider.notifier).uploadAvatar(
            _selectedBytes!,
            _selectedFileName!,
          );
      if (mounted) {
        AppToast.success(context, 'Profile picture updated successfully');
        widget.onUpdated?.call(updatedUser);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Failed to upload photo: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _removeAvatar() async {
    setState(() => _isLoading = true);
    try {
      final updatedUser = await ref.read(authControllerProvider.notifier).deleteAvatar();
      if (mounted) {
        AppToast.success(context, 'Profile photo removed');
        widget.onUpdated?.call(updatedUser);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Failed to remove photo: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentAvatarUrl = widget.user.avatarUrl;
    final hasCurrentAvatar = currentAvatarUrl != null && currentAvatarUrl.trim().isNotEmpty;
    final hasSelectedNew = _selectedBytes != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Profile Photo',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Avatar Display Preview
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3), width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: hasSelectedNew
                            ? Image.memory(
                                _selectedBytes!,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              )
                            : UserAvatar(
                                name: widget.user.name,
                                avatarUrl: widget.user.avatarUrl,
                                radius: 60,
                                fontSize: 44,
                              ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Material(
                        color: AppColors.primary,
                        shape: const CircleBorder(),
                        elevation: 3,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _isLoading ? null : _pickImage,
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.photo_camera, size: 20, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // User Info
              Text(
                widget.user.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                widget.user.email,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Action Buttons
              if (hasSelectedNew) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                setState(() {
                                  _selectedBytes = null;
                                  _selectedFileName = null;
                                });
                              },
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check, size: 18),
                        label: Text(_isLoading ? 'Saving...' : 'Save Photo'),
                        onPressed: _isLoading ? null : _saveAvatar,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.file_upload_outlined, size: 18),
                    label: const Text('Upload New Photo'),
                    onPressed: _isLoading ? null : _pickImage,
                  ),
                ),
                if (hasCurrentAvatar) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.rose,
                        side: const BorderSide(color: AppColors.rose),
                      ),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.rose),
                            )
                          : const Icon(Icons.delete_outline, size: 18),
                      label: Text(_isLoading ? 'Removing...' : 'Remove Photo'),
                      onPressed: _isLoading ? null : _removeAvatar,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
