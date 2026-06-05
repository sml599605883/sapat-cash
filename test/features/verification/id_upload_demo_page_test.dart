import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sapat_cash/src/features/verification/pages/id_upload_demo_page.dart';

void main() {
  group('pickImageWithLoading', () {
    test('dismisses loading when image picking is cancelled', () async {
      var showCount = 0;
      var dismissCount = 0;

      final result = await pickImageWithLoading(
        pickImage: () async => null,
        showLoading: () {
          showCount++;
        },
        dismissLoading: () {
          dismissCount++;
        },
      );

      expect(result, isNull);
      expect(showCount, 1);
      expect(dismissCount, 1);
    });

    test('returns picked file and dismisses loading after success', () async {
      var dismissCount = 0;
      final file = XFile('/tmp/mock.jpg');

      final result = await pickImageWithLoading(
        pickImage: () async => file,
        showLoading: () {},
        dismissLoading: () {
          dismissCount++;
        },
      );

      expect(result, same(file));
      expect(dismissCount, 1);
    });
  });
}
