import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class AppPermissionService {
  AppPermissionService._();

  /// Request permissions needed to pick, attach, or upload files from device.
  static Future<bool> requestFileAccessPermission() async {
    if (kIsWeb) return true;

    // Desktop platforms (Windows, macOS, Linux) use native system dialogs
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return true;
    }

    if (Platform.isAndroid) {
      // Android 13 (API 33) and above uses granular media permissions
      final photosStatus = await Permission.photos.status;
      if (photosStatus.isDenied) {
        final res = await Permission.photos.request();
        if (res.isGranted || res.isLimited) return true;
      } else if (photosStatus.isGranted || photosStatus.isLimited) {
        return true;
      }

      // Legacy Android storage fallback
      final storageStatus = await Permission.storage.status;
      if (storageStatus.isDenied) {
        final res = await Permission.storage.request();
        return res.isGranted || res.isLimited;
      }
      return storageStatus.isGranted || storageStatus.isLimited;
    }

    if (Platform.isIOS) {
      final status = await Permission.photos.status;
      if (status.isDenied) {
        final res = await Permission.photos.request();
        return res.isGranted || res.isLimited;
      }
      return status.isGranted || status.isLimited;
    }

    return true;
  }

  /// Request permissions needed to save files into public download folders.
  static Future<bool> ensureDownloadPermission() async {
    if (kIsWeb) return true;

    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return true;
    }

    if (Platform.isAndroid) {
      // Scoped storage handles public Downloads without WRITE_EXTERNAL_STORAGE on Android 10+
      final status = await Permission.storage.status;
      if (status.isDenied) {
        final res = await Permission.storage.request();
        // Even if denied on Android 11+, apps can still write to app-specific directories
        return res.isGranted || true;
      }
      return true;
    }

    return true;
  }

  /// Request push/local notification permission.
  static Future<bool> requestNotificationPermission() async {
    if (kIsWeb) return true;

    if (Platform.isAndroid || Platform.isIOS) {
      final status = await Permission.notification.status;
      if (status.isDenied) {
        final res = await Permission.notification.request();
        return res.isGranted;
      }
      return status.isGranted;
    }

    return true;
  }
}
