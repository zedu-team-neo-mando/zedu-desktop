import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

class _FakeProfileNotifier extends UserProfileNotifier {
  @override
  UserProfileState build() => const UserProfileState();
}

class _FakeDataReader extends Fake implements DataReader {
  _FakeDataReader(this.formats);

  final Map<FileFormat, Uint8List> formats;

  @override
  bool canProvide(DataFormat format) => formats.containsKey(format);

  @override
  ReadProgress? getFile(
    FileFormat? format,
    void Function(DataReaderFile file) onFile, {
    void Function(Object error)? onError,
    bool allowVirtualFiles = true,
    bool synthesizeFilesFromURIs = true,
  }) {
    if (format != null) {
      final bytes = formats[format];
      if (bytes != null) {
        onFile(_FakeDataReaderFile(bytes));
      }
    }
    return null;
  }
}

class _FakeDataReaderFile extends Fake implements DataReaderFile {
  _FakeDataReaderFile(this.bytes);

  final Uint8List bytes;

  @override
  Future<Uint8List> readAll() async => bytes;
}

Future<void> _pumpComposer(
  WidgetTester tester,
  void Function(String) onSend,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        userProfileNotifierProvider.overrideWith(_FakeProfileNotifier.new),
      ],
      child: buildTestMaterialApp(
        Scaffold(
          body: MessageComposer(
            activeChat: const ActiveChatState(
              type: ActiveChatType.channel,
              id: 'general',
            ),
            onSend: onSend,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _attachPastedImage(WidgetTester tester) async {
  final dynamic state = tester.state(find.byType(MessageComposer));
  final png = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]);
  final reader = _FakeDataReader({Formats.png: png});
  final handled = await tester.runAsync(
    () => state.handlePaste(reader: reader) as Future<bool>,
  );
  expect(handled, isTrue);
  await tester.pumpAndSettle();
}

void main() {
  group('MessageComposer action button with attachments', () {
    testWidgets('shows the microphone with no attachment', (tester) async {
      await _pumpComposer(tester, (_) {});

      expect(find.widgetWithIcon(IconButton, Icons.mic_none), findsOneWidget);
      expect(find.widgetWithIcon(IconButton, Icons.send), findsNothing);
    });

    testWidgets('shows the Send button with a file attached', (tester) async {
      await _pumpComposer(tester, (_) {});
      await _attachPastedImage(tester);

      expect(find.byType(Chip), findsOneWidget);
      expect(find.widgetWithIcon(IconButton, Icons.send), findsOneWidget);
      expect(find.widgetWithIcon(IconButton, Icons.mic_none), findsNothing);
    });

    testWidgets('sends the file with an empty message body', (tester) async {
      final sent = <String>[];
      await _pumpComposer(tester, sent.add);
      await _attachPastedImage(tester);

      await tester.tap(find.widgetWithIcon(IconButton, Icons.send));
      await tester.pumpAndSettle();

      expect(sent, hasLength(1));
      expect(sent.single, startsWith('[Attachment: pasted_image_'));
    });

    testWidgets('clears the attachment after sending', (tester) async {
      await _pumpComposer(tester, (_) {});
      await _attachPastedImage(tester);

      await tester.tap(find.widgetWithIcon(IconButton, Icons.send));
      await tester.pumpAndSettle();

      expect(find.byType(Chip), findsNothing);
      expect(find.widgetWithIcon(IconButton, Icons.mic_none), findsOneWidget);
    });

    testWidgets('shows the microphone again when removed', (tester) async {
      await _pumpComposer(tester, (_) {});
      await _attachPastedImage(tester);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byType(Chip), findsNothing);
      expect(find.widgetWithIcon(IconButton, Icons.mic_none), findsOneWidget);
      expect(find.widgetWithIcon(IconButton, Icons.send), findsNothing);
    });
  });
}
