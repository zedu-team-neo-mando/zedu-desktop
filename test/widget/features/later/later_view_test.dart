import '../../../helpers/helpers.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class FakeDmListNotifier extends DmListNotifier {
  @override
  Future<List<DmConversation>> build() async => [
    DmConversation(
      channelId: 'ch-1',
      username: 'Ada Lovelace',
      participantId: 'u-2',
      previewMessage: '',
      unreadCount: 0,
    ),
  ];
}

SavedMessage message(String id) => SavedMessage(
  messageId: id,
  orgId: 'org-1',
  conversationId: 'ch-1',
  conversationName: 'Ada Lovelace',
  senderName: 'Ada',
  snippet: 'hello there',
  savedAt: DateTime(2026, 10, 17, 8, 30),
);

void main() {
  Widget wrap(Widget child, FakeSavedMessagesStorage storage) {
    return ProviderScope(
      overrides: [
        currentOrgIdProvider.overrideWithValue('org-1'),
        dmListProvider.overrideWith(FakeDmListNotifier.new),
        savedMessagesProvider.overrideWith(
          () => SavedMessagesNotifier(storage),
        ),
      ],
      child: buildTestMaterialApp(child),
    );
  }

  testWidgets('shows the empty state when nothing is saved', (tester) async {
    await tester.pumpWidget(
      wrap(const Scaffold(body: LaterView()), FakeSavedMessagesStorage()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Later'), findsOneWidget);
    expect(find.text('Nothing saved yet'), findsOneWidget);
    expect(find.textContaining('Save for later'), findsOneWidget);
  });

  testWidgets('lists saved messages newest first', (tester) async {
    final storage = FakeSavedMessagesStorage({
      'org-1': [
        message('m1'),
        SavedMessage(
          messageId: 'm2',
          orgId: 'org-1',
          conversationId: 'ch-1',
          conversationName: 'Ada Lovelace',
          senderName: 'Ada',
          snippet: 'second message',
          savedAt: DateTime(2026, 10, 17, 9, 0),
        ),
      ],
    });
    await tester.pumpWidget(wrap(const Scaffold(body: LaterView()), storage));
    await tester.pumpAndSettle();

    expect(find.text('hello there'), findsOneWidget);
    expect(find.text('second message'), findsOneWidget);
    expect(find.text('Nothing saved yet'), findsNothing);
  });

  testWidgets('removing a bookmark updates the list and storage', (
    tester,
  ) async {
    final storage = FakeSavedMessagesStorage({
      'org-1': [
        message('m1'),
        SavedMessage(
          messageId: 'm2',
          orgId: 'org-1',
          conversationId: 'ch-1',
          conversationName: 'Ada Lovelace',
          senderName: 'Ada',
          snippet: 'second message',
          savedAt: DateTime(2026, 10, 17, 9, 0),
        ),
      ],
    });
    await tester.pumpWidget(wrap(const Scaffold(body: LaterView()), storage));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Remove bookmark').first);
    await tester.pumpAndSettle();

    expect(find.text('second message'), findsOneWidget);
    expect(find.text('hello there'), findsNothing);
    expect(storage.saved['org-1']!.map((m) => m.messageId), ['m2']);
  });

  testWidgets('opening a saved message jumps to its DM', (tester) async {
    final storage = FakeSavedMessagesStorage({
      'org-1': [message('m1')],
    });
    await tester.pumpWidget(wrap(const Scaffold(body: LaterView()), storage));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open in conversation'));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(LaterView)),
    );
    expect(container.read(homeSidebarProvider), HomeSidebarType.dms);
    expect(container.read(selectedDmProvider)?.channelId, 'ch-1');
  });
}
