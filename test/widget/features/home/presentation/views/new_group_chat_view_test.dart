import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

class _FakeAuthNotifier extends AuthNotifier {
  final User? _user;
  _FakeAuthNotifier([this._user]);

  @override
  AuthState build() {
    return AuthState(
      status: _user != null
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated,
      user: _user,
    );
  }
}

class _FakeUserProfileNotifier extends UserProfileNotifier {
  final List<TeamMember> _members;
  _FakeUserProfileNotifier(this._members);

  @override
  UserProfileState build() {
    return UserProfileState(isLoading: false, teamMembers: _members);
  }
}

void main() {
  final testMembers = [
    const TeamMember(
      id: 'member-1',
      name: '',
      email: 'emptyname@zedu.test',
      role: 'Member',
      dateJoined: 'Jan 1, 2026',
      status: TeamMemberStatus.active,
    ),
    const TeamMember(
      id: 'member-2',
      name: '   ',
      email: 'whitespace@zedu.test',
      role: 'Member',
      dateJoined: 'Jan 1, 2026',
      status: TeamMemberStatus.active,
    ),
    const TeamMember(
      id: 'member-3',
      name: null,
      email: 'nullname@zedu.test',
      role: 'Member',
      dateJoined: 'Jan 1, 2026',
      status: TeamMemberStatus.active,
    ),
    const TeamMember(
      id: 'member-4',
      name: 'Alice Cooper',
      email: 'alice@zedu.test',
      role: 'Admin',
      dateJoined: 'Jan 1, 2026',
      status: TeamMemberStatus.active,
    ),
  ];

  Widget buildWidget({List<TeamMember>? members, User? signedInUser}) {
    return ProviderScope(
      overrides: [
        userProfileNotifierProvider.overrideWith(
          () => _FakeUserProfileNotifier(members ?? testMembers),
        ),
        authNotifierProvider.overrideWith(
          () => _FakeAuthNotifier(signedInUser),
        ),
      ],
      child: buildTestMaterialApp(
        const Scaffold(
          body: SizedBox(width: 1200, height: 900, child: NewGroupChatView()),
        ),
      ),
    );
  }

  Finder findSearchField() {
    return find.byWidgetPredicate(
      (w) =>
          w is TextField &&
          w.decoration?.hintText?.contains('#a-channel') == true,
    );
  }

  testWidgets(
    'renders contact list without crashing when members have empty or whitespace names',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      final searchField = findSearchField();
      expect(searchField, findsOneWidget);

      await tester.tap(searchField);
      await tester.pumpAndSettle();

      // Contact tiles should be displayed without throwing RangeError
      expect(find.text('emptyname'), findsOneWidget);
      expect(find.text('whitespace'), findsOneWidget);
      expect(find.text('nullname'), findsOneWidget);
      expect(find.text('Alice Cooper'), findsOneWidget);
    },
  );

  testWidgets(
    'renders selected member chip with safe initials and fallback label for empty name',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.tap(findSearchField());
      await tester.pumpAndSettle();

      // Tap on member with empty name ('emptyname@zedu.test')
      await tester.tap(find.text('emptyname'));
      await tester.pumpAndSettle();

      // Verify selected member chip renders with label and without error
      expect(find.byType(Chip), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(Chip),
          matching: find.text('emptyname'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: find.byType(Chip), matching: find.text('EM')),
        findsOneWidget,
      );
    },
  );
  testWidgets('renders validation helper in neutral style on initial load', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    final helperText = tester.widget<Text>(
      find.textContaining('Select at least 2 members'),
    );
    expect(helperText.style?.color, isNot(equals(AppPalette.light.error)));
    expect(helperText.style?.color, equals(AppPalette.light.textSecondary));
  });

  testWidgets('does not suggest signed-in user in suggestions list', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final currentUser = User(
      id: 'member-4',
      firstName: 'Alice',
      lastName: 'Cooper',
      email: 'alice@zedu.test',
      phone: '',
      username: 'alice',
      isVerified: true,
      isOnboarded: true,
      createdAt: DateTime(2026, 1, 1),
      currentOrg: 'org-1',
      currentOrganisationSlug: 'org-1',
      avatarUrl: '',
      defaultAvatarUrl: '',
    );

    await tester.pumpWidget(buildWidget(signedInUser: currentUser));
    await tester.pumpAndSettle();

    await tester.tap(findSearchField());
    await tester.pumpAndSettle();

    // Alice Cooper is the signed-in user and should NOT be suggested
    expect(find.text('Alice Cooper'), findsNothing);
    expect(find.text('emptyname'), findsOneWidget);
  });
}
