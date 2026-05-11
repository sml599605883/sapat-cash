import '../../json/json.dart';
import '../config/network_config.dart';

class NetworkResponse<T> {
  const NetworkResponse({
    required this.code,
    required this.message,
    required this.data,
  });

  final int code;
  final String message;
  final T? data;

  bool get isSuccess => NetworkConfig.successCodes.contains(code);

  Json get json => Json(data);
}
