import 'package:flutter_test/flutter_test.dart';
import 'package:sapat_cash/src/features/auth/auth_controller.dart';
import 'package:sapat_cash/src/features/auth/login_controller.dart';

void main() {
  group('LoginController login agreement', () {
    test('allows login submission only when privacy agreement is accepted', () {
      final controller = LoginController(AuthController());

      expect(controller.canSubmitLogin(), isTrue);

      controller.toggleAgreement();

      expect(controller.canSubmitLogin(), isFalse);
    });
  });
}
