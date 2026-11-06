import '../../../../helpers/helpers.dart';
import 'package:zedu/features/features.dart';

void main() {
  test('SavedMessage roundtrips through a map', () {
    final original = SavedMessage(
      messageId: 'msg-1',
      orgId: 'org-1',
      conversationId: 'ch-1',
      conversationName: 'Ada Lovelace',
      senderName: 'Ada',
      snippet: 'hello there',
      savedAt: DateTime.utc(2026, 10, 17, 8, 30),
    );

    final restored = SavedMessage.fromMap(original.toMap());

    expect(restored.messageId, 'msg-1');
    expect(restored.orgId, 'org-1');
    expect(restored.conversationId, 'ch-1');
    expect(restored.conversationName, 'Ada Lovelace');
    expect(restored.senderName, 'Ada');
    expect(restored.snippet, 'hello there');
    expect(restored.savedAt, DateTime.utc(2026, 10, 17, 8, 30));
  });

  test('SavedMessage.fromMap tolerates missing fields', () {
    final restored = SavedMessage.fromMap(const {});

    expect(restored.messageId, '');
    expect(restored.orgId, '');
    expect(restored.conversationId, '');
    expect(restored.conversationName, '');
    expect(restored.senderName, '');
    expect(restored.snippet, '');
    expect(restored.savedAt, isA<DateTime>());
  });
}
