import 'dart:io';

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

class MockDmRepository extends Mock implements DmRepository {}

class MockDraftStore extends Mock implements DmDraftStore {}

// Avoids the GetIt/locator setup the real AuthNotifier needs.
class FakeAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.unauthenticated);
}

const _pdfMessage = {
  'id': 'm1',
  'content': 'Take a look',
  'user_id': 'user-2',
  'media': [
    {
      'file_name': 'quarterly-report.pdf',
      'file_link': 'https://files.test/quarterly-report.pdf',
      'file_type': 'pdf',
    },
  ],
};

Future<void> _pumpChatArea(
  WidgetTester tester, {
  List<Map<String, dynamic>> messages = const [_pdfMessage],
}) async {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final repository = MockDmRepository();
  when(
    () => repository.getMessages(any(), page: any(named: 'page')),
  ).thenAnswer((_) async => messages);
  final drafts = MockDraftStore();
  when(() => drafts.load(any())).thenAnswer((_) async => null);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(FakeAuthNotifier.new),
        dmRepositoryProvider.overrideWithValue(repository),
        dmDraftStoreProvider.overrideWith((ref) => drafts),
      ],
      child: buildTestMaterialApp(
        Scaffold(
          body: DmChatArea(
            conversation: DmConversation(
              channelId: 'chat-1',
              username: 'History Tester',
              participantId: 'user-2',
              previewMessage: '',
              unreadCount: 0,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

/// Lets PDFium's async loading fail (or finish) inside the test VM without
/// failing the test, then settles the tree teardown.
Future<void> _absorbAsyncLoad(WidgetTester tester) async {
  for (var i = 0; i < 15; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    tester.takeException();
  }
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => Directory.systemTemp.path,
        );
  });

  testWidgets(
    'a PDF attachment renders as a PDF tile, not the generic file tile',
    (tester) async {
      await _pumpChatArea(tester);

      expect(find.byIcon(Icons.picture_as_pdf_rounded), findsOneWidget);
      expect(find.byIcon(Icons.insert_drive_file_rounded), findsNothing);
      expect(find.text('quarterly-report.pdf'), findsOneWidget);
      expect(find.text('Take a look', findRichText: true), findsOneWidget);

      await _absorbAsyncLoad(tester);
    },
  );

  testWidgets(
    'tapping the PDF tile opens the in-app viewer instead of the browser',
    (tester) async {
      await _pumpChatArea(tester);

      await tester.tap(find.text('quarterly-report.pdf'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(PdfAttachmentViewer), findsOneWidget);

      await _absorbAsyncLoad(tester);
    },
  );

  testWidgets('the PDF viewer shows title, page and zoom controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestMaterialApp(
        PdfAttachmentViewer(
          fileUrl: 'https://example.com/report.pdf',
          fileName: 'report.pdf',
        ),
      ),
    );
    await tester.pump();

    expect(find.text('report.pdf'), findsOneWidget);
    expect(find.byTooltip('Download PDF'), findsOneWidget);
    expect(find.byTooltip('Close preview'), findsOneWidget);
    expect(find.byTooltip('Previous page'), findsOneWidget);
    expect(find.byTooltip('Next page'), findsOneWidget);
    expect(find.byTooltip('Zoom out'), findsOneWidget);
    expect(find.byTooltip('Zoom in'), findsOneWidget);
    expect(find.text('Loading...'), findsOneWidget);

    await _absorbAsyncLoad(tester);
  });
}
