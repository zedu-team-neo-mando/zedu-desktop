import 'package:zedu/core/core.dart';
import 'package:zedu/features/dms/presentation/providers/dm_list_provider.dart'
    show currentOrgIdProvider;
import 'package:zedu/features/later/data/data.dart';
import 'package:zedu/features/later/domain/domain.dart';

/// Bookmarked messages of the current organisation, newest first.
class SavedMessagesNotifier extends AsyncNotifier<List<SavedMessage>> {
  SavedMessagesNotifier([SavedMessagesStorage? storage])
    : _storage = storage ?? HiveSavedMessagesStorage();

  final SavedMessagesStorage _storage;

  @override
  Future<List<SavedMessage>> build() async {
    return _storage.load(ref.watch(currentOrgIdProvider));
  }

  /// Adds the message (replacing an older bookmark of the same message id)
  /// and persists the list.
  Future<void> save(SavedMessage message) async {
    final current = state.value ?? const <SavedMessage>[];
    final updated = [
      message,
      ...current.where((m) => m.messageId != message.messageId),
    ];
    state = AsyncData(updated);
    await _storage.store(ref.read(currentOrgIdProvider), updated);
  }

  /// Removes the bookmark and persists the list.
  Future<void> remove(String messageId) async {
    final updated = (state.value ?? const <SavedMessage>[])
        .where((m) => m.messageId != messageId)
        .toList();
    state = AsyncData(updated);
    await _storage.store(ref.read(currentOrgIdProvider), updated);
  }
}

final savedMessagesProvider =
    AsyncNotifierProvider<SavedMessagesNotifier, List<SavedMessage>>(
      SavedMessagesNotifier.new,
    );
