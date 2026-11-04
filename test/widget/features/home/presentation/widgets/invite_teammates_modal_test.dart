import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

class _FakeWorkspaceNotifier extends WorkspaceNotifier {
  @override
  WorkspaceState build() => const WorkspaceState();
}

class _FakeUserProfileNotifier extends UserProfileNotifier {
  @override
  UserProfileState build() => const UserProfileState();

  @override
  Future<List<Map<String, dynamic>>> fetchRegisteredUsers() async => [];

  @override
  Future<void> inviteMember({
    required String email,
    required String role,
    String? userId,
  }) async {
    state = state.copyWith(error: 'Email already invited.');
  }
}

void main() {
  testWidgets('surfaces an invite failure as a toast', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workspaceProvider.overrideWith(_FakeWorkspaceNotifier.new),
          userProfileNotifierProvider.overrideWith(
            _FakeUserProfileNotifier.new,
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: InviteTeammatesModal())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField).first,
      'teammate@example.com',
    );
    await tester.ensureVisible(find.text('Add'));
    await tester.tap(find.text('Add'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Error'), findsOneWidget);
    expect(find.text('Email already invited.'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);

    await tester.pump(const Duration(seconds: 5));
  });
}
