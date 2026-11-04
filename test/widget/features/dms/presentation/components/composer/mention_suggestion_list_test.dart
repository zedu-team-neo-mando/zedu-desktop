import 'package:zedu/core/core.dart';
import 'package:zedu/features/dms/presentation/components/composer/composer.dart';
import 'package:zedu/features/features.dart';

import '../../../../../../helpers/helpers.dart';

void main() {
  DmParticipant participantWithName(String username) {
    return DmParticipant(
      userId: 'user-1',
      username: username,
      email: 'user@example.com',
    );
  }

  Future<void> pumpList(WidgetTester tester, String username) async {
    await tester.pumpWidget(
      buildTestMaterialApp(
        Scaffold(
          body: MentionSuggestionList(
            suggestions: [participantWithName(username)],
            query: '',
            colors: AppPalette.light,
            onSelect: (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('shows ? for a whitespace-only username', (tester) async {
    await pumpList(tester, '   ');

    expect(
      find.descendant(of: find.byType(CircleAvatar), matching: find.text('?')),
      findsOneWidget,
    );
  });

  testWidgets('keeps an emoji username intact', (tester) async {
    await pumpList(tester, '🤖bot');

    expect(
      find.descendant(of: find.byType(CircleAvatar), matching: find.text('🤖')),
      findsOneWidget,
    );
  });

  testWidgets('uses the first letter of a normal username', (tester) async {
    await pumpList(tester, 'Ada');

    expect(
      find.descendant(of: find.byType(CircleAvatar), matching: find.text('A')),
      findsOneWidget,
    );
  });
}
