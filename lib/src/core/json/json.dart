import 'dart:convert';
import 'dart:typed_data';

class Json {
  Json([dynamic value]) : _value = value;

  dynamic _value;

  factory Json.parse(String source) {
    try {
      return Json(jsonDecode(source));
    } catch (_) {
      return Json();
    }
  }

  factory Json.parseBytes(List<int> bytes) {
    try {
      return Json.parse(utf8.decode(bytes));
    } catch (_) {
      return Json();
    }
  }

  dynamic get rawValue => _value;

  bool exists() => _value != null;

  bool isNull() => _value == null;

  Map<String, dynamic> get mapValue => mapOrNull ?? <String, dynamic>{};

  Map<String, dynamic>? get mapOrNull {
    final value = _value;
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return null;
  }

  List<dynamic> get listValue => listOrNull ?? <dynamic>[];

  List<dynamic>? get listOrNull {
    final value = _value;
    if (value is List<dynamic>) {
      return value;
    }
    if (value is List) {
      return List<dynamic>.from(value);
    }
    return null;
  }

  bool get boolValue => boolOrNull ?? false;

  bool? get boolOrNull {
    final value = _value;
    if (value == null) {
      return null;
    }
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized.isEmpty) {
        return null;
      }
      return const {'true', 'y', 't', 'yes', '1'}.contains(normalized);
    }
    return null;
  }

  num get numValue => numOrNull ?? 0;

  num? get numOrNull {
    final value = _value;
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value;
    }
    if (value is bool) {
      return value ? 1 : 0;
    }
    if (value is String) {
      final normalized = value.trim();
      if (normalized.isEmpty) {
        return null;
      }
      return int.tryParse(normalized) ?? double.tryParse(normalized);
    }
    return null;
  }

  int get intValue => numValue.toInt();

  int? get intOrNull => numOrNull?.toInt();

  double get doubleValue => numValue.toDouble();

  double? get doubleOrNull => numOrNull?.toDouble();

  String get stringValue => stringOrNull ?? '';

  String? get stringOrNull {
    final value = _value;
    if (value == null) {
      return null;
    }
    if (value is String) {
      return value;
    }
    if (value is num || value is bool) {
      return value.toString();
    }
    return null;
  }

  Json operator [](dynamic key) {
    final value = _value;
    if (key is String && value is Map) {
      if (!value.containsKey(key)) {
        return Json();
      }
      return Json(value[key]);
    }
    if (key is int && value is List) {
      if (key < 0 || key >= value.length) {
        return Json();
      }
      return Json(value[key]);
    }
    return Json();
  }

  void operator []=(dynamic key, dynamic value) {
    if (key is String) {
      final map = mapOrNull ?? <String, dynamic>{};
      map[key] = _unwrap(value);
      _value = map;
      return;
    }
    if (key is int) {
      final list = listOrNull ?? <dynamic>[];
      while (list.length <= key) {
        list.add(null);
      }
      list[key] = _unwrap(value);
      _value = list;
    }
  }

  dynamic remove(dynamic key) {
    final value = _value;
    if (key is String && value is Map) {
      return value.remove(key);
    }
    if (key is int && value is List && key >= 0 && key < value.length) {
      return value.removeAt(key);
    }
    return null;
  }

  String rawString() {
    try {
      return jsonEncode(_value);
    } catch (_) {
      return 'null';
    }
  }

  String get prettyPrint {
    try {
      return const JsonEncoder.withIndent('  ').convert(_value);
    } catch (_) {
      return 'null';
    }
  }

  @override
  String toString() => rawString();

  dynamic _unwrap(dynamic value) {
    if (value is Json) {
      return value.rawValue;
    }
    if (value is Uint8List) {
      return Json.parseBytes(value).rawValue;
    }
    return value;
  }
}
