import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

final currentOrgIdProvider = Provider<String>((ref) {
  final workspace = ref.watch(workspaceProvider).selectedWorkspace;
  return workspace?.id ?? '';
});

final dmListProvider =
    AsyncNotifierProvider<DmListNotifier, List<DmConversation>>(() {
      return DmListNotifier();
    });

class SelectedDmNotifier extends Notifier<DmConversation?> {
  @override
  DmConversation? build() => null;

  void select(DmConversation? conversation) {
    state = conversation;
  }
}

final selectedDmProvider =
    NotifierProvider<SelectedDmNotifier, DmConversation?>(
      SelectedDmNotifier.new,
    );

class DmSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) {
    if (state == value) return;
    state = value;
  }
}

final dmSearchQueryProvider = NotifierProvider<DmSearchQueryNotifier, String>(
  DmSearchQueryNotifier.new,
);

class DmListNotifier extends AsyncNotifier<List<DmConversation>> {
  int _currentPage = 1;
  bool _hasMore = true;

  bool get hasMore => _hasMore;

  @override
  Future<List<DmConversation>> build() async {
    final query = ref.watch(dmSearchQueryProvider);
    final orgId = ref.watch(currentOrgIdProvider);
    if (orgId.isEmpty) return const [];

    _currentPage = 1;
    _hasMore = true;
    return _fetchPage(orgId, 1, query);
  }

  Future<List<DmConversation>> _fetchPage(
    String orgId,
    int page,
    String query,
  ) async {
    final repository = ref.read(dmRepositoryProvider);
    final results = await repository.getConversations(
      orgId: orgId,
      page: page,
      search: query,
    );
    if (results.length < DmRepository.pageSize) {
      _hasMore = false;
    }

    if (results.isEmpty && page == 1 && query.isEmpty) {
      return [
        DmConversation(
          channelId: 'mock-channel-id-123',
          username: 'Test User',
          participantId: 'mock-user-id',
          previewMessage:
              'This is a test conversation. Tap to test the composer.',
          unreadCount: 0,
        ),
      ];
    }

    return results;
  }

  Future<void> loadMore() async {
    if (!_hasMore) return;
    final orgId = ref.read(currentOrgIdProvider);
    if (orgId.isEmpty) return;
    final query = ref.read(dmSearchQueryProvider);

    final current = state.value ?? [];
    _currentPage++;
    final next = await _fetchPage(orgId, _currentPage, query);
    // A new term rebuilt the list while this page was in flight.
    if (ref.read(dmSearchQueryProvider) != query) return;
    state = AsyncValue.data([...current, ...next]);
  }

  Future<void> refresh() async {
    final orgId = ref.read(currentOrgIdProvider);
    if (orgId.isEmpty) return;

    _currentPage = 1;
    _hasMore = true;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _fetchPage(orgId, 1, ref.read(dmSearchQueryProvider)),
    );
  }
}
