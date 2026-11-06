import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// The latest messages of a channel, newest first.
final channelHistoryProvider = FutureProvider.autoDispose
    .family<List<ChannelMessage>, String>((ref, channelId) async {
      final result = await ref
          .watch(channelRepositoryProvider)
          .fetchChannelMessages(channelId);
      return switch (result) {
        Success<List<ChannelMessage>>(:final value) => value,
        Failure<List<ChannelMessage>>(:final error) => throw error,
      };
    });

/// The people in a channel, for @mention suggestions in its composer.
final channelMembersProvider = FutureProvider.autoDispose
    .family<List<DmParticipant>, String>((ref, channelId) async {
      final result = await ref
          .watch(channelRepositoryProvider)
          .fetchChannelMembers(channelId);
      return switch (result) {
        Success<List<DmParticipant>>(:final value) => value,
        Failure<List<DmParticipant>>(:final error) => throw error,
      };
    });

/// The usernames of everyone who reacted with a given reaction on a message.
final reactionUsersProvider = FutureProvider.autoDispose
    .family<List<String>, ({String reactionId, String threadId})>((
      ref,
      key,
    ) async {
      final result = await ref
          .watch(channelRepositoryProvider)
          .fetchReactionUsers(
            reactionId: key.reactionId,
            threadId: key.threadId,
          );
      return switch (result) {
        Success<List<String>>(:final value) => value,
        Failure<List<String>>(:final error) => throw error,
      };
    });
