import 'package:zedu/features/features.dart';

class FakeSavedMessagesStorage implements SavedMessagesStorage {
  FakeSavedMessagesStorage([Map<String, List<SavedMessage>>? initial])
    : saved = initial ?? {};

  final Map<String, List<SavedMessage>> saved;

  @override
  Future<List<SavedMessage>> load(String orgId) async =>
      saved[orgId] ?? const [];

  @override
  Future<void> store(String orgId, List<SavedMessage> messages) async {
    saved[orgId] = messages;
  }
}
