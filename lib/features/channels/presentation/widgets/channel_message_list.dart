import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// The messages of a channel, newest at the bottom. Shows [empty] when the
/// channel has no messages yet.
class ChannelMessageList extends ConsumerWidget {
  const ChannelMessageList({
    super.key,
    required this.channelId,
    required this.empty,
  });

  final String channelId;
  final Widget empty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatHistory = ref.watch(chatHistoryProvider(channelId));
    final pendingMessages = chatHistory.messages
        .where(
          (m) =>
              m['status'] != null &&
              (m['channel_id'] == channelId || m['is_channel'] == true),
        )
        .map(
          (m) => ChannelMessage(
            id: m['id']?.toString(),
            senderName: (m['sender_name'] as String?)?.isNotEmpty == true
                ? m['sender_name'] as String
                : chatHistory.currentUserName,
            avatarUrl: (m['avatar_url'] as String?)?.isNotEmpty == true
                ? m['avatar_url'] as String
                : chatHistory.currentUserAvatarUrl,
            text: m['content']?.toString() ?? '',
            createdAt: DateTime.tryParse(
              m['created_at']?.toString() ?? '',
            )?.toLocal(),
            status: m['status']?.toString(),
          ),
        )
        .toList();

    return ref
        .watch(channelHistoryProvider(channelId))
        .when(
          loading: () => pendingMessages.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _buildList(context, ref, pendingMessages),
          error: (_, _) => pendingMessages.isEmpty
              ? Center(
                  child: TextButton(
                    onPressed: () =>
                        ref.invalidate(channelHistoryProvider(channelId)),
                    child: const Text("Couldn't load messages. Retry"),
                  ),
                )
              : _buildList(context, ref, pendingMessages),
          data: (serverMessages) {
            final allMessages = [...pendingMessages, ...serverMessages];
            return allMessages.isEmpty
                ? empty
                : _buildList(context, ref, allMessages);
          },
        );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    List<ChannelMessage> messages,
  ) {
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return ChannelMessageTile(
          channelId: channelId,
          message: message,
          onRetry: message.id != null
              ? () => ref
                    .read(chatHistoryProvider(channelId))
                    .retryMessage(message.id!)
              : null,
        );
      },
    );
  }
}

class ChannelMessageTile extends ConsumerStatefulWidget {
  const ChannelMessageTile({
    super.key,
    required this.channelId,
    required this.message,
    this.onRetry,
  });

  final String channelId;
  final ChannelMessage message;
  final VoidCallback? onRetry;

  @override
  ConsumerState<ChannelMessageTile> createState() => _ChannelMessageTileState();
}

class _ChannelMessageTileState extends ConsumerState<ChannelMessageTile> {
  /// Emojis with a toggle request still in flight, to block double taps.
  final Set<String> _busyEmojis = {};

  ChannelMessage get _message => widget.message;

  Future<void> _toggleReaction(String emoji, {String? reactionId}) async {
    final messageId = _message.id;
    if (messageId == null || messageId.isEmpty) return;
    if (_busyEmojis.contains(emoji)) return;

    setState(() => _busyEmojis.add(emoji));
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
    try {
      final result = await ref
          .read(channelRepositoryProvider)
          .toggleReaction(
            channelId: widget.channelId,
            threadId: messageId,
            emoji: emoji,
          );
      switch (result) {
        case Success<bool>():
          ref.invalidate(channelHistoryProvider(widget.channelId));
          if (reactionId != null && reactionId.isNotEmpty) {
            ref.invalidate(
              reactionUsersProvider((
                reactionId: reactionId,
                threadId: messageId,
              )),
            );
          }
        case Failure<bool>(:final error):
          scaffoldMessenger?.showSnackBar(
            SnackBar(content: Text(error.message)),
          );
      }
    } finally {
      if (mounted) setState(() => _busyEmojis.remove(emoji));
    }
  }

  void _openEmojiPicker() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: DmEmojiPicker(
          onEmojiSelected: (emoji) {
            Navigator.of(dialogContext).pop();
            _toggleReaction(emoji);
          },
          onClose: () => Navigator.of(dialogContext).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final avatarUrl = _message.avatarUrl;
    final time = _message.createdAt;
    final initial = avatarInitial(_message.senderName);
    final status = _message.status;
    final hasReactions = _message.reactions.isNotEmpty;
    final canReact =
        _message.id != null && _message.id!.isNotEmpty && status == null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: colors.primary,
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? Text(initial, style: TextStyle(color: colors.onPrimary))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    text: _message.senderName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                    children: [
                      if (time != null)
                        TextSpan(
                          text:
                              '  ${TimeOfDay.fromDateTime(time).format(context)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                            color: colors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                MessageLinkScope(
                  builder: (context, links) => SelectableText.rich(
                    links.span(
                      _message.text,
                      TextStyle(fontSize: 15, color: colors.textPrimary),
                    ),
                  ),
                ),
                if (hasReactions || canReact)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        for (final reaction in _message.reactions)
                          _ReactionPill(
                            reaction: reaction,
                            reacted: _didUserReact(reaction),
                            busy: _busyEmojis.contains(reaction.emoji),
                            onTap: () => _toggleReaction(
                              reaction.emoji,
                              reactionId: reaction.reactionId,
                            ),
                          ),
                        if (canReact)
                          IconButton(
                            onPressed: _openEmojiPicker,
                            icon: Icon(
                              Icons.add_reaction_outlined,
                              size: 18,
                              color: colors.textHint,
                            ),
                            tooltip: 'Add reaction',
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                  ),
                if (status != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: status == 'failed'
                        ? GestureDetector(
                            onTap: widget.onRetry,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 13,
                                  color: colors.error,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Failed – Tap to retry',
                                  style: TextStyle(
                                    color: colors.error,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Text(
                            status == 'sending' ? 'Sending...' : '',
                            style: TextStyle(
                              color: colors.textHint,
                              fontSize: 11,
                            ),
                          ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _didUserReact(ChannelReaction reaction) {
    final messageId = _message.id ?? '';
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final String? myUsername = user == null
        ? null
        : (user.username.isEmpty ? user.email.split('@').first : user.username)
              .toLowerCase();
    if (myUsername == null) return false;
    final users = ref
        .watch(
          reactionUsersProvider((
            reactionId: reaction.reactionId,
            threadId: messageId,
          )),
        )
        .value;
    return users?.any((u) => u.toLowerCase() == myUsername) ?? false;
  }
}

class _ReactionPill extends StatelessWidget {
  const _ReactionPill({
    required this.reaction,
    required this.reacted,
    required this.busy,
    required this.onTap,
  });

  final ChannelReaction reaction;
  final bool reacted;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final background = reacted ? colors.primary : colors.background;
    final border = reacted ? colors.primary : colors.divider;
    final foreground = reacted ? colors.onPrimary : colors.textSecondary;

    return Material(
      color: background,
      shape: StadiumBorder(side: BorderSide(color: border)),
      child: InkWell(
        onTap: busy ? null : onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(reaction.emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                '${reaction.count}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
