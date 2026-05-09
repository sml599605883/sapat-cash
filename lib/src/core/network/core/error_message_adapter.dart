import 'package:dio/dio.dart';

import 'business_exception.dart';

class ErrorMessageAdapter {
  const ErrorMessageAdapter._();

  static String resolve(Object? error) {
    if (error == null) {
      return 'Unexpected empty error';
    }
    if (error is BusinessException) {
      return error.message;
    }
    if (error is DioException) {
      if (error.message != null && error.message!.trim().isNotEmpty) {
        return error.message!;
      }
      return 'Network request failed';
    }
    return error.toString();
  }
}
