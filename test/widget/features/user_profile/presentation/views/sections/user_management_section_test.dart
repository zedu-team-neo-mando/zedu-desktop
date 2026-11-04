import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zedu/features/features.dart';

import '../../../../../../helpers/helpers.dart';

void main() {
  const member = TeamMember(
    id: 'm1',
    email: 'ada@example.com',
    role: 'Administrator',
    dateJoined: '1 Jan 2026',
    status: TeamMemberStatus.active,
  );

  testWidgets('member row edit and remove buttons have accessible names',
      (tester) async {
    final semantics = tester.ensureSemantics();
    addTearDown(semantics.dispose);

    await tester.pumpWidget(
      ProviderScope(
        child: buildTestMaterialApp(
          Scaffold(
            body: SingleChildScrollView(
              child: UserManagementSection(
                members: const [member],
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

    final tooltipMessages = tester
        .widgetList<Tooltip>(find.byType(Tooltip))
        .map((tooltip) => tooltip.message)
        .toList();
    expect(tooltipMessages, contains('Edit ada@example.com'));
    expect(tooltipMessages, contains('Remove ada@example.com'));

    expect(find.bySemanticsLabel('Edit ada@example.com'), findsWidgets);
    expect(find.bySemanticsLabel('Remove ada@example.com'), findsWidgets);
  });
}
