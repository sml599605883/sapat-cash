import 'package:flutter_test/flutter_test.dart';
import 'package:sapat_cash/src/features/home/widgets/home_top_section.dart';

void main() {
  group('resolveTopCardIconUrl', () {
    test('prefers icon image url when it is not empty', () {
      expect(
        resolveTopCardIconUrl(
          iconImageUrl: 'https://example.com/icon.png',
          productLogo: 'https://example.com/product.png',
        ),
        'https://example.com/icon.png',
      );
    });

    test('falls back to product logo when icon image url is empty', () {
      expect(
        resolveTopCardIconUrl(
          iconImageUrl: '  ',
          productLogo: 'https://example.com/product.png',
        ),
        'https://example.com/product.png',
      );
    });

    test('returns empty string when both urls are empty', () {
      expect(
        resolveTopCardIconUrl(iconImageUrl: '', productLogo: ' '),
        isEmpty,
      );
    });
  });
}
