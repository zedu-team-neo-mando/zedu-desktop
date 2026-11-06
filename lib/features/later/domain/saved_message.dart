/// A message the user bookmarked from a conversation for later reading.
class SavedMessage {
  const SavedMessage({
    required this.messageId,
    required this.orgId,
    required this.conversationId,
    required this.conversationName,
    required this.senderName,
    required this.snippet,
    required this.savedAt,
  });

  final String messageId;
  final String orgId;

  /// The DM channel id (or channel id) the message belongs to.
  final String conversationId;

  /// Display name of the conversation, e.g. a DM contact name.
  final String conversationName;
  final String senderName;
  final String snippet;
  final DateTime savedAt;

  Map<String, dynamic> toMap() => {
    'messageId': messageId,
    'orgId': orgId,
    'conversationId': conversationId,
    'conversationName': conversationName,
    'senderName': senderName,
    'snippet': snippet,
    'savedAt': savedAt.toIso8601String(),
  };

  factory SavedMessage.fromMap(Map<dynamic, dynamic> map) {
    return SavedMessage(
      messageId: map['messageId']?.toString() ?? '',
      orgId: map['orgId']?.toString() ?? '',
      conversationId: map['conversationId']?.toString() ?? '',
      conversationName: map['conversationName']?.toString() ?? '',
      senderName: map['senderName']?.toString() ?? '',
      snippet: map['snippet']?.toString() ?? '',
      savedAt:
          DateTime.tryParse(map['savedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
