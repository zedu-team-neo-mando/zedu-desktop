import '../../../../../helpers/helpers.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

SavedMessage message(String id, {String snippet = 'snippet'}) => SavedMessage(
  messageId: id,
  orgId: 'org-1',
  conversationId: 'ch-1',
  conversationName: 'Ada Lovelace',
  senderName: 'Ada',
  snippet: snippet,
  savedAt: DateTime.utc(2026, 10, 17, 8, 30),
);

void main() {
  test('loads an empty list from storage', () async {
    final storage = FakeSavedMessagesStorage();
    final container = ProviderContainer(
      overrides: [
        currentOrgIdProvider.overrideWithValue('org-1'),
        savedMessagesProvider.overrideWith(
          () => SavedMessagesNotifier(storage),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(await container.read(savedMessagesProvider.future), isEmpty);
  });

  test('save adds newest first and replaces the same message id', () async {
    final storage = FakeSavedMessagesStorage();
    final container = ProviderContainer(
      overrides: [
        currentOrgIdProvider.overrideWithValue('org-1'),
        savedMessagesProvider.overrideWith(
          () => SavedMessagesNotifier(storage),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(savedMessagesProvider.future);
    final notifier = container.read(savedMessagesProvider.notifier);

    await notifier.save(message('m1', snippet: 'first'));
    await notifier.save(message('m2', snippet: 'second'));
    await notifier.save(message('m1', snippet: 'first edited'));

    final saved = container.read(savedMessagesProvider).value!;
    expect(saved.map((m) => m.messageId).toList(), ['m1', 'm2']);
    expect(saved.first.snippet, 'first edited');
    expect(storage.saved['org-1'], hasLength(2));
  });

  test('remove drops the message and persists', () async {
    final storage = FakeSavedMessagesStorage({
      'org-1': [message('m1'), message('m2')],
    });
    final container = ProviderContainer(
      overrides: [
        currentOrgIdProvider.overrideWithValue('org-1'),
        savedMessagesProvider.overrideWith(
          () => SavedMessagesNotifier(storage),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(savedMessagesProvider.future);

    await container.read(savedMessagesProvider.notifier).remove('m1');

    final saved = container.read(savedMessagesProvider).value!;
    expect(saved.map((m) => m.messageId).toList(), ['m2']);
    expect(storage.saved['org-1'], hasLength(1));
  });
}
