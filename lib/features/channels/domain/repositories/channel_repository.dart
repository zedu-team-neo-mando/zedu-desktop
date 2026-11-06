import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

abstract class ChannelRepository {
  Future<Result<List<Channel>>> fetchChannels(String orgId);
  Future<Result<Channel>> createChannel({
    required String name,
    required String description,
    required String orgId,
    required String username,
    required bool isPrivate,
    String? topic,
  });
  Future<Result<void>> updateChannelTopicOrDescription({
    required String channelId,
    String? topic,
    String? description,
  });
  Future<Result<void>> archiveChannel(String channelId, bool archived);

  /// Removes the current user from the channel.
  Future<Result<void>> leaveChannel(String channelId);
  Future<Result<List<String>>> fetchOrganisationMemberIds(String orgId);
  Future<Result<List<String>>> fetchChannelMemberIds(String channelId);
  Future<Result<List<DmParticipant>>> fetchChannelMembers(String channelId);
  Future<Result<void>> addMembersToChannel({
    required String channelId,
    required List<String> userIds,
  });

  /// The latest messages of a channel, newest first.
  Future<Result<List<ChannelMessage>>> fetchChannelMessages(String channelId);

  /// Usernames of the users who reacted with [reactionId] on [threadId].
  Future<Result<List<String>>> fetchReactionUsers({
    required String reactionId,
    required String threadId,
  });

  /// Adds the current user's [emoji] reaction to [threadId], or removes it
  /// if they have already reacted. Returns whether the user reacted now.
  Future<Result<bool>> toggleReaction({
    required String channelId,
    required String threadId,
    required String emoji,
  });
}
