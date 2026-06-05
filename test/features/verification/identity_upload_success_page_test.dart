import 'package:flutter_test/flutter_test.dart';
import 'package:sapat_cash/src/features/verification/pages/identity_upload_success_page.dart';

void main() {
  group('parseIdentityBirthDate', () {
    test('returns default date for empty birth date', () {
      expect(parseIdentityBirthDate(''), defaultIdentityBirthDate());
    });

    test('returns default date for future birth date', () {
      expect(
        parseIdentityBirthDate(
          '2099-01-01',
          now: DateTime(2026, 6, 5),
        ),
        defaultIdentityBirthDate(),
      );
    });

    test('keeps valid recognized birth date', () {
      expect(
        parseIdentityBirthDate(
          '2001-02-03',
          now: DateTime(2026, 6, 5),
        ),
        DateTime(2001, 2, 3),
      );
    });
  });
}
