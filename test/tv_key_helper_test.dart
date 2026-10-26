import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_tv_app/utils/tv_key_helper.dart';

KeyDownEvent _down(LogicalKeyboardKey logical, PhysicalKeyboardKey physical) =>
    KeyDownEvent(
      physicalKey: physical,
      logicalKey: logical,
      timeStamp: Duration.zero,
    );

KeyUpEvent _up(LogicalKeyboardKey logical, PhysicalKeyboardKey physical) =>
    KeyUpEvent(
      physicalKey: physical,
      logicalKey: logical,
      timeStamp: Duration.zero,
    );

void main() {
  group('isTvActivateEvent', () {
    test('select fires once when both KeyDown and KeyUp are delivered', () {
      final down = _down(LogicalKeyboardKey.select, PhysicalKeyboardKey.select);
      final up = _up(LogicalKeyboardKey.select, PhysicalKeyboardKey.select);

      expect(isTvActivateEvent(down), isTrue);
      expect(isTvActivateEvent(up), isFalse);
    });

    test('select fires on KeyUp alone (remotes that skip KeyDown)', () {
      final up = _up(LogicalKeyboardKey.select, PhysicalKeyboardKey.select);

      expect(isTvActivateEvent(up), isTrue);
      // The guard is reset, so a second KeyUp-only press fires again.
      expect(isTvActivateEvent(up), isTrue);
    });

    test('enter fires on KeyDown only', () {
      final down = _down(LogicalKeyboardKey.enter, PhysicalKeyboardKey.enter);
      final up = _up(LogicalKeyboardKey.enter, PhysicalKeyboardKey.enter);

      expect(isTvActivateEvent(down), isTrue);
      expect(isTvActivateEvent(up), isFalse);
    });

    test('mediaPlayPause activates only when explicitly included', () {
      final down = _down(
        LogicalKeyboardKey.mediaPlayPause,
        PhysicalKeyboardKey.mediaPlayPause,
      );

      expect(isTvActivateEvent(down), isFalse);
      expect(isTvActivateEvent(down, includeMediaPlayPause: true), isTrue);
    });

    test('unrelated keys are ignored', () {
      final down = _down(
        LogicalKeyboardKey.arrowDown,
        PhysicalKeyboardKey.arrowDown,
      );

      expect(isTvActivateEvent(down), isFalse);
    });
  });

  group('isTvBackEvent', () {
    test('back fires once when both KeyDown and KeyUp are delivered', () {
      final down = _down(LogicalKeyboardKey.goBack, PhysicalKeyboardKey.escape);
      final up = _up(LogicalKeyboardKey.goBack, PhysicalKeyboardKey.escape);

      expect(isTvBackEvent(down), isTrue);
      expect(isTvBackEvent(up), isFalse);
    });

    test('back fires on KeyUp alone', () {
      final up = _up(LogicalKeyboardKey.escape, PhysicalKeyboardKey.escape);

      expect(isTvBackEvent(up), isTrue);
    });

    test('non-back keys are ignored', () {
      final down = _down(LogicalKeyboardKey.enter, PhysicalKeyboardKey.enter);

      expect(isTvBackEvent(down), isFalse);
    });
  });
}
