import 'dart:async';

import '../../../../../helpers/helpers.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockDmRepository extends Mock implements DmRepository {}

void main() {
  _deleteTests();
  _retryTests();
  _disposalTests();
  group('ChatHistoryNotifier.saveEdit', () {
    late MockDmRepository mockRepository;
    late ProviderContainer container;
    late ChatHistoryNotifier notifier;

    final initialMessages = <Map<String, dynamic>>[
      {'id': 'm1', 'content': 'hello', 'user_id': 'u1'},
    ];

    setUp(() async {
      mockRepository = MockDmRepository();
      when(
        () => mockRepository.getMessages(any(), page: any(named: 'page')),
      ).thenAnswer(
        (_) async => List<Map<String, dynamic>>.from(initialMessages),
      );

      container = ProviderContainer(
        overrides: [dmRepositoryProvider.overrideWithValue(mockRepository)],
      );
      notifier = container.read(chatHistoryProvider('ch-1'));
      await pumpEventQueue();
    });

    tearDown(() {
      container.dispose();
    });

    test('keeps the new content when the edit request succeeds', () async {
      when(
        () => mockRepository.editMessage(any(), content: any(named: 'content')),
      ).thenAnswer((_) async {});

      notifier.startEditing('m1');
      await notifier.saveEdit('m1', 'edited');

      expect(notifier.editingMessageId, isNull);
      expect(notifier.messages.single['content'], 'edited');
    });

    test(
      'reverts to the original content when the edit request fails',
      () async {
        when(
          () =>
              mockRepository.editMessage(any(), content: any(named: 'content')),
        ).thenThrow(Exception('network error'));

        notifier.startEditing('m1');
        await notifier.saveEdit('m1', 'edited');

        expect(notifier.editingMessageId, isNull);
        expect(notifier.messages.single['content'], 'hello');
      },
    );

    test(
      'reverts to null content when the edited message had no content',
      () async {
        when(
          () =>
              mockRepository.editMessage(any(), content: any(named: 'content')),
        ).thenThrow(Exception('network error'));

        notifier.messages = [
          {'id': 'm1', 'content': null, 'user_id': 'u1'},
        ];

        notifier.startEditing('m1');
        await notifier.saveEdit('m1', 'edited');

        expect(notifier.editingMessageId, isNull);
        expect(notifier.messages.single['content'], isNull);
      },
    );

    test(
      'keeps the newer edit when an older pending edit fails later',
      () async {
        final firstRequest = Completer<void>();
        var callCount = 0;
        when(
          () =>
              mockRepository.editMessage(any(), content: any(named: 'content')),
        ).thenAnswer((_) {
          callCount++;
          if (callCount == 1) return firstRequest.future;
          return Future.value();
        });

        notifier.startEditing('m1');
        final first = notifier.saveEdit('m1', 'edited1');
        notifier.startEditing('m1');
        final second = notifier.saveEdit('m1', 'edited2');

        firstRequest.completeError(Exception('network error'));
        await second;
        await first;

        expect(notifier.messages.single['content'], 'edited2');
      },
    );

    test(
      'keeps the newer save when an older edit with the same content fails',
      () async {
        final firstRequest = Completer<void>();
        var callCount = 0;
        when(
          () =>
              mockRepository.editMessage(any(), content: any(named: 'content')),
        ).thenAnswer((_) {
          callCount++;
          if (callCount == 1) return firstRequest.future;
          return Future.value();
        });

        notifier.startEditing('m1');
        final first = notifier.saveEdit('m1', 'edited');
        notifier.startEditing('m1');
        final second = notifier.saveEdit('m1', 'edited');

        firstRequest.completeError(Exception('network error'));
        await second;
        await first;

        expect(notifier.messages.single['content'], 'edited');
      },
    );

    test(
      'keeps another message being edited when a queued save starts',
      () async {
        final firstRequest = Completer<void>();
        var callCount = 0;
        when(
          () =>
              mockRepository.editMessage(any(), content: any(named: 'content')),
        ).thenAnswer((_) {
          callCount++;
          if (callCount == 1) return firstRequest.future;
          return Future.value();
        });

        notifier.messages = [
          {'id': 'm1', 'content': 'hello', 'user_id': 'u1'},
          {'id': 'm2', 'content': 'other', 'user_id': 'u1'},
        ];

        notifier.startEditing('m1');
        final first = notifier.saveEdit('m1', 'edited1');
        notifier.startEditing('m2');
        final second = notifier.saveEdit('m1', 'edited1b');

        firstRequest.complete();
        await first;
        await second;

        expect(notifier.editingMessageId, 'm2');
        expect(notifier.messages.first['content'], 'edited1b');
      },
    );

    test('reverts when two overlapping edits both fail', () async {
      when(
        () => mockRepository.editMessage(any(), content: any(named: 'content')),
      ).thenThrow(Exception('network error'));

      notifier.startEditing('m1');
      final first = notifier.saveEdit('m1', 'edited1');
      notifier.startEditing('m1');
      final second = notifier.saveEdit('m1', 'edited2');

      await first;
      await second;

      expect(notifier.messages.single['content'], 'hello');
    });
  });
}

void _deleteTests() {
  group('ChatHistoryNotifier.deleteMessage', () {
    late MockDmRepository mockRepository;
    late ProviderContainer container;
    late ChatHistoryNotifier notifier;

    setUp(() async {
      mockRepository = MockDmRepository();
      when(
        () => mockRepository.getMessages(any(), page: any(named: 'page')),
      ).thenAnswer(
        (_) async => [
          {'id': 'm1', 'content': 'hello', 'user_id': 'u1'},
          {'id': 'm2', 'content': 'again', 'user_id': 'u1'},
        ],
      );
      container = ProviderContainer(
        overrides: [dmRepositoryProvider.overrideWithValue(mockRepository)],
      );
      notifier = container.read(chatHistoryProvider('ch-1'));
      await pumpEventQueue();
    });

    tearDown(() => container.dispose());

    test('removes the message and calls the delete endpoint', () async {
      when(
        () => mockRepository.deleteMessage(
          threadId: any(named: 'threadId'),
          channelId: any(named: 'channelId'),
        ),
      ).thenAnswer((_) async {});

      await notifier.deleteMessage('m1');

      expect(notifier.messages.map((m) => m['id']), ['m2']);
      verify(
        () => mockRepository.deleteMessage(threadId: 'm1', channelId: 'ch-1'),
      ).called(1);
    });

    test('does not bring a deleted message back when polling', () async {
      when(
        () => mockRepository.deleteMessage(
          threadId: any(named: 'threadId'),
          channelId: any(named: 'channelId'),
        ),
      ).thenAnswer((_) async {});

      await notifier.deleteMessage('m1');
      await notifier.loadMore();

      expect(notifier.messages.map((m) => m['id']), isNot(contains('m1')));
    });

    test('puts the message back when the request fails', () async {
      when(
        () => mockRepository.deleteMessage(
          threadId: any(named: 'threadId'),
          channelId: any(named: 'channelId'),
        ),
      ).thenThrow(Exception('network error'));

      await notifier.deleteMessage('m1');

      expect(notifier.messages.map((m) => m['id']), ['m1', 'm2']);
    });
  });
}

void _disposalTests() {
  group('ChatHistoryNotifier disposal guards', () {
    test(
      'an edit that completes after dispose notifies no one and does not crash',
      () async {
        final mockRepository = MockDmRepository();
        when(
          () => mockRepository.getMessages(any(), page: any(named: 'page')),
        ).thenAnswer(
          (_) async => [
            {'id': 'm1', 'content': 'hello', 'user_id': 'u1'},
          ],
        );
        final editRequest = Completer<void>();
        when(
          () =>
              mockRepository.editMessage(any(), content: any(named: 'content')),
        ).thenAnswer((_) => editRequest.future);

        final container = ProviderContainer(
          overrides: [dmRepositoryProvider.overrideWithValue(mockRepository)],
        );
        var disposed = false;
        void disposeOnce() {
          if (!disposed) {
            disposed = true;
            container.dispose();
          }
        }

        addTearDown(disposeOnce);
        final notifier = container.read(chatHistoryProvider('ch-1'));
        await pumpEventQueue();

        // Detach and dispose the notifier while the edit request is in flight,
        // as happens when the user switches to another conversation.
        notifier.startEditing('m1');
        final edit = notifier.saveEdit('m1', 'edited');
        await pumpEventQueue();
        disposeOnce();

        editRequest.completeError(Exception('network error'));
        await edit;
        await pumpEventQueue();

        // Without the disposal guard, the late continuation would call
        // notifyListeners on the disposed notifier and crash here.
      },
    );

    test('a delete that completes after dispose does not crash', () async {
      final mockRepository = MockDmRepository();
      when(
        () => mockRepository.getMessages(any(), page: any(named: 'page')),
      ).thenAnswer(
        (_) async => [
          {'id': 'm1', 'content': 'hello', 'user_id': 'u1'},
        ],
      );
      final deleteRequest = Completer<void>();
      when(
        () => mockRepository.deleteMessage(
          threadId: any(named: 'threadId'),
          channelId: any(named: 'channelId'),
        ),
      ).thenAnswer((_) => deleteRequest.future);

      final container = ProviderContainer(
        overrides: [dmRepositoryProvider.overrideWithValue(mockRepository)],
      );
      var disposed = false;
      void disposeOnce() {
        if (!disposed) {
          disposed = true;
          container.dispose();
        }
      }

      addTearDown(disposeOnce);
      final notifier = container.read(chatHistoryProvider('ch-1'));
      await pumpEventQueue();

      // Fire the delete, then dispose the notifier before the HTTP request
      // resolves; with the guard the failing continuation stays a no-op.
      unawaited(notifier.deleteMessage('m1'));
      await pumpEventQueue();
      disposeOnce();

      deleteRequest.completeError(Exception('network error'));
      await pumpEventQueue();
    });
  });
}

class _FakeAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => AuthState(
    status: AuthStatus.authenticated,
    user: User(
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
      currentOrganisationSlug: 'org-slug',
      avatarUrl: '',
      defaultAvatarUrl: '',
    ),
  );
}

void _retryTests() {
  group('ChatHistoryNotifier.retryMessage', () {
    late MockDmRepository mockRepository;
    late ProviderContainer container;
    late ChatHistoryNotifier notifier;

    setUp(() async {
      mockRepository = MockDmRepository();
      when(
        () => mockRepository.getMessages(any(), page: any(named: 'page')),
      ).thenAnswer((_) async => []);

      container = ProviderContainer(
        overrides: [
          dmRepositoryProvider.overrideWithValue(mockRepository),
          authNotifierProvider.overrideWith(_FakeAuthNotifier.new),
        ],
      );
      notifier = container.read(chatHistoryProvider('channel-xyz'));
      await pumpEventQueue();
    });

    tearDown(() => container.dispose());

    test(
      'stores is_channel in optimistic message when sending channel message',
      () async {
        when(
          () => mockRepository.sendMessage(
            any(),
            any(),
            media: any(named: 'media'),
            mentions: any(named: 'mentions'),
            isChannel: any(named: 'isChannel'),
          ),
        ).thenAnswer((_) async => 'thread-1');

        await notifier.sendMessage('test content', isChannel: true);

        expect(notifier.messages.isNotEmpty, isTrue);
        expect(notifier.messages.first['is_channel'], isTrue);
      },
    );

    test(
      'retryMessage reads is_channel directly from failed message payload even when sendOptions are absent',
      () async {
        when(
          () => mockRepository.sendMessage(
            any(),
            any(),
            media: any(named: 'media'),
            mentions: any(named: 'mentions'),
            isChannel: any(named: 'isChannel'),
          ),
        ).thenAnswer((_) async => 'thread-retry');

        notifier.messages = [
          {
            'id': 'failed-msg-1',
            'content': 'Retrying channel message',
            'channel_id': 'channel-xyz',
            'status': 'failed',
            'is_channel': true,
          },
        ];

        await notifier.retryMessage('failed-msg-1');

        verify(
          () => mockRepository.sendMessage(
            'channel-xyz',
            'Retrying channel message',
            media: null,
            isChannel: true,
          ),
        ).called(1);
        expect(notifier.messages.first['status'], isNull);
        expect(notifier.messages.first['thread_id'], 'thread-retry');
      },
    );

    test(
      'retryMessage falls back to isChannel: false when message is a DM and has no is_channel flag',
      () async {
        when(
          () => mockRepository.sendMessage(
            any(),
            any(),
            media: any(named: 'media'),
            mentions: any(named: 'mentions'),
            isChannel: any(named: 'isChannel'),
          ),
        ).thenAnswer((_) async => 'thread-dm');

        notifier.messages = [
          {
            'id': 'failed-dm-1',
            'content': 'Retrying DM message',
            'channel_id': 'channel-xyz',
            'status': 'failed',
          },
        ];

        await notifier.retryMessage('failed-dm-1');

        verify(
          () => mockRepository.sendMessage(
            'channel-xyz',
            'Retrying DM message',
            media: null,
            isChannel: false,
          ),
        ).called(1);
      },
    );
  });
}
