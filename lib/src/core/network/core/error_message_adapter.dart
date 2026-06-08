import 'package:dio/dio.dart';

import 'business_exception.dart';

class ErrorMessageAdapter {
  const ErrorMessageAdapter._();

  static String resolve(Object? error) {
    if (error == null) {
      return 'Something went wrong. Please try again.';
    }
    if (error is BusinessException) {
      return error.message;
    }
    if (error is DioException) {
      if (error.type == .sendTimeout ||
          error.type == .receiveTimeout ||
          error.type == .connectionTimeout) {
        return 'Request timed out. Tap to retry.';
      } else if (error.message != null && error.message!.trim().isNotEmpty) {
        return error.message!;
      }
      return 'Network error. Please try again.';
    }
    return error.toString();
  }
}
