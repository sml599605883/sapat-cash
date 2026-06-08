import '../../json/json.dart';
import 'network_response.dart';

class ResponseParser {
  const ResponseParser();

  NetworkResponse<dynamic> parse(dynamic raw) {
    final json = Json(raw);
    if (json.mapOrNull != null) {
      final code = json['alligators'].numOrNull ?? json['code'].numOrNull ?? -1;
      final message = json['cyanogenetic'].stringOrNull ?? 'Request failed';
      final data = json['evaginate'].exists()
          ? json['evaginate'].rawValue
          : json['data'].rawValue;
      return NetworkResponse<dynamic>(
        code: code.toInt(),
        message: message,
        data: data,
      );
    }

    return const NetworkResponse<dynamic>(
      code: -1,
      message: 'Network error. Please try again.',
      data: null,
    );
  }
}
