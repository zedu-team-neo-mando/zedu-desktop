import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/core/theme/app_theme.dart';
import 'package:zedu/features/home/presentation/widgets/message_bubble.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

Widget _wrapBottomRight(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.all(80),
          child: SizedBox(width: 420, child: child),
        ),
      ),
    ),
  );
}

void main() {
  group('MessageBubble Author Initial Tests', () {
    testWidgets('renders standard author initial correctly', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const MessageBubble(
            author: 'Alice',
            text: 'Hello world',
            timestamp: '10:00 AM',
          ),
        ),
      );

      expect(find.text('A'), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Hello world'), findsOneWidget);
    });

    testWidgets(
      'handles author name starting with emoji surrogate pair cleanly',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            const MessageBubble(
              author: '🚀 Astro',
              text: 'Rocket test',
              timestamp: '10:05 AM',
            ),
          ),
        );

        expect(find.text('🚀'), findsOneWidget);
        expect(find.text('🚀 Astro'), findsOneWidget);
      },
    );

    testWidgets('trims leading whitespace from author name for initial', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const MessageBubble(
            author: '   Bob',
            text: 'Indented author test',
            timestamp: '10:10 AM',
          ),
        ),
      );

      expect(find.text('B'), findsOneWidget);
    });

    testWidgets('renders fallback question mark for empty or blank author', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const MessageBubble(
            author: '   ',
            text: 'Blank author test',
            timestamp: '10:15 AM',
          ),
        ),
      );

      expect(find.text('?'), findsOneWidget);
    });
  });

  group('MessageBubble reaction picker', () {
    testWidgets('opens next to the reaction button, not at a fixed point', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapBottomRight(
          const MessageBubble(
            author: 'Ada',
            text: 'Hello world',
            timestamp: '10:00',
          ),
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.byType(MessageBubble)));
      await tester.pumpAndSettle();

      final button = find.byKey(const ValueKey('add-reaction-button'));
      expect(button, findsOneWidget);
      final buttonRect = tester.getRect(button);

      await tester.tap(button);
      await tester.pumpAndSettle();

      final menuItem = find.byType(PopupMenuItem<String>).first;
      expect(menuItem, findsOneWidget);
      final menuRect = tester.getRect(menuItem);
      final windowSize =
          tester.view.physicalSize / tester.view.devicePixelRatio;

      expect((menuRect.left - buttonRect.left).abs(), lessThan(300));
      expect((menuRect.top - buttonRect.top).abs(), lessThan(350));
      expect(menuRect.left, greaterThanOrEqualTo(0));
      expect(menuRect.top, greaterThanOrEqualTo(0));
      expect(menuRect.right, lessThanOrEqualTo(windowSize.width));
      expect(menuRect.bottom, lessThanOrEqualTo(windowSize.height));

      await tester.tap(find.text('👍').last);
      await tester.pumpAndSettle();

      expect(find.text('👍'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });
  });
}
