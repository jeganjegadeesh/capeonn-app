// ignore_for_file: avoid_relative_lib_imports
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/core/network/api_exception.dart';

DioException _badResponse(int status, dynamic data) {
  final request = RequestOptions(path: '/x');
  return DioException(
    requestOptions: request,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: request, statusCode: status, data: data),
  );
}

void main() {
  test('reads the message and field errors from a 422 response', () {
    final e = ApiException.fromDio(_badResponse(422, {
      'success': false,
      'message': 'Validation failed',
      'errors': {
        'email': ['These credentials do not match our records.'],
      },
    }));

    expect(e.statusCode, 422);
    expect(e.isValidation, isTrue);
    expect(e.fieldError('email'), 'These credentials do not match our records.');
    expect(e.displayMessage, 'These credentials do not match our records.');
  });

  test('falls back to the server message when there are no field errors', () {
    final e = ApiException.fromDio(_badResponse(403, {
      'success': false,
      'message': 'Your account is deactivated. Please contact your administrator.',
      'errors': null,
    }));

    expect(e.isForbidden, isTrue);
    expect(e.displayMessage, contains('deactivated'));
  });

  test('401 is flagged as unauthorized', () {
    final e = ApiException.fromDio(_badResponse(401, {'success': false, 'message': 'Unauthenticated.', 'errors': null}));

    expect(e.isUnauthorized, isTrue);
  });

  test('network failures get a friendly message', () {
    final e = ApiException.fromDio(DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: DioExceptionType.connectionError,
    ));

    expect(e.statusCode, isNull);
    expect(e.message, contains('Cannot reach the server'));
  });

  test('a non-JSON error body still produces a message', () {
    final e = ApiException.fromDio(_badResponse(500, '<html>oops</html>'));

    expect(e.statusCode, 500);
    expect(e.message, isNotEmpty);
  });

  test('ApiException.toString() returns displayMessage without prefixes', () {
    final e = ApiException('Status transition from \'in_progress\' to \'completed\' is not permitted', statusCode: 422);

    expect(e.toString(), 'Status transition from \'in_progress\' to \'completed\' is not permitted');
    expect(e.toString(), isNot(contains('ApiException(422):')));
  });

  test('ApiException.cleanMessage removes Unhandled Exception and ApiException prefixes', () {
    const raw = "Unhandled Exception: ApiException(422): Status transition from 'in_progress' to 'completed' is not permitted";
    final cleaned = ApiException.cleanMessage(raw);

    expect(cleaned, "Status transition from 'in_progress' to 'completed' is not permitted");
  });

  test('ApiException.cleanMessage handles ApiException instances directly', () {
    final e = ApiException('Custom user error', statusCode: 400);
    final cleaned = ApiException.cleanMessage(e);

    expect(cleaned, 'Custom user error');
  });

  test('ApiException.cleanMessage handles Exception: and Error: prefixes', () {
    expect(ApiException.cleanMessage('Exception: Something failed'), 'Something failed');
    expect(ApiException.cleanMessage('Error: Server is unreachable'), 'Server is unreachable');
    expect(ApiException.cleanMessage(null), '');
  });
}

