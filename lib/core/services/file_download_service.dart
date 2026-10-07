import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import '../widgets/app_toast.dart';
import 'app_permission_service.dart';
import 'web_file_downloader.dart';

class FileDownloadService {
  FileDownloadService._();

  /// Categorize file into standard media type folder for mobile storage:
  /// capeonn/(mediatype)/file
  static String getMediaTypeFolder(String fileName, String? mimeType) {
    final lower = fileName.toLowerCase();
    final mime = mimeType?.toLowerCase() ?? '';

    if (mime.startsWith('image/') ||
        lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.svg') ||
        lower.endsWith('.bmp')) {
      return 'images';
    }

    if (mime == 'application/pdf' || lower.endsWith('.pdf')) {
      return 'pdf';
    }

    if (mime.startsWith('video/') ||
        lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.webm')) {
      return 'videos';
    }

    if (mime.startsWith('audio/') ||
        lower.endsWith('.mp3') ||
        lower.endsWith('.wav') ||
        lower.endsWith('.aac') ||
        lower.endsWith('.m4a') ||
        lower.endsWith('.ogg') ||
        lower.endsWith('.flac')) {
      return 'audio';
    }

    return 'documents';
  }

  /// Resolve absolute reachable URL and download the file.
  /// - Windows: Saved to Windows Downloads folder (e.g. C:\Users\<user>\Downloads)
  /// - Web: Trigger native browser file download into local Downloads folder
  /// - Mobile (Android/iOS): Saved to capeonn/(mediatype)/filename in local storage
  static Future<String?> downloadFile({
    required BuildContext context,
    required String rawUrl,
    required String fileName,
    String? mimeType,
    bool autoOpen = false,
  }) async {
    final token = await TokenStorage().read();
    final resolvedUrl = AppConfig.resolveFileUrl(rawUrl, token: token);

    if (resolvedUrl.isEmpty) {
      if (context.mounted) {
        AppToast.error(context, 'Invalid file download URL');
      }
      return null;
    }

    // 1. Web platform: Authenticated download via Dio and browser Blob anchor
    if (kIsWeb) {
      if (context.mounted) {
        AppToast.info(context, 'Downloading $fileName...');
      }

      try {
        final dio = Dio();
        final response = await dio.get<List<int>>(
          resolvedUrl,
          options: Options(
            responseType: ResponseType.bytes,
            headers: (token != null && token.isNotEmpty)
                ? {'Authorization': 'Bearer $token'}
                : null,
            followRedirects: true,
          ),
        );

        if (response.data != null && response.data!.isNotEmpty) {
          final downloaded = await downloadFileOnWeb(response.data!, fileName);
          if (downloaded) {
            if (context.mounted) {
              AppToast.success(context, 'Downloaded $fileName to Downloads folder');
            }
            return resolvedUrl;
          }
        }

        // Fallback for Web: open authenticated URL with token
        final uri = Uri.parse(resolvedUrl);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (context.mounted) {
          AppToast.success(context, 'Downloading $fileName in browser...');
        }
        return resolvedUrl;
      } catch (e) {
        if (context.mounted) {
          AppToast.error(context, 'Download failed: $e');
        }
        return null;
      }
    }

    // 2. Mobile platforms: ensure storage/download permissions
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      await AppPermissionService.ensureDownloadPermission();
    }

    if (context.mounted) {
      AppToast.info(context, 'Downloading $fileName...');
    }

    try {
      final sanitizedName = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final targetDirectory = await _getTargetDownloadDirectory(fileName, mimeType);

      // Ensure unique filename if already exists
      String savePath = '${targetDirectory.path}${Platform.pathSeparator}$sanitizedName';
      final file = File(savePath);
      if (await file.exists()) {
        final dotIdx = sanitizedName.lastIndexOf('.');
        final namePart = dotIdx != -1 ? sanitizedName.substring(0, dotIdx) : sanitizedName;
        final extPart = dotIdx != -1 ? sanitizedName.substring(dotIdx) : '';
        savePath = '${targetDirectory.path}${Platform.pathSeparator}${namePart}_${DateTime.now().millisecondsSinceEpoch}$extPart';
      }

      // Download bytes using authenticated Dio instance
      final dio = Dio();
      await dio.download(
        resolvedUrl,
        savePath,
        options: Options(
          responseType: ResponseType.bytes,
          headers: (token != null && token.isNotEmpty)
              ? {'Authorization': 'Bearer $token'}
              : null,
          followRedirects: true,
        ),
      );

      final finalFileName = savePath.split(Platform.pathSeparator).last;

      if (context.mounted) {
        if (!kIsWeb && Platform.isWindows) {
          AppToast.success(context, 'Saved to Downloads: $finalFileName');
        } else if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
          final mediaFolder = getMediaTypeFolder(fileName, mimeType);
          AppToast.success(context, 'Saved to capeonn/$mediaFolder: $finalFileName');
        } else {
          AppToast.success(context, 'Saved: $finalFileName');
        }
      }

      // Open file if requested
      if (autoOpen) {
        try {
          final result = await OpenFilex.open(savePath);
          if (result.type != ResultType.done && context.mounted) {
            AppToast.info(context, 'File saved: $savePath');
          }
        } catch (_) {}
      }

      return savePath;
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, 'Download failed: $e');
      }
      return null;
    }
  }

  /// Resolve destination directory according to user requirements:
  /// - Windows: C:\Users\<user>\Downloads
  /// - Android/iOS Mobile: capeonn/(mediatype)/
  /// - macOS/Linux: ~/Downloads
  static Future<Directory> _getTargetDownloadDirectory(String fileName, String? mimeType) async {
    final mediaFolder = getMediaTypeFolder(fileName, mimeType);

    // 1. Windows: strictly C:\Users\<username>\Downloads
    if (!kIsWeb && Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null && userProfile.isNotEmpty) {
        final winDownloads = Directory('$userProfile\\Downloads');
        if (!await winDownloads.exists()) {
          await winDownloads.create(recursive: true);
        }
        return winDownloads;
      }
      try {
        final d = await getDownloadsDirectory();
        if (d != null) return d;
      } catch (_) {}
    }

    // 2. Mobile Android: store in mobile local storage in the folder capeonn/(mediatype)/
    if (!kIsWeb && Platform.isAndroid) {
      final publicDownloads = Directory('/storage/emulated/0/Download');
      if (await publicDownloads.exists()) {
        final capeonnDir = Directory('${publicDownloads.path}/capeonn/$mediaFolder');
        if (!await capeonnDir.exists()) {
          await capeonnDir.create(recursive: true);
        }
        return capeonnDir;
      }

      try {
        final extDirs = await getExternalStorageDirectories(type: StorageDirectory.downloads);
        if (extDirs != null && extDirs.isNotEmpty) {
          final capeonnDir = Directory('${extDirs.first.path}/capeonn/$mediaFolder');
          if (!await capeonnDir.exists()) {
            await capeonnDir.create(recursive: true);
          }
          return capeonnDir;
        }
      } catch (_) {}
    }

    // 3. Mobile iOS / Fallback: app documents directory with capeonn/(mediatype)
    if (!kIsWeb && Platform.isIOS) {
      final docDir = await getApplicationDocumentsDirectory();
      final capeonnDir = Directory('${docDir.path}/capeonn/$mediaFolder');
      if (!await capeonnDir.exists()) {
        await capeonnDir.create(recursive: true);
      }
      return capeonnDir;
    }

    // 4. macOS / Linux: ~/Downloads
    if (!kIsWeb && (Platform.isMacOS || Platform.isLinux)) {
      final home = Platform.environment['HOME'];
      if (home != null) {
        final downloads = Directory('$home/Downloads');
        if (await downloads.exists()) {
          return downloads;
        }
      }
    }

    // Default fallback
    try {
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null) return downloadsDir;
    } catch (_) {}

    return await getApplicationDocumentsDirectory();
  }

  /// Locates the real system downloads directory across platforms (public helper).
  static Future<Directory> getSystemDownloadDirectory() async {
    return _getTargetDownloadDirectory('', null);
  }
}
