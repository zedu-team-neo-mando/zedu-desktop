import 'dart:math' as math;

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

  group('UserManagementSection tab alignment (#211)', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    Future<void> pumpSection(
      WidgetTester tester, {
      List<TeamMember> members = const [],
      int invitesCount = 0,
      Size size = const Size(1400, 1000),
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: UserManagementSection(
                  members: members,
                  isSaving: false,
                  invitesCount: invitesCount,
                  onInvite: ({required email, required role}) async {},
                  onUpdate: (_) {},
                  onRemove: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    // Both labels and both badges must sit on the same baselines. The badge is
    // keyed by its tab so the geometry can be measured directly.
    Finder badgeFor(String label) => find.byKey(Key('tab_badge_$label'));
    Finder labelFor(String label) => find.byKey(Key('tab_label_$label'));
    Finder underlineFor(String label) =>
        find.byKey(Key('tab_underline_$label'));
    Finder tabFor(String label) =>
        find.ancestor(of: badgeFor(label), matching: find.byType(InkWell));
    Finder countFor(String label) =>
        find.descendant(of: badgeFor(label), matching: find.byType(Text));

    /// Visible top space and bottom space before the underline.
    ({double top, double bottom}) headerGaps(
      WidgetTester tester,
      String label,
    ) {
      final tab = tester.getRect(tabFor(label));
      final underline = tester.getRect(underlineFor(label));
      final labelRect = tester.getRect(labelFor(label));
      final badgeRect = tester.getRect(badgeFor(label));
      final contentTop = math.min(labelRect.top, badgeRect.top);
      final contentBottom = math.max(labelRect.bottom, badgeRect.bottom);
      return (top: contentTop - tab.top, bottom: underline.top - contentBottom);
    }

    testWidgets('keeps the underline close to the vertically centred content', (
      tester,
    ) async {
      await pumpSection(tester, members: createMembers(3), invitesCount: 2);

      for (final label in ['Members', 'Invites']) {
        final tab = tester.getRect(tabFor(label));
        final underline = tester.getRect(underlineFor(label));
        final text = tester.getRect(labelFor(label));
        final badge = tester.getRect(badgeFor(label));
        final contentTop = math.min(text.top, badge.top);
        final contentBottom = math.max(text.bottom, badge.bottom);
        final visibleGap = underline.top - contentBottom;

        expect(visibleGap, inInclusiveRange(7, 9));
        expect(contentTop - tab.top, inInclusiveRange(7, 9));
        expect(underline.bottom, moreOrLessEquals(tab.bottom, epsilon: 0.01));
      }
    });

    testWidgets('keeps both tab labels on the same baseline', (tester) async {
      await pumpSection(tester, members: createMembers(3));

      final membersLabel = tester.getRect(labelFor('Members'));
      final invitesLabel = tester.getRect(labelFor('Invites'));

      expect(
        membersLabel.center.dy,
        moreOrLessEquals(invitesLabel.center.dy, epsilon: 0.5),
        reason: 'label baselines must be aligned across tabs',
      );
      expect(membersLabel.height, moreOrLessEquals(invitesLabel.height));
    });

    testWidgets('keeps both count badges vertically centred on the label', (
      tester,
    ) async {
      await pumpSection(tester, members: createMembers(3));

      final membersLabel = tester.getRect(labelFor('Members'));
      final invitesLabel = tester.getRect(labelFor('Invites'));
      final membersBadge = tester.getRect(badgeFor('Members'));
      final invitesBadge = tester.getRect(badgeFor('Invites'));

      expect(
        membersBadge.center.dy,
        moreOrLessEquals(membersLabel.center.dy, epsilon: 1.0),
        reason: 'the Members badge must be centred on its label',
      );
      expect(
        invitesBadge.center.dy,
        moreOrLessEquals(invitesLabel.center.dy, epsilon: 1.0),
        reason: 'the Invites badge must be centred on its label',
      );
    });

    testWidgets('uses identical label-to-badge spacing on both tabs', (
      tester,
    ) async {
      await pumpSection(tester, members: createMembers(3));

      final membersGap =
          tester.getRect(badgeFor('Members')).left -
          tester.getRect(labelFor('Members')).right;
      final invitesGap =
          tester.getRect(badgeFor('Invites')).left -
          tester.getRect(labelFor('Invites')).right;

      expect(membersGap, moreOrLessEquals(invitesGap, epsilon: 1.0));
      expect(membersGap, greaterThan(0));
    });

    testWidgets('renders both tabs at the same width, height and spacing', (
      tester,
    ) async {
      await pumpSection(tester, members: createMembers(3), invitesCount: 2);

      final membersTab = tester.getRect(
        find.ancestor(of: badgeFor('Members'), matching: find.byType(InkWell)),
      );
      final invitesTab = tester.getRect(
        find.ancestor(of: badgeFor('Invites'), matching: find.byType(InkWell)),
      );

      expect(
        membersTab.width,
        moreOrLessEquals(invitesTab.width, epsilon: 0.01),
        reason: 'Members and Invites must have identical widths',
      );
      expect(
        membersTab.height,
        moreOrLessEquals(invitesTab.height, epsilon: 0.5),
        reason: 'both tabs must render at the same height',
      );
      expect(membersTab.top, moreOrLessEquals(invitesTab.top, epsilon: 0.5));
      expect(
        invitesTab.left - membersTab.right,
        moreOrLessEquals(12, epsilon: 0.5),
        reason: 'tabs should be spaced 24px apart',
      );
    });

    testWidgets('uses one compact width for the longer label and widest badge', (
      tester,
    ) async {
      await pumpSection(tester, members: createMembers(3), invitesCount: 999);

      final membersTab = tester.getRect(tabFor('Members'));
      final invitesTab = tester.getRect(tabFor('Invites'));
      final labelWidth = math.max(
        tester.getRect(labelFor('Members')).width,
        tester.getRect(labelFor('Invites')).width,
      );
      // The 999 badge is the widest the badge can get, and therefore the width
      // the shared tab geometry reserves.
      final widestBadge = tester.getRect(badgeFor('Invites'));

      expect(
        invitesTab.width,
        moreOrLessEquals(membersTab.width, epsilon: 0.01),
      );

      // Longer label + label→badge gap (8) + widest badge + 4px padding on each
      // side, rounded up to a whole pixel. Anything larger would be wasted
      // space.
      expect(
        membersTab.width,
        moreOrLessEquals(
          (labelWidth + 8 + widestBadge.width + 8).ceilToDouble(),
          epsilon: 0.01,
        ),
        reason: 'the shared width must be compact, not padded out',
      );
    });

    testWidgets('badges hug their count with symmetric padding', (
      tester,
    ) async {
      await pumpSection(tester, members: createMembers(7), invitesCount: 3);

      final membersBadge = tester.getRect(badgeFor('Members'));
      final invitesBadge = tester.getRect(badgeFor('Invites'));
      final membersCount = tester.getRect(countFor('Members'));
      final invitesCount = tester.getRect(countFor('Invites'));

      expect(
        membersBadge.width,
        moreOrLessEquals(membersCount.width + 5 + 5, epsilon: 0.5),
        reason: 'the badge must use symmetric 5px horizontal padding',
      );
      expect(
        membersBadge.height,
        moreOrLessEquals(membersCount.height + 2 + 2, epsilon: 0.5),
        reason: 'the badge must use symmetric 2px vertical padding',
      );
      expect(
        membersCount.center.dx,
        moreOrLessEquals(membersBadge.center.dx, epsilon: 0.01),
        reason: 'the count must be horizontally centred in the pill',
      );
      expect(
        membersCount.center.dy,
        moreOrLessEquals(membersBadge.center.dy, epsilon: 0.01),
        reason: 'the count must be vertically centred in the pill',
      );
      expect(
        invitesCount.center.dx,
        moreOrLessEquals(invitesBadge.center.dx, epsilon: 0.01),
      );
      expect(
        membersBadge.width,
        lessThan(30),
        reason: 'a single digit must not sit in a wide, padded block',
      );
    });

    testWidgets('keeps counts 0–999 readable without resizing the tabs', (
      tester,
    ) async {
      double? sharedWidth;
      for (final count in [0, 7, 42, 999]) {
        await pumpSection(
          tester,
          members: createMembers(2),
          invitesCount: count,
        );

        final invitesTab = tester.getRect(tabFor('Invites'));
        final badge = tester.getRect(badgeFor('Invites'));
        final digits = tester.getRect(countFor('Invites'));

        expect(
          tester.takeException(),
          isNull,
          reason: 'count $count overflows',
        );
        expect(
          digits.left,
          greaterThanOrEqualTo(badge.left - 0.01),
          reason: '$count must not be clipped on the left',
        );
        expect(
          digits.right,
          lessThanOrEqualTo(badge.right + 0.01),
          reason: '$count must not be clipped on the right',
        );
        expect(
          badge.right,
          lessThanOrEqualTo(invitesTab.right + 0.01),
          reason: '$count must fit inside the reserved tab width',
        );
        sharedWidth ??= invitesTab.width;
        expect(
          invitesTab.width,
          moreOrLessEquals(sharedWidth, epsilon: 0.01),
          reason: 'count $count must not resize the tab',
        );
      }
    });

    testWidgets('centres label and badge in an identical shared header', (
      tester,
    ) async {
      await pumpSection(tester, members: createMembers(3), invitesCount: 2);

      final membersTab = tester.getRect(tabFor('Members'));
      final invitesTab = tester.getRect(tabFor('Invites'));
      final membersGaps = headerGaps(tester, 'Members');
      final invitesGaps = headerGaps(tester, 'Invites');

      expect(
        membersTab.height,
        moreOrLessEquals(invitesTab.height, epsilon: 0.01),
        reason: 'active and inactive tabs must share one height',
      );
      expect(
        membersGaps.top,
        moreOrLessEquals(membersGaps.bottom, epsilon: 0.5),
        reason: 'Members content must be vertically centred in the header',
      );
      expect(
        invitesGaps.top,
        moreOrLessEquals(invitesGaps.bottom, epsilon: 0.5),
        reason: 'Invites content must be vertically centred in the header',
      );
      expect(
        membersGaps.top,
        moreOrLessEquals(invitesGaps.top, epsilon: 0.5),
        reason: 'both tabs must share identical vertical geometry',
      );
      expect(
        tester.getRect(labelFor('Members')).top,
        moreOrLessEquals(tester.getRect(labelFor('Invites')).top, epsilon: 0.5),
      );
      expect(
        tester.getRect(badgeFor('Members')).top,
        moreOrLessEquals(tester.getRect(badgeFor('Invites')).top, epsilon: 0.5),
      );

      // The underline is the last child, so it is flush with the tab bottom.
      expect(
        tester.getRect(underlineFor('Members')).bottom,
        moreOrLessEquals(membersTab.bottom, epsilon: 0.01),
        reason: 'the underline must be anchored to the tab bottom',
      );
      expect(
        tester.getRect(underlineFor('Invites')).bottom,
        moreOrLessEquals(invitesTab.bottom, epsilon: 0.01),
        reason: 'the inactive tab reserves the same bottom-anchored space',
      );
    });

    testWidgets('keeps both tab widths equal when counts change', (
      tester,
    ) async {
      await pumpSection(tester, members: createMembers(3), invitesCount: 0);
      final small = tester.getRect(
        find.ancestor(of: badgeFor('Invites'), matching: find.byType(InkWell)),
      );

      await pumpSection(tester, members: createMembers(150), invitesCount: 999);
      final large = tester.getRect(
        find.ancestor(of: badgeFor('Invites'), matching: find.byType(InkWell)),
      );
      final membersTab = tester.getRect(
        find.ancestor(of: badgeFor('Members'), matching: find.byType(InkWell)),
      );

      expect(
        large.width,
        moreOrLessEquals(small.width, epsilon: 0.01),
        reason: 'a wider count must not resize the tab',
      );
      expect(large.left, moreOrLessEquals(small.left, epsilon: 0.5));
      expect(large.width, moreOrLessEquals(membersTab.width, epsilon: 0.01));
    });

    testWidgets('leaves the inactive badge background transparent', (
      tester,
    ) async {
      await pumpSection(tester, members: createMembers(3), invitesCount: 2);

      BoxDecoration badgeDecoration(String label) =>
          tester.widget<DecoratedBox>(badgeFor(label)).decoration
              as BoxDecoration;

      expect(
        badgeDecoration('Invites').color,
        equals(Colors.transparent),
        reason: 'the inactive tab must not look like a separate button',
      );
      expect(
        badgeDecoration('Members').color,
        equals(
          tester.element(find.byType(UserManagementSection)).colors.primaryBg,
        ),
        reason: 'the active badge uses the theme surface tint',
      );
    });

    Color underlineColor(WidgetTester tester, String label) =>
        (tester.widget<Container>(underlineFor(label)).decoration
                as BoxDecoration)
            .color!;

    /// Resolves the design-system primary colour from the widget's own theme
    /// context, so expectations follow the theme token instead of a literal.
    Color themePrimary(WidgetTester tester) =>
        tester.element(find.byType(UserManagementSection)).colors.primary;

    testWidgets(
      'paints a clearly visible themed underline beneath the active tab only',
      (tester) async {
        await pumpSection(tester, members: createMembers(3));

        final activeColor = themePrimary(tester);
        expect(
          activeColor,
          equals(AppPalette.light.primary),
          reason: 'the test must resolve the real theme token',
        );
        expect(
          underlineColor(tester, 'Members'),
          equals(activeColor),
          reason: 'the selected tab must use the theme primary colour',
        );
        expect(
          underlineColor(tester, 'Invites'),
          equals(Colors.transparent),
          reason: 'the inactive tab must not paint an underline',
        );

        final membersUnderline = tester.getRect(underlineFor('Members'));
        expect(
          membersUnderline.width,
          greaterThan(0),
          reason: 'the underline must have a visible width',
        );
        expect(
          membersUnderline.height,
          moreOrLessEquals(3),
          reason: 'the underline must have a visible thickness',
        );
        expect(
          membersUnderline.width,
          equals(
            tester
                .getRect(
                  find.ancestor(
                    of: badgeFor('Members'),
                    matching: find.byType(InkWell),
                  ),
                )
                .width,
          ),
          reason: 'the underline must align to the active tab width',
        );
        expect(
          tester.getRect(underlineFor('Invites')).width,
          moreOrLessEquals(membersUnderline.width, epsilon: 0.01),
          reason: 'both tabs reserve the same underline width',
        );
      },
    );

    testWidgets('resolves the underline colour from the theme, not a literal', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            // A different theme configuration: dark brightness on top of the
            // app theme. The palette extension is the single source of the
            // underline colour, so the indicator must still resolve through it.
            theme: AppTheme.light.copyWith(brightness: Brightness.dark),
            home: Scaffold(
              body: SingleChildScrollView(
                child: UserManagementSection(
                  members: createMembers(3),
                  isSaving: false,
                  onInvite: ({required email, required role}) async {},
                  onUpdate: (_) {},
                  onRemove: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        underlineColor(tester, 'Members'),
        equals(themePrimary(tester)),
        reason: 'the indicator must track the themed palette token',
      );
      expect(
        underlineColor(tester, 'Members'),
        equals(AppPalette.light.primary),
        reason: 'the design system currently exposes one primary token',
      );
      expect(underlineColor(tester, 'Invites'), equals(Colors.transparent));
    });

    testWidgets('underlines the tab that is selected via its geometry', (
      tester,
    ) async {
      await pumpSection(tester, members: createMembers(3), invitesCount: 2);

      final membersTab = tester.getRect(
        find.ancestor(of: badgeFor('Members'), matching: find.byType(InkWell)),
      );
      final membersUnderline = tester.getRect(underlineFor('Members'));

      expect(
        membersUnderline.left,
        moreOrLessEquals(membersTab.left, epsilon: 0.5),
        reason: 'the underline must start at the selected tab edge',
      );
      expect(
        membersUnderline.right,
        moreOrLessEquals(membersTab.right, epsilon: 0.5),
        reason: 'the underline must span the selected tab',
      );
      expect(
        membersUnderline.top,
        greaterThan(membersTab.center.dy),
        reason: 'the underline must sit beneath the label, not above it',
      );
    });

    testWidgets('moves the themed underline to the newly selected tab', (
      tester,
    ) async {
      await pumpSection(tester, members: createMembers(3), invitesCount: 2);

      final membersUnderlineBefore = tester.getRect(underlineFor('Members'));
      final invitesUnderlineBefore = tester.getRect(underlineFor('Invites'));
      expect(
        membersUnderlineBefore.center.dx,
        lessThan(invitesUnderlineBefore.center.dx),
      );
      expect(underlineColor(tester, 'Members'), equals(themePrimary(tester)));
      expect(underlineColor(tester, 'Invites'), equals(Colors.transparent));

      await tester.tap(find.text('Invites'));
      await tester.pumpAndSettle();

      expect(
        underlineColor(tester, 'Members'),
        equals(Colors.transparent),
        reason: 'the previously selected tab loses its underline',
      );
      expect(
        underlineColor(tester, 'Invites'),
        equals(themePrimary(tester)),
        reason: 'the newly selected tab gains the themed underline',
      );

      final invitesUnderlineAfter = tester.getRect(underlineFor('Invites'));
      expect(
        invitesUnderlineAfter.width,
        moreOrLessEquals(membersUnderlineBefore.width, epsilon: 0.01),
        reason: 'equal tabs keep equal underline widths',
      );
      expect(
        invitesUnderlineAfter.center.dx,
        greaterThan(membersUnderlineBefore.center.dx),
        reason: 'the underline must now be drawn further right',
      );
      expect(
        invitesUnderlineAfter.center.dy,
        moreOrLessEquals(membersUnderlineBefore.center.dy, epsilon: 0.5),
        reason: 'the underline must not change vertical position',
      );
    });

    testWidgets('does not shift the tab strip when switching tabs', (
      tester,
    ) async {
      await pumpSection(tester, members: createMembers(3), invitesCount: 2);

      final membersTabBefore = tester.getRect(tabFor('Members'));
      final invitesTabBefore = tester.getRect(tabFor('Invites'));
      final labelBefore = tester.getRect(labelFor('Members'));
      final badgeBefore = tester.getRect(badgeFor('Members'));
      final underlineBefore = tester.getRect(underlineFor('Members'));
      final gapsBefore = headerGaps(tester, 'Members');

      await tester.tap(find.text('Invites'));
      await tester.pumpAndSettle();

      final membersTabAfter = tester.getRect(tabFor('Members'));
      final invitesTabAfter = tester.getRect(tabFor('Invites'));
      final labelAfter = tester.getRect(labelFor('Members'));
      final badgeAfter = tester.getRect(badgeFor('Members'));
      final underlineAfter = tester.getRect(underlineFor('Members'));
      final gapsAfter = headerGaps(tester, 'Members');

      for (final (before, after) in [
        (membersTabBefore, membersTabAfter),
        (invitesTabBefore, invitesTabAfter),
      ]) {
        expect(
          after.left,
          moreOrLessEquals(before.left, epsilon: 0.5),
          reason: 'tabs must not jump horizontally on switch',
        );
        expect(
          after.top,
          moreOrLessEquals(before.top, epsilon: 0.5),
          reason: 'tabs must not jump vertically on switch',
        );
        expect(
          after.width,
          moreOrLessEquals(before.width, epsilon: 0.01),
          reason: 'tab widths must not change on switch',
        );
        expect(
          after.height,
          moreOrLessEquals(before.height, epsilon: 0.01),
          reason: 'tab heights must not change on switch',
        );
      }
      expect(
        labelAfter.top,
        moreOrLessEquals(labelBefore.top, epsilon: 0.5),
        reason: 'label vertical geometry must be stable on switch',
      );
      expect(
        badgeAfter.top,
        moreOrLessEquals(badgeBefore.top, epsilon: 0.5),
        reason: 'badge vertical geometry must be stable on switch',
      );
      expect(
        badgeAfter.height,
        moreOrLessEquals(badgeBefore.height, epsilon: 0.01),
      );
      expect(
        underlineAfter.top,
        moreOrLessEquals(underlineBefore.top, epsilon: 0.5),
        reason: 'the reserved underline slot must not shift vertically',
      );
      expect(
        underlineAfter.width,
        moreOrLessEquals(underlineBefore.width, epsilon: 0.5),
      );
      expect(
        gapsAfter.top,
        moreOrLessEquals(gapsBefore.top, epsilon: 0.5),
        reason: 'content must stay centred when the active tab changes',
      );
      expect(gapsAfter.top, moreOrLessEquals(gapsAfter.bottom, epsilon: 0.5));
    });

    testWidgets('does not shift the tab strip when counts change', (
      tester,
    ) async {
      await pumpSection(tester, members: createMembers(3), invitesCount: 0);
      final smallTab = tester.getRect(tabFor('Invites'));
      final smallUnderline = tester.getRect(underlineFor('Invites'));
      final smallGaps = headerGaps(tester, 'Invites');

      await pumpSection(tester, members: createMembers(150), invitesCount: 999);
      final largeTab = tester.getRect(tabFor('Invites'));
      final largeUnderline = tester.getRect(underlineFor('Invites'));
      final largeGaps = headerGaps(tester, 'Invites');

      expect(
        largeTab.top,
        moreOrLessEquals(smallTab.top, epsilon: 0.5),
        reason: 'wider count badges must not move the tab strip',
      );
      expect(largeTab.left, moreOrLessEquals(smallTab.left, epsilon: 0.5));
      expect(
        largeTab.width,
        moreOrLessEquals(smallTab.width, epsilon: 0.01),
        reason: 'a changing count must not resize the tab',
      );
      expect(
        largeTab.height,
        moreOrLessEquals(smallTab.height, epsilon: 0.01),
        reason: 'a changing count must not change the tab height',
      );
      expect(
        largeUnderline.top,
        moreOrLessEquals(smallUnderline.top, epsilon: 0.5),
        reason: 'the underline must stay in place when counts change',
      );
      expect(
        largeUnderline.width,
        moreOrLessEquals(smallUnderline.width, epsilon: 0.5),
      );
      expect(
        largeGaps.top,
        moreOrLessEquals(smallGaps.top, epsilon: 0.5),
        reason: 'content must stay vertically centred when counts change',
      );
      expect(largeGaps.top, moreOrLessEquals(largeGaps.bottom, epsilon: 0.5));
    });

    testWidgets('keeps equal geometry across window sizes', (tester) async {
      for (final size in const [
        Size(900, 700),
        Size(1000, 800),
        Size(1280, 800),
        Size(1600, 1000),
      ]) {
        await pumpSection(tester, members: createMembers(3), size: size);

        final membersLabel = tester.getRect(labelFor('Members'));
        final invitesLabel = tester.getRect(labelFor('Invites'));
        final membersTab = tester.getRect(tabFor('Members'));
        final invitesTab = tester.getRect(tabFor('Invites'));
        final gaps = headerGaps(tester, 'Members');

        expect(
          membersTab.width,
          moreOrLessEquals(invitesTab.width, epsilon: 0.01),
          reason: 'tabs must stay identically wide at $size',
        );
        expect(
          membersTab.height,
          moreOrLessEquals(invitesTab.height, epsilon: 0.01),
          reason: 'tabs must stay identically tall at $size',
        );
        expect(
          invitesTab.left - membersTab.right,
          moreOrLessEquals(12, epsilon: 0.5),
          reason: 'tab spacing must stay compact at $size',
        );
        expect(
          membersLabel.center.dy,
          moreOrLessEquals(invitesLabel.center.dy, epsilon: 0.5),
          reason: 'labels must stay aligned at $size',
        );
        expect(
          tester.getRect(badgeFor('Members')).center.dy,
          moreOrLessEquals(membersLabel.center.dy, epsilon: 1.0),
          reason: 'the badge must stay centred at $size',
        );
        expect(
          gaps.top,
          moreOrLessEquals(gaps.bottom, epsilon: 0.5),
          reason: 'tab content must stay vertically centred at $size',
        );
        expect(
          underlineColor(tester, 'Members'),
          equals(themePrimary(tester)),
          reason: 'the themed underline must be visible at $size',
        );
        expect(
          underlineColor(tester, 'Invites'),
          equals(Colors.transparent),
          reason: 'the inactive underline must stay absent at $size',
        );
        expect(
          tester.getRect(underlineFor('Members')).width,
          moreOrLessEquals(membersTab.width, epsilon: 0.5),
          reason: 'the underline must span the full tab at $size',
        );
        expect(
          tester.getRect(underlineFor('Invites')).width,
          moreOrLessEquals(membersTab.width, epsilon: 0.5),
          reason: 'the inactive tab reserves the same width at $size',
        );
        expect(
          tester.getRect(underlineFor('Members')).bottom,
          moreOrLessEquals(membersTab.bottom, epsilon: 0.01),
          reason: 'the underline must stay anchored to the tab bottom at $size',
        );
      }
    });

    testWidgets('shows the members table on the Members tab and switches '
        'to the invites view on tap', (tester) async {
      await pumpSection(tester, members: createMembers(3), invitesCount: 2);

      expect(find.text('member0@example.com'), findsWidgets);
      expect(find.text('2 pending invites.'), findsNothing);

      await tester.tap(find.text('Invites'));
      await tester.pumpAndSettle();

      expect(find.text('member0@example.com'), findsNothing);
      expect(find.text('2 pending invites.'), findsOneWidget);

      await tester.tap(find.text('Members'));
      await tester.pumpAndSettle();

      expect(find.text('member0@example.com'), findsWidgets);
      expect(find.text('2 pending invites.'), findsNothing);
    });
  });
}
