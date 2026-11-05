import 'package:audioplayers/audioplayers.dart'
    show AudioPlayer, DeviceFileSource;
import 'package:zedu/core/core.dart';

class MessageBubble extends StatefulWidget {
  final String author;
  final String text;
  final String timestamp;
  final bool isSystem;

  const MessageBubble({
    super.key,
    required this.author,
    required this.text,
    required this.timestamp,
    this.isSystem = false,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  final Map<String, int> _reactions = {};
  bool _isHovering = false;

  void _addReaction(String emoji) {
    setState(() {
      _reactions[emoji] = (_reactions[emoji] ?? 0) + 1;
    });
  }

  void _toggleReaction(String emoji) {
    setState(() {
      if (_reactions.containsKey(emoji)) {
        if (_reactions[emoji]! > 1) {
          _reactions[emoji] = _reactions[emoji]! - 1;
        } else {
          _reactions.remove(emoji);
        }
      } else {
        _reactions[emoji] = 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final initial = avatarInitial(widget.author);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: widget.isSystem
                  ? colors.textHint.withValues(alpha: 0.1)
                  : colors.primary.withValues(alpha: 0.1),
              child: Text(
                initial,
                style: TextStyle(
                  color: widget.isSystem ? colors.textHint : colors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.author,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.timestamp,
                        style: TextStyle(fontSize: 11, color: colors.textHint),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _MessageBody(text: widget.text),
                  if (_reactions.isNotEmpty || _isHovering)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 4,
                        children: [
                          ..._reactions.entries.map((e) {
                            return InkWell(
                              onTap: () => _toggleReaction(e.key),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.primary.withValues(alpha: 0.1),
                                  border: Border.all(
                                    color: colors.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      e.key,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${e.value}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          if (_isHovering)
                            InkWell(
                              onTap: () async {
                                final emoji = await showMenu<String>(
                                  context: context,
                                  position: const RelativeRect.fromLTRB(
                                    100,
                                    100,
                                    0,
                                    0,
                                  ), // Adjust this or use a button's render box
                                  items: const [
                                    PopupMenuItem(
                                      value: '👍',
                                      child: Text('👍'),
                                    ),
                                    PopupMenuItem(
                                      value: '❤️',
                                      child: Text('❤️'),
                                    ),
                                    PopupMenuItem(
                                      value: '😂',
                                      child: Text('😂'),
                                    ),
                                    PopupMenuItem(
                                      value: '🎉',
                                      child: Text('🎉'),
                                    ),
                                    PopupMenuItem(
                                      value: '👎',
                                      child: Text('👎'),
                                    ),
                                  ],
                                );
                                if (emoji != null) {
                                  _addReaction(emoji);
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.background,
                                  border: Border.all(color: colors.divider),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.add_reaction_outlined,
                                  size: 14,
                                  color: colors.textHint,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBody extends StatelessWidget {
  final String text;

  const _MessageBody({required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (text.contains('[Voice Note Attached]')) {
      final voicePathMatch = RegExp(r'\[Voice Note: (.*?)\]').firstMatch(text);
      final voicePath = voicePathMatch?.group(1);
      if (voicePath != null && voicePath.isNotEmpty) {
        return _VoiceNotePlayer(path: voicePath);
      }
      return Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_circle_fill, color: colors.primary, size: 28),
            const SizedBox(width: 8),
            Container(
              height: 20,
              width: 100,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    final attachmentRegex = RegExp(r'\[Attachment: (.*?)\]');
    final matches = attachmentRegex.allMatches(text);
    final cleanText = text.replaceAll(attachmentRegex, '').trim();

    Widget markdownWidget = cleanText.isNotEmpty
        ? MarkdownBody(
            data: cleanText,
            onTapLink: (_, href, _) {
              if (href != null) openMessageLink(href);
            },
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(fontSize: 14, color: colors.textPrimary),
              strong: TextStyle(
                fontSize: 14,
                color: colors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              em: TextStyle(
                fontSize: 14,
                color: colors.textPrimary,
                fontStyle: FontStyle.italic,
              ),
              code: TextStyle(
                fontSize: 13,
                color: colors.primary,
                backgroundColor: colors.primary.withValues(alpha: 0.1),
                fontFamily: 'monospace',
              ),
            ),
          )
        : const SizedBox.shrink();

    if (matches.isNotEmpty) {
      final attachments = matches.map((m) => m.group(1)!).toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cleanText.isNotEmpty) markdownWidget,
          if (cleanText.isNotEmpty) const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: attachments.map((fileName) {
              final lowerName = fileName.toLowerCase();
              final isImage =
                  lowerName.endsWith('.png') ||
                  lowerName.endsWith('.jpg') ||
                  lowerName.endsWith('.jpeg') ||
                  lowerName.endsWith('.gif');
              final isVideo =
                  lowerName.endsWith('.mp4') ||
                  lowerName.endsWith('.mov') ||
                  lowerName.endsWith('.avi');

              return Container(
                width: isImage || isVideo ? 200 : 180,
                padding: isImage || isVideo
                    ? EdgeInsets.zero
                    : const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.background,
                  border: Border.all(color: colors.divider),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: isImage || isVideo
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Icon(
                                isImage ? Icons.image : Icons.videocam,
                                color: colors.primary.withValues(alpha: 0.5),
                                size: 48,
                              ),
                            ),
                          ),
                          if (isVideo)
                            const Icon(
                              Icons.play_circle_fill,
                              color: Colors.white,
                              size: 40,
                            ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(8),
                                  bottomRight: Radius.circular(8),
                                ),
                              ),
                              child: Text(
                                fileName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Icon(Icons.insert_drive_file, color: colors.textHint),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              fileName,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
              );
            }).toList(),
          ),
        ],
      );
    }

    return markdownWidget;
  }
}

class _VoiceNotePlayer extends StatefulWidget {
  final String path;

  const _VoiceNotePlayer({required this.path});

  @override
  State<_VoiceNotePlayer> createState() => _VoiceNotePlayerState();
}

class _VoiceNotePlayerState extends State<_VoiceNotePlayer> {
  AudioPlayer? _player;
  Duration? _duration;
  Duration _position = Duration.zero;
  bool _playing = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    try {
      final player = AudioPlayer();
      _player = player;
      player.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() {
            _playing = false;
            _position = Duration.zero;
          });
        }
      });
      player.onPositionChanged.listen((position) {
        if (mounted) setState(() => _position = position);
      });
      await player.setSource(DeviceFileSource(widget.path));
      final duration = await player.getDuration();
      if (mounted) {
        setState(() {
          _duration = duration;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _togglePlayback() async {
    final player = _player;
    if (player == null || _loading) return;
    try {
      if (_playing) {
        await player.pause();
        if (mounted) setState(() => _playing = false);
      } else {
        await player.resume();
        if (mounted) setState(() => _playing = true);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  String _format(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final duration = _duration;
    final fraction = duration != null && duration.inMilliseconds > 0
        ? (_position.inMilliseconds / duration.inMilliseconds)
              .clamp(0.0, 1.0)
              .toDouble()
        : 0.0;
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: _loading ? null : _togglePlayback,
            icon: Icon(
              _playing ? Icons.pause_circle_filled : Icons.play_circle_fill,
              color: colors.primary,
              size: 28,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: _playing ? 'Pause voice note' : 'Play voice note',
          ),
          const SizedBox(width: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Container(
              height: 6,
              width: 100,
              color: colors.primary.withValues(alpha: 0.2),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: fraction,
                child: Container(color: colors.primary),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _playing ? _format(_position) : _format(duration ?? _position),
            style: TextStyle(
              color: colors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
