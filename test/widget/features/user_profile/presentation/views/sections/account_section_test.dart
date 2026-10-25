import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zedu/features/features.dart';

import '../../../../../../helpers/helpers.dart';

ProfileAccount buildAccount({
  String name = 'Ada Okafor',
  String email = 'ada@zedu.chat',
  String username = '',
}) {
  return ProfileAccount(
    name: name,
    email: email,
    timezone: 'Africa/Lagos',
    username: username,
  );
}

Widget buildSectionUnderTest(ProfileAccount account) {
  return ProviderScope(
    child: buildTestMaterialApp(
      Scaffold(
        body: SingleChildScrollView(
          child: AccountSection(
            account: account,
            isSaving: false,
            onSave: (_) {},
            onDelete: () async {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the account username when it is set', (tester) async {
    await tester.pumpWidget(
      buildSectionUnderTest(buildAccount(username: 'ada')),
    );

    expect(find.text('@ada'), findsOneWidget);
  });

  testWidgets('derives the handle from the name when username is empty', (
    tester,
  ) async {
    await tester.pumpWidget(buildSectionUnderTest(buildAccount()));

    expect(find.text('@adaokafor'), findsOneWidget);
  });

  testWidgets('displays the authenticated user complete full name and email', (
    tester,
  ) async {
    final account = buildAccount(
      name: 'Pauline Banye',
      email: 'pauline@zedu.chat',
      username: 'pauline',
    );

    await tester.pumpWidget(buildSectionUnderTest(account));

    expect(find.text('Pauline Banye'), findsOneWidget);
    expect(find.text('pauline@zedu.chat'), findsOneWidget);
  });

  testWidgets(
    'updates displayed info when switching from User A to User B without restart',
    (tester) async {
      final userAAccount = buildAccount(
        name: 'Pauline Banye',
        email: 'pauline@zedu.chat',
        username: 'pauline',
      );
      final userBAccount = buildAccount(
        name: 'Maureen Chidera',
        email: 'maureen@zedu.chat',
        username: 'maureen',
      );

      // Render User A
      await tester.pumpWidget(buildSectionUnderTest(userAAccount));
      expect(find.text('Pauline Banye'), findsOneWidget);
      expect(find.text('pauline@zedu.chat'), findsOneWidget);

      // Switch to User B
      await tester.pumpWidget(buildSectionUnderTest(userBAccount));
      await tester.pumpAndSettle();

      // Verify User B is displayed and User A is no longer displayed
      expect(find.text('Maureen Chidera'), findsOneWidget);
      expect(find.text('maureen@zedu.chat'), findsOneWidget);

      expect(find.text('Pauline Banye'), findsNothing);
      expect(find.text('pauline@zedu.chat'), findsNothing);
    },
  );
}
