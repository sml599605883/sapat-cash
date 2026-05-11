import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sapat_cash/src/core/json/json.dart';

void main() {
  group('Json helper', () {
    test('parses string and supports chained reads', () {
      final json = Json.parse('{"user":{"name":"alice","age":"18"}}');

      expect(json['user']['name'].stringValue, 'alice');
      expect(json['user']['age'].intValue, 18);
      expect(json['missing']['field'].stringValue, '');
      expect(json['missing']['field'].stringOrNull, isNull);
    });

    test('parses bytes safely and degrades on invalid input', () {
      final valid = Json.parseBytes(utf8.encode('{"flag":1}'));
      final invalid = Json.parse('{bad json}');

      expect(valid['flag'].boolValue, isTrue);
      expect(invalid.isNull(), isTrue);
      expect(invalid.mapValue, isEmpty);
    });

    test('converts scalar values with safe defaults', () {
      expect(Json('yes').boolValue, isTrue);
      expect(Json('0').boolValue, isFalse);
      expect(Json(true).numValue, 1);
      expect(Json('12.5').doubleValue, 12.5);
      expect(Json(3).stringValue, '3');
      expect(Json(<String, dynamic>{}).stringValue, '');
    });

    test('supports map and list writes plus remove', () {
      final mapJson = Json();
      mapJson['name'] = 'bob';
      mapJson['enabled'] = Json('true');

      expect(mapJson['name'].stringValue, 'bob');
      expect(mapJson['enabled'].boolValue, isTrue);

      final listJson = Json();
      listJson[1] = 'second';
      listJson[0] = 'first';

      expect(listJson[0].stringValue, 'first');
      expect(listJson[1].stringValue, 'second');

      mapJson.remove('name');
      listJson.remove(0);

      expect(mapJson['name'].stringOrNull, isNull);
      expect(listJson[0].stringValue, 'second');
    });

    test('serializes raw and pretty json', () {
      final json = Json(<String, dynamic>{
        'name': 'alice',
        'list': <int>[1, 2],
      });

      expect(json.rawString(), '{"name":"alice","list":[1,2]}');
      expect(json.toString(), json.rawString());
      expect(json.prettyPrint, contains('\n'));
      expect(json.prettyPrint, contains('"name"'));
    });
  });
}
