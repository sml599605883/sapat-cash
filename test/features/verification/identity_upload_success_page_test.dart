import 'package:flutter_test/flutter_test.dart';
import 'package:sapat_cash/src/features/verification/pages/identity_upload_success_page.dart';

void main() {
  group('calculateIdentityKeyboardOverlap', () {
    test('returns zero when keyboard is hidden', () {
      expect(
        calculateIdentityKeyboardOverlap(
          fieldBottom: 600,
          viewportHeight: 800,
          keyboardInset: 0,
          bottomSpacing: 12,
        ),
        0,
      );
    });

    test('returns zero when field is above keyboard top', () {
      expect(
        calculateIdentityKeyboardOverlap(
          fieldBottom: 500,
          viewportHeight: 800,
          keyboardInset: 240,
          bottomSpacing: 12,
        ),
        0,
      );
    });

    test('returns overlap when field is covered by keyboard', () {
      expect(
        calculateIdentityKeyboardOverlap(
          fieldBottom: 620,
          viewportHeight: 800,
          keyboardInset: 240,
          bottomSpacing: 12,
        ),
        72,
      );
    });
  });

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
