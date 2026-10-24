import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import '../../../../../../helpers/helpers.dart';

Widget buildUnderTest(List<TeamMember> members) {
  return ProviderScope(
    child: MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: UserManagementSection(
            members: members,
            isSaving: false,
            onInvite: ({required email, required role}) async {},
            onUpdate: (_) {},
            onRemove: (_) {},
          ),
        ),
      ),
    ),
  );
}

List<TeamMember> createMembers(int count) {
  return List.generate(
    count,
    (i) => TeamMember(
      id: '$i',
      email: 'member$i@example.com',
      name: 'Member $i',
      role: i % 2 == 0 ? 'User' : 'Administrator',
      dateJoined: 'Oct 1, 2026',
      status: TeamMemberStatus.active,
    ),
  );
}

void main() {
  group('UserManagementSection empty state and pagination', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    testWidgets('shows a message and hides pagination with no members', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildUnderTest(const []));
      await tester.pump();

      expect(find.text('No members found.'), findsOneWidget);
      expect(find.text('Previous'), findsNothing);
      expect(find.text('Next'), findsNothing);
    });

    testWidgets(
      'shows the member and hides pagination when there is only one page',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          buildUnderTest(const [
            TeamMember(
              id: '1',
              email: 'member@example.com',
              role: 'User',
              dateJoined: 'Oct 1, 2026',
              status: TeamMemberStatus.active,
            ),
          ]),
        );
        await tester.pump();

        expect(find.text('No members found.'), findsNothing);
        expect(find.text('member@example.com'), findsWidgets);
        expect(find.text('Previous'), findsNothing);
        expect(find.text('Next'), findsNothing);
      },
    );

    testWidgets('shows a search message when the filter matches nothing', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildUnderTest(const [
          TeamMember(
            id: '1',
            email: 'member@example.com',
            role: 'User',
            dateJoined: 'Oct 1, 2026',
            status: TeamMemberStatus.active,
          ),
        ]),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump();

      expect(find.text('No members match your search.'), findsOneWidget);
      expect(find.text('Previous'), findsNothing);
      expect(find.text('Next'), findsNothing);
    });

    testWidgets('shows pagination and supports multi-page navigation', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final members = createMembers(15);
      await tester.pumpWidget(buildUnderTest(members));
      await tester.pump();

      // Page 1
      expect(find.text('No members found.'), findsNothing);
      expect(find.text('member0@example.com'), findsWidgets);
      expect(find.text('member14@example.com'), findsNothing);
      expect(
        tester
            .widget<Text>(find.byKey(const Key('user_management_page_number')))
            .data,
        '1',
      );

      final prevBtnPage1 = tester.widget<AppButton>(
        find.widgetWithText(AppButton, 'Previous'),
      );
      final nextBtnPage1 = tester.widget<AppButton>(
        find.widgetWithText(AppButton, 'Next'),
      );
      expect(prevBtnPage1.disabled, isTrue);
      expect(nextBtnPage1.disabled, isFalse);

      // Navigate to Page 2
      await tester.tap(find.widgetWithText(AppButton, 'Next'));
      await tester.pump();

      expect(find.text('member0@example.com'), findsNothing);
      expect(find.text('member14@example.com'), findsWidgets);
      expect(
        tester
            .widget<Text>(find.byKey(const Key('user_management_page_number')))
            .data,
        '2',
      );

      final prevBtnPage2 = tester.widget<AppButton>(
        find.widgetWithText(AppButton, 'Previous'),
      );
      final nextBtnPage2 = tester.widget<AppButton>(
        find.widgetWithText(AppButton, 'Next'),
      );
      expect(prevBtnPage2.disabled, isFalse);
      expect(nextBtnPage2.disabled, isTrue);

      // Navigate back to Page 1
      await tester.tap(find.widgetWithText(AppButton, 'Previous'));
      await tester.pump();

      expect(find.text('member0@example.com'), findsWidgets);
      expect(find.text('member14@example.com'), findsNothing);
      expect(
        tester
            .widget<Text>(find.byKey(const Key('user_management_page_number')))
            .data,
        '1',
      );
    });

    testWidgets('resets to page 1 and updates empty state when searching', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final members = createMembers(15);
      await tester.pumpWidget(buildUnderTest(members));
      await tester.pump();

      // Navigate to Page 2
      await tester.tap(find.widgetWithText(AppButton, 'Next'));
      await tester.pump();
      expect(
        tester
            .widget<Text>(find.byKey(const Key('user_management_page_number')))
            .data,
        '2',
      );

      // Search for specific member
      await tester.enterText(find.byType(TextField), 'member0');
      await tester.pump();

      // Only 1 result matching member0, so pagination hides
      expect(find.text('member0@example.com'), findsWidgets);
      expect(find.text('Previous'), findsNothing);

      // Clear search
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();

      // Pagination restores on page 1
      expect(
        tester
            .widget<Text>(find.byKey(const Key('user_management_page_number')))
            .data,
        '1',
      );
      expect(find.text('member0@example.com'), findsWidgets);
    });

    testWidgets('updates empty state when changing role filter', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Members only have 'User' role
      final members = [
        const TeamMember(
          id: '1',
          email: 'user@example.com',
          role: 'User',
          dateJoined: 'Oct 1, 2026',
          status: TeamMemberStatus.active,
        ),
      ];

      await tester.pumpWidget(buildUnderTest(members));
      await tester.pump();

      // Select 'Manager' which has no matching members
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Manager').last);
      await tester.pumpAndSettle();

      expect(find.text('No members match your search.'), findsOneWidget);
      expect(find.text('Previous'), findsNothing);

      // Reset to 'All Roles'
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('All Roles').last);
      await tester.pumpAndSettle();

      expect(find.text('user@example.com'), findsWidgets);
      expect(find.text('No members match your search.'), findsNothing);
    });
  });

  group('UserManagementSection table layout and overflow (#204)', () {
    testWidgets('renders long email, long role, and long date without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final members = [
        const TeamMember(
          id: 'long-member-1',
          email:
              'verylongemailaddressthatcouldcauseoverflow@organizationdomain.com',
          role: '019fcd17-4b53-72d3-bac3-4586dc029b5a',
          dateJoined: 'November 28, 2026, 11:59 PM',
          status: TeamMemberStatus.active,
        ),
      ];

      await tester.pumpWidget(buildUnderTest(members));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.text(
          'verylongemailaddressthatcouldcauseoverflow@organizationdomain.com',
        ),
        findsOneWidget,
      );
      expect(find.text('019fcd17-4b53-72d3-bac3-4586dc029b5a'), findsOneWidget);
      expect(find.text('November 28, 2026, 11:59 PM'), findsOneWidget);
    });

    testWidgets('renders without overflow on narrow window dimensions', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(600, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildUnderTest(createMembers(5)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('member0@example.com'), findsOneWidget);
    });

    testWidgets(
      'search and filter toolbar stacks responsively at reduced window widths without overflow',
      (tester) async {
        // Window width where fixed-width 300px + dropdown previously threw 35px overflow
        tester.view.physicalSize = const Size(440, 700);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(buildUnderTest(createMembers(3)));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('All Roles'), findsOneWidget);

        // Verify search input still functions when stacked
        await tester.enterText(find.byType(TextField), 'member1');
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('member1@example.com'), findsOneWidget);
        expect(find.text('member0@example.com'), findsNothing);
      },
    );

    testWidgets(
      'table columns and action buttons remain accessible via horizontal scroll at reduced widths',
      (tester) async {
        tester.view.physicalSize = const Size(500, 700);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(buildUnderTest(createMembers(2)));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        // Check horizontal scrollbar is present
        expect(find.byType(Scrollbar), findsOneWidget);

        // Scroll horizontally to ensure the rightmost Actions column is fully reached
        final scrollableFinder = find.byType(SingleChildScrollView).last;
        await tester.drag(scrollableFinder, const Offset(-300, 0));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byIcon(Icons.edit_outlined), findsWidgets);
        expect(find.byIcon(Icons.delete_outline), findsWidgets);
      },
    );
  });
}
