import 'package:dio/dio.dart';

/// Every failed API call becomes one of these, so screens never deal with Dio directly.
/// The backend always answers errors as { success: false, message, errors }.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.errors = const {}});

  final String message;
  final int? statusCode;

  /// Field -> messages, only present for validation errors (422).
  final Map<String, List<String>> errors;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isValidation => statusCode == 422;

  String? fieldError(String field) {
    final list = errors[field];
    return (list == null || list.isEmpty) ? null : list.first;
  }

  /// The single best message to show the user: the first field error, else the server message.
  String get displayMessage {
    if (isForbidden) {
      return message.isNotEmpty ? message : "You don't have permission to perform this action.";
    }
    if (isNotFound) {
      return message.isNotEmpty ? message : 'The requested resource was not found.';
    }
    if (isUnauthorized) {
      return message.isNotEmpty ? message : 'Your session has expired. Please sign in again.';
    }
    for (final messages in errors.values) {
      if (messages.isNotEmpty) return messages.first;
    }
    return message;
  }

  factory ApiException.fromDio(DioException e) {
    final response = e.response;
    final data = response?.data;

    if (response != null && data is Map) {
      final rawMessage = data['message'];
      final errors = <String, List<String>>{};
      final rawErrors = data['errors'];
      if (rawErrors is Map) {
        rawErrors.forEach((key, value) {
          if (value is List) {
            errors['$key'] = value.map((v) => '$v').toList();
          } else if (value != null) {
            errors['$key'] = ['$value'];
          }
        });
      }
      final fallbackMessage = switch (response.statusCode) {
        403 => "You don't have permission to perform this action.",
        404 => 'The requested resource was not found.',
        401 => 'Your session has expired. Please sign in again.',
        422 => 'Please review the highlighted fields.',
        _ => 'Something went wrong.',
      };
      return ApiException(
        rawMessage is String && rawMessage.isNotEmpty ? rawMessage : fallbackMessage,
        statusCode: response.statusCode,
        errors: errors,
      );
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException('The server took too long to respond. Please try again.');
      case DioExceptionType.connectionError:
        return ApiException('Cannot reach the server. Check your internet connection.');
      default:
        return ApiException(
          response != null
              ? 'Unexpected server response (${response.statusCode}).'
              : 'Something went wrong. Please try again.',
          statusCode: response?.statusCode,
        );
    }
  }

  /// Returns a clean, user-friendly error message stripped of system/framework
  /// prefixes like "Unhandled Exception:", "ApiException(422):", "Exception:", etc.
  static String cleanMessage(dynamic error) {
    if (error == null) return '';
    if (error is ApiException) {
      return error.displayMessage;
    }
    String msg = error.toString().trim();
    // Recursively strip common exception wrappers/prefixes
    bool changed = true;
    while (changed) {
      final prev = msg;
      msg = msg
          .replaceFirst(RegExp(r'^Unhandled Exception:\s*', caseSensitive: false), '')
          .replaceFirst(RegExp(r'^ApiException(\(\d+\))?:\s*', caseSensitive: false), '')
          .replaceFirst(RegExp(r'^Exception:\s*', caseSensitive: false), '')
          .replaceFirst(RegExp(r'^Error:\s*', caseSensitive: false), '')
          .trim();
      changed = (prev != msg);
    }
    return msg.isNotEmpty ? msg : 'An unexpected error occurred.';
  }

  @override
  String toString() => displayMessage;
}

