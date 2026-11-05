import 'dart:async';

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// Polls the signed-in user's DM conversation list so a message in a
/// conversation that was never opened this session still reaches the desktop
/// notification path. The per-chat poller in [ChatHistoryNotifier] only runs
/// for conversations the user has opened, which left every other conversation
/// silent.
class DmIncomingWatcher {
  DmIncomingWatcher({
    required Future<List<DmConversation>> Function() fetchConversations,
    required this.notify,
    required this.pollerActive,
    this.interval = defaultInterval,
    Timer Function(Duration, void Function())? createTimer,
  }) : _fetchConversations = fetchConversations,
       _createTimer =
           createTimer ??
           ((interval, tick) => Timer.periodic(interval, (_) => tick()));

  /// Slow enough not to hammer the dms list endpoint; new messages reach the
  /// open conversations through their own 10-second pollers regardless.
  static const Duration defaultInterval = Duration(seconds: 15);

  /// Latest-thread ids remembered per channel this run.
  final Map<String, String> latestThreadIds = {};

  final Future<List<DmConversation>> Function() _fetchConversations;
  final Future<void> Function(
    Map<String, dynamic> message,
    String channelId,
    String senderName,
  )
  notify;

  /// Channels whose per-chat poller already handles notifications are left to
  /// it, so the two pollers never notify twice about the same message.
  final bool Function(String channelId) pollerActive;
  final Duration interval;

  final Timer Function(Duration, void Function()) _createTimer;

  Timer? _timer;
  bool _busy = false;
  bool _primed = false;

  bool get isRunning => _timer != null;

  /// Starts the loop. Each [start] re-primes the seen state, so a fresh run
  /// after an org switch or re-mount never replays old messages.
  void start() {
    if (isRunning) return;
    _primed = false;
    latestThreadIds.clear();
    _timer = _createTimer(interval, _tick);
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    latestThreadIds.clear();
    _primed = false;
  }

  Future<void> _tick() async {
    // A slow fetch must not pile ticks up.
    if (_busy || !isRunning) return;
    _busy = true;
    try {
      await _poll();
    } catch (_) {
      // A failed list poll just waits for the next tick; notifications and
      // message loading are not urgent enough to crash over.
    } finally {
      _busy = false;
    }
  }

  Future<void> _poll() async {
    final conversations = await _fetchConversations();

    for (final conversation in conversations) {
      final channelId = conversation.channelId;
      if (channelId.isEmpty) continue;

      final latest = _latestThread(conversation);
      if (latest == null) {
        latestThreadIds.remove(channelId);
        continue;
      }

      final known = latestThreadIds[channelId];
      latestThreadIds[channelId] = latest.threadId;

      // First sight is the baseline: mark everything seen silently.
      if (!_primed) continue;
      if (known == null || known == latest.threadId) continue;
      // The per-chat poller already notifies about its own channel.
      if (pollerActive(channelId)) continue;

      await notify(
        <String, dynamic>{
          'id': latest.threadId,
          'user_id': latest.userId,
          'content': latest.message,
        },
        channelId,
        conversation.username.isNotEmpty ? conversation.username : 'Someone',
      );
    }

    _primed = true;
  }

  /// The newest message of the conversation, or null when it has none.
  DmPreviewThread? _latestThread(DmConversation conversation) {
    final threads = conversation.previewThreads;
    if (threads.isEmpty) return null;
    return threads.first;
  }
}

final dmIncomingWatcherProvider = Provider<DmIncomingWatcher>((ref) {
  final watcher = DmIncomingWatcher(
    fetchConversations: () async {
      final orgId = ref.read(currentOrgIdProvider);
      if (orgId.isEmpty) return const <DmConversation>[];
      return ref.read(dmRepositoryProvider).getConversations(orgId: orgId);
    },
    notify: (message, channelId, senderName) => ref
        .read(notificationServiceProvider)
        .handleIncomingMessage(message, channelId, senderName),
    pollerActive: (channelId) => ref.exists(chatHistoryProvider(channelId)),
  );
  ref.onDispose(watcher.stop);
  return watcher;
});
