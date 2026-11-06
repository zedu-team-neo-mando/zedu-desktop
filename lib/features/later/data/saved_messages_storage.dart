import 'package:hive/hive.dart';

import 'package:zedu/features/later/domain/domain.dart';

/// Persists [SavedMessage]s per organisation so each workspace keeps its own.
abstract class SavedMessagesStorage {
  Future<List<SavedMessage>> load(String orgId);

  Future<void> store(String orgId, List<SavedMessage> messages);
}

class HiveSavedMessagesStorage implements SavedMessagesStorage {
  static const _boxName = 'saved_messages';

  Box<dynamic>? _box;

  Future<Box<dynamic>> get _messagesBox async =>
      _box ??= await Hive.openBox<dynamic>(_boxName);

  @override
  Future<List<SavedMessage>> load(String orgId) async {
    final box = await _messagesBox;
    final raw = box.get(orgId);
    if (raw is! List) return const [];
    return [
      for (final entry in raw)
        if (entry is Map)
          SavedMessage.fromMap(Map<dynamic, dynamic>.from(entry)),
    ];
  }

  @override
  Future<void> store(String orgId, List<SavedMessage> messages) async {
    final box = await _messagesBox;
    await box.put(orgId, [for (final m in messages) m.toMap()]);
  }
}
