import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier(this._buildState);

  final AuthState Function() _buildState;

  @override
  AuthState build() => _buildState();
}

User _user({required String avatarUrl, required String defaultAvatarUrl}) =>
    User(
      id: 'user-1',
      firstName: 'Test',
      lastName: 'User',
      email: 'test@example.com',
      phone: '',
      username: 'testuser',
      isVerified: true,
      isOnboarded: true,
      createdAt: DateTime(2026),
      currentOrg: 'org-1',
      currentOrganisationSlug: 'test-org',
      avatarUrl: avatarUrl,
      defaultAvatarUrl: defaultAvatarUrl,
    );

Future<void> _openMenu(WidgetTester tester, User? user) async {
  tester.view.physicalSize = const Size(900, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(
          () => _TestAuthNotifier(
            () => AuthState(status: AuthStatus.authenticated, user: user),
          ),
        ),
        orgCreditBalanceProvider.overrideWith((ref) => 0),
      ],
      child: buildTestMaterialApp(
        const Scaffold(
          body: Stack(
            children: [
              Positioned(left: 0, bottom: 16, child: UserMenuButton()),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byType(UserMenuButton));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows initials when the user has no avatar url', (tester) async {
    await _openMenu(tester, _user(avatarUrl: '', defaultAvatarUrl: ''));

    expect(find.text('TU'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Image && widget.image is NetworkImage,
      ),
      findsNothing,
    );
  });

  testWidgets('fetches the profile avatar image when a url is set', (
    tester,
  ) async {
    await _openMenu(
      tester,
      _user(
        avatarUrl: 'https://media.zedu.chat/avatars/test.png',
        defaultAvatarUrl: '',
      ),
    );

    // One frame is enough to see the image widget; the stream itself is
    // not awaited because network requests are disabled in widget tests.
    await tester.pump();

    expect(
      find.byWidgetPredicate(
        (widget) => widget is Image && widget.image is NetworkImage,
      ),
      findsOneWidget,
    );
  });

  testWidgets('falls back to the default avatar url when the upload is empty', (
    tester,
  ) async {
    await _openMenu(
      tester,
      _user(
        avatarUrl: '',
        defaultAvatarUrl: 'https://media.zedu.chat/default_avatar.png',
      ),
    );

    await tester.pump();

    expect(
      find.byWidgetPredicate(
        (widget) => widget is Image && widget.image is NetworkImage,
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows the anonymous fallback initials without a user', (
    tester,
  ) async {
    await _openMenu(tester, null);

    expect(find.text('ZU'), findsOneWidget);
  });
}
