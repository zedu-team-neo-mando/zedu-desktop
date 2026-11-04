import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/features/dms/domain/notification_service.dart';

void main() {
  group('truncateNotificationPreview', () {
    test('leaves a short message untouched', () {
      const text = 'short message';
      expect(truncateNotificationPreview(text), text);
    });

    test('leaves a message at the boundary untouched', () {
      final text = 'a' * 80;
      expect(truncateNotificationPreview(text), text);
    });

    test('truncates a long message to 77 characters plus an ellipsis', () {
      final text = 'a' * 100;
      final result = truncateNotificationPreview(text);
      expect(result, '${'a' * 77}...');
      expect(result.length, 80);
    });

    test('never splits a surrogate pair at the cut point', () {
      // A non-BMP emoji occupies two UTF-16 code units. Place it so that a
      // naive substring(0, 77) would cut between its high and low surrogate.
      final emoji = String.fromCharCodes([0x1F600]); // 😀
      final prefix = 'a' * 76;
      final text = '$prefix$emoji${'b' * 30}';

      // Confirm the naive cut would have landed mid-pair.
      expect(text.codeUnitAt(76) & 0xFC00, 0xD800);

      final result = truncateNotificationPreview(text);

      // The surrogate pair must stay whole, so the emoji is dropped entirely
      // and the cut backs off one code unit.
      expect(result, '${'a' * 76}...');
      expect(result.contains(emoji), isFalse);
      // No lone surrogate survived into the preview.
      for (var i = 0; i < result.length; i++) {
        final unit = result.codeUnitAt(i);
        if (unit & 0xFC00 == 0xDC00) {
          expect(i, greaterThan(0));
          expect(result.codeUnitAt(i - 1) & 0xFC00, 0xD800);
        }
      }
    });

    test('keeps a surrogate pair that ends exactly at the cut point', () {
      final emoji = String.fromCharCodes([0x1F600]);
      final text = '${'a' * 75}$emoji${'b' * 30}';

      final result = truncateNotificationPreview(text);

      // The pair ends at index 76, so it is entirely before the cut.
      expect(result, '${'a' * 75}$emoji...');
      expect(result.contains(emoji), isTrue);
    });
  });
}
