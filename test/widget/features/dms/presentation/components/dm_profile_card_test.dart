import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

void main() {
  DmConversation conversationWithName(String username) {
    return DmConversation(
      channelId: 'channel-1',
      username: username,
      participantId: 'user-1',
      previewMessage: '',
      unreadCount: 0,
    );
  }

  Future<void> pumpCard(WidgetTester tester, String username) async {
    await tester.pumpWidget(
      buildTestMaterialApp(
        Scaffold(
          body: DmProfileCard(conversation: conversationWithName(username)),
        ),
      ),
    );
  }

  testWidgets('shows ? for a whitespace-only display name', (tester) async {
    await pumpCard(tester, '   ');

    expect(
      find.descendant(
        of: find.byType(CircleAvatar),
        matching: find.text('?'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('keeps an emoji display name intact', (tester) async {
    await pumpCard(tester, '👩🏽‍💻 Alice');

    expect(
      find.descendant(
        of: find.byType(CircleAvatar),
        matching: find.text('👩🏽‍💻'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('uses the first letter of a normal display name', (tester) async {
    await pumpCard(tester, 'Ada Okafor');

    expect(
      find.descendant(
        of: find.byType(CircleAvatar),
        matching: find.text('A'),
      ),
      findsOneWidget,
    );
  });
}
