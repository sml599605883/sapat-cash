import 'package:flutter_test/flutter_test.dart';
import 'package:sapat_cash/src/features/home/home_models.dart';
import 'package:sapat_cash/src/features/home/widgets/home_progress_module.dart';

void main() {
  group('resolveHomeProgressActionKind', () {
    test('maps retry raw type to retry action', () {
      expect(
        resolveHomeProgressActionKind(
          const HomeActionButton(
            type: HomeActionType.retry,
            rawType: 'retry',
            enabled: true,
            text: 'Retry Original Account',
          ),
        ),
        HomeProgressActionKind.retry,
      );
    });

    test('maps change raw type to change-account action', () {
      expect(
        resolveHomeProgressActionKind(
          const HomeActionButton(
            type: HomeActionType.change,
            rawType: 'change',
            enabled: true,
            text: 'Change Account',
          ),
        ),
        HomeProgressActionKind.changeAccount,
      );
    });

    test('keeps repay as detail action', () {
      expect(
        resolveHomeProgressActionKind(
          const HomeActionButton(
            type: HomeActionType.repay,
            rawType: 'repay',
            enabled: true,
            text: 'Repay',
          ),
        ),
        HomeProgressActionKind.detail,
      );
    });
  });
}
