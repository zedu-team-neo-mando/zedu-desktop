import '../../../../../helpers/helpers.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class _EmptyWorkspaceNotifier extends WorkspaceNotifier {
  @override
  WorkspaceState build() => const WorkspaceState();
}

class _FakeDmListNotifier extends DmListNotifier {
  _FakeDmListNotifier(this._conversations);

  final List<DmConversation> _conversations;

  @override
  Future<List<DmConversation>> build() async => _conversations;
}

Future<ProviderContainer> _pumpSidebar(
  WidgetTester tester, {
  List<DmConversation> conversations = const [],
}) async {
  final container = ProviderContainer(
    overrides: [
      workspaceProvider.overrideWith(_EmptyWorkspaceNotifier.new),
      dmListProvider.overrideWith(() => _FakeDmListNotifier(conversations)),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: buildTestMaterialApp(
        const SizedBox(width: 320, height: 600, child: DmSidebarList()),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  return container;
}

void main() {
  group('DmSidebarList search field', () {
    testWidgets('renders an editable field instead of a static label', (
      tester,
    ) async {
      await _pumpSidebar(tester);

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Find a Conversation'), findsOneWidget);
    });

    testWidgets('accepts typed input', (tester) async {
      await _pumpSidebar(tester);

      await tester.enterText(find.byType(TextField), 'ada');

      expect(find.text('ada'), findsOneWidget);
    });

    testWidgets('publishes the term only after the debounce', (tester) async {
      final container = await _pumpSidebar(tester);

      await tester.enterText(find.byType(TextField), 'ada');
      await tester.pump(const Duration(milliseconds: 200));
      expect(container.read(dmSearchQueryProvider), '');

      await tester.pump(const Duration(milliseconds: 150));
      expect(container.read(dmSearchQueryProvider), 'ada');
    });

    testWidgets('an active search shows "No matches"', (tester) async {
      await _pumpSidebar(tester);
      expect(find.text('No recent chats'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'ada');
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('No matches'), findsOneWidget);
      expect(find.text('No recent chats'), findsNothing);
    });

    testWidgets('clearing the term restores the unfiltered empty state', (
      tester,
    ) async {
      final container = await _pumpSidebar(tester);

      await tester.enterText(find.byType(TextField), 'ada');
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('No matches'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '');
      await tester.pump(const Duration(milliseconds: 350));

      expect(container.read(dmSearchQueryProvider), '');
      expect(find.text('No recent chats'), findsOneWidget);
      expect(find.text('No matches'), findsNothing);
    });
  });
}
