import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// The Later section: every message the user bookmarked, newest first.
class LaterView extends ConsumerWidget {
  const LaterView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final saved = ref.watch(savedMessagesProvider);

    return Container(
      color: colors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            child: Text(
              'Later',
              style: context.textTheme.titleLarge?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(height: 1, color: colors.divider),
          Expanded(
            child: saved.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _LaterMessage(
                icon: Icons.error_outline,
                title: 'Could not load saved messages',
                subtitle: '$error',
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const _LaterMessage(
                    icon: Icons.bookmark_border,
                    title: 'Nothing saved yet',
                    subtitle:
                        'Hover a message in a DM and choose Save for later '
                        'to keep it here.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _SavedMessageTile(
                      key: ValueKey(item.messageId),
                      message: item,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedMessageTile extends ConsumerWidget {
  const _SavedMessageTile({super.key, required this.message});

  final SavedMessage message;

  Future<void> _open(WidgetRef ref) async {
    final dms = await ref
        .read(dmListProvider.future)
        .catchError((_) => const <DmConversation>[]);
    DmConversation? conversation;
    for (final dm in dms) {
      if (dm.channelId == message.conversationId) {
        conversation = dm;
        break;
      }
    }
    if (conversation == null) return;
    ref.read(homeSidebarProvider.notifier).setType(HomeSidebarType.dms);
    ref.read(selectedDmProvider.notifier).select(conversation);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: Material(
        color: colors.onPrimary,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: colors.divider),
          borderRadius: BorderRadius.circular(10),
        ),
        child: InkWell(
          onTap: () => _open(ref),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.bookmark, size: 18, color: colors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.snippet.isEmpty
                            ? 'Attachment'
                            : message.snippet,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${message.senderName} · ${message.conversationName} · '
                        'saved ${_formatSavedAt(message.savedAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: colors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: 'Open in conversation',
                  icon: Icon(
                    Icons.arrow_forward,
                    size: 18,
                    color: colors.textPrimary,
                  ),
                  onPressed: () => _open(ref),
                ),
                IconButton(
                  tooltip: 'Remove bookmark',
                  icon: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: colors.textHint,
                  ),
                  onPressed: () => ref
                      .read(savedMessagesProvider.notifier)
                      .remove(message.messageId),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatSavedAt(DateTime value) {
    final local = value.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    final days = today.difference(day).inDays;
    if (days == 0) {
      final hour = local.hour > 12
          ? local.hour - 12
          : (local.hour == 0 ? 12 : local.hour);
      final minute = local.minute.toString().padLeft(2, '0');
      final period = local.hour >= 12 ? 'PM' : 'AM';
      return 'today at $hour:$minute $period';
    }
    if (days == 1) return 'yesterday';
    return '${local.day}/${local.month}/${local.year}';
  }
}

class _LaterMessage extends StatelessWidget {
  const _LaterMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: colors.textHint),
          const SizedBox(height: 12),
          Text(
            title,
            style: context.textTheme.titleMedium?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.textHint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
