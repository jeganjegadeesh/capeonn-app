import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../widgets/app_toast.dart';
import 'app_permission_service.dart';

class FileDownloadService {
  FileDownloadService._();

  /// Resolve absolute reachable URL and download the file to the system Downloads folder.
  /// If [autoOpen] is true, opens the downloaded document/file with the native system viewer.
  static Future<String?> downloadFile({
    required BuildContext context,
    required String rawUrl,
    required String fileName,
    bool autoOpen = false,
  }) async {
    final resolvedUrl = AppConfig.resolveFileUrl(rawUrl);
    if (resolvedUrl.isEmpty) {
      if (context.mounted) {
        AppToast.error(context, 'Invalid file download URL');
      }
      return null;
    }

    // 1. Web platform: delegate to browser native download
    if (kIsWeb) {
      try {
        final uri = Uri.parse(resolvedUrl);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (context.mounted) {
          AppToast.success(context, 'Downloading $fileName in browser...');
        }
        return resolvedUrl;
      } catch (e) {
        if (context.mounted) {
          AppToast.error(context, 'Failed to launch file: $e');
        }
        return null;
      }
    }

    // 2. Request download/storage permissions on Android/iOS
    await AppPermissionService.ensureDownloadPermission();

    if (context.mounted) {
      AppToast.info(context, 'Downloading $fileName...');
    }

    try {
      final downloadDir = await getSystemDownloadDirectory();
      final sanitizedName = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      
      // Ensure unique filename if already exists
      String savePath = '${downloadDir.path}${Platform.pathSeparator}$sanitizedName';
      final file = File(savePath);
      if (await file.exists()) {
        final dotIdx = sanitizedName.lastIndexOf('.');
        final namePart = dotIdx != -1 ? sanitizedName.substring(0, dotIdx) : sanitizedName;
        final extPart = dotIdx != -1 ? sanitizedName.substring(dotIdx) : '';
        savePath = '${downloadDir.path}${Platform.pathSeparator}${namePart}_${DateTime.now().millisecondsSinceEpoch}$extPart';
      }

      // Download bytes using Dio
      final dio = Dio();
      await dio.download(
        resolvedUrl,
        savePath,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
        ),
      );

      if (context.mounted) {
        AppToast.success(
          context,
          'Saved to Downloads: ${savePath.split(Platform.pathSeparator).last}',
        );
      }

      // 3. Open file if requested
      if (autoOpen) {
        try {
          final result = await OpenFilex.open(savePath);
          if (result.type != ResultType.done && context.mounted) {
            AppToast.info(context, 'Saved in Downloads folder: $savePath');
          }
        } catch (_) {
          // OpenFilex fallback
        }
      }

      return savePath;
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, 'Download failed: $e');
      }
      return null;
    }
  }

  /// Locates the real system downloads directory across platforms.
  static Future<Directory> getSystemDownloadDirectory() async {
    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null && userProfile.isNotEmpty) {
        final winDownloads = Directory('$userProfile\\Downloads');
        if (await winDownloads.exists()) {
          return winDownloads;
        }
      }
    }

    if (Platform.isAndroid) {
      final publicDownloads = Directory('/storage/emulated/0/Download');
      if (await publicDownloads.exists()) {
        return publicDownloads;
      }
      try {
        final extDirs = await getExternalStorageDirectories(type: StorageDirectory.downloads);
        if (extDirs != null && extDirs.isNotEmpty) {
          return extDirs.first;
        }
      } catch (_) {}
    }

    if (Platform.isMacOS || Platform.isLinux) {
      final home = Platform.environment['HOME'];
      if (home != null) {
        final downloads = Directory('$home/Downloads');
        if (await downloads.exists()) {
          return downloads;
        }
      }
    }

    // Default fallbacks from path_provider
    try {
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null) {
        return downloadsDir;
      }
    } catch (_) {}

    return await getApplicationDocumentsDirectory();
  }
}
