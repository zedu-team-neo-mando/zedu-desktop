import '../../../../../helpers/helpers.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockApiBaseService extends Mock implements ApiBaseService {}

class _RecordedCall {
  const _RecordedCall({required this.page, required this.search});

  final int page;
  final String? search;
}

class _FakeDmRepository extends DmRepository {
  _FakeDmRepository() : super(MockApiBaseService());

  final List<_RecordedCall> calls = [];
  List<DmConversation> nextResult = const [];

  @override
  Future<List<DmConversation>> getConversations({
    required String orgId,
    int page = 1,
    bool recentDm = false,
    String? search,
  }) async {
    calls.add(_RecordedCall(page: page, search: search));
    return nextResult;
  }
}

DmConversation _conversation(int index) {
  return DmConversation(
    channelId: 'channel-$index',
    username: 'User $index',
    participantId: 'user-$index',
    previewMessage: 'Message $index',
    unreadCount: 0,
  );
}

void main() {
  late _FakeDmRepository repository;

  ProviderContainer createContainer() {
    repository = _FakeDmRepository();
    final container = ProviderContainer(
      overrides: [
        dmRepositoryProvider.overrideWithValue(repository),
        currentOrgIdProvider.overrideWith((ref) => 'org-1'),
      ],
    );
    container.listen(dmListProvider, (_, _) {});
    addTearDown(container.dispose);
    return container;
  }

  group('DmListNotifier search', () {
    test('first page request carries no search term', () async {
      final container = createContainer();

      await container.read(dmListProvider.future);

      expect(repository.calls, hasLength(1));
      expect(repository.calls.single.page, 1);
      expect(repository.calls.single.search ?? '', isEmpty);
    });

    test('a new term reloads page 1 with search set', () async {
      final container = createContainer();
      await container.read(dmListProvider.future);

      container.read(dmSearchQueryProvider.notifier).set('ada');
      await container.read(dmListProvider.future);

      expect(repository.calls.last.page, 1);
      expect(repository.calls.last.search, 'ada');
    });

    test('loadMore keeps the active search term', () async {
      final container = createContainer();
      repository.nextResult = List.generate(
        DmRepository.pageSize,
        _conversation,
      );
      await container.read(dmListProvider.future);

      container.read(dmSearchQueryProvider.notifier).set('ada');
      await container.read(dmListProvider.future);
      repository.nextResult = [_conversation(99)];
      await container.read(dmListProvider.notifier).loadMore();

      expect(repository.calls.map((call) => call.page), [1, 1, 2]);
      expect(repository.calls.last.search, 'ada');
    });

    test(
      'an empty search result does not inject the mock conversation',
      () async {
        final container = createContainer();
        final unfiltered = await container.read(dmListProvider.future);
        expect(unfiltered.single.username, 'Test User');

        container.read(dmSearchQueryProvider.notifier).set('zzz');
        repository.nextResult = const [];
        final filtered = await container.read(dmListProvider.future);

        expect(filtered, isEmpty);
      },
    );
  });
}
