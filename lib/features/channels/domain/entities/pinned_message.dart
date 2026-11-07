import 'package:zedu/features/features.dart';

/// A message pinned in a channel, as returned by
/// `GET /channels/pin/{channel_id}` (Ziki #17).
class PinnedMessage {
  /// The reply's id for a pinned reply, otherwise the thread id.
  final String id;
  final String senderName;
  final String text;
  final DateTime? createdAt;

  const PinnedMessage({
    required this.id,
    required this.senderName,
    required this.text,
    this.createdAt,
  });

  factory PinnedMessage.fromJson(Map<String, dynamic> json) {
    String? nonEmpty(Object? value) {
      final text = value?.toString().trim() ?? '';
      return text.isEmpty ? null : text;
    }

    return PinnedMessage(
      id: nonEmpty(json['message_id']) ?? nonEmpty(json['thread_id']) ?? '',
      senderName:
          nonEmpty(json['full_name']) ??
          nonEmpty(json['username']) ??
          nonEmpty(json['email']) ??
          'Unknown',
      // Messages sent from the web app arrive as HTML; ChannelMessage turns
      // that into plain text.
      text: ChannelMessage.fromJson({'message': json['message']}).text,
      createdAt: DateTime.tryParse(
        json['created_at']?.toString() ?? '',
      )?.toLocal(),
    );
  }
}
