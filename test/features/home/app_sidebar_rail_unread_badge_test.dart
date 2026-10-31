import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/features/home/presentation/components/app_sidebar_rail.dart';

void main() {
  group('totalUnreadDmCount', () {
    test('returns 0 when there are no conversations', () {
      expect(totalUnreadDmCount(const []), 0);
    });

    test('sums unread counts across conversations', () {
      expect(totalUnreadDmCount(const [2, 0, 5]), 7);
    });
  });

  group('unreadBadgeLabel', () {
    test('shows the exact count up to 99', () {
      expect(unreadBadgeLabel(1), '1');
      expect(unreadBadgeLabel(99), '99');
    });

    test('caps at 99+ above 99', () {
      expect(unreadBadgeLabel(100), '99+');
      expect(unreadBadgeLabel(250), '99+');
    });
  });
}