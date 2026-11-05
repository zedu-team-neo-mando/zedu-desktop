import 'dart:async';

import 'package:zedu/features/features.dart';

import '../../../../helpers/helpers.dart';

class _DriveTimer implements Timer {
  _DriveTimer(this._tick);

  final Function _tick;
  bool cancelled = false;

  /// Runs one tick and completes when the watcher's work for it settles, so
  /// tests can await a whole poll instead of racing the event queue.
  Future<void> fire() {
    final dynamic result = _tick();
    if (result is Future<void>) return result;
    return Future<void>.value();
  }

  @override
  void cancel() => cancelled = true;
  @override
  bool get isActive => !cancelled;
  @override
  int get tick => 0;
}

class _Notified {
  final Map<String, dynamic> message;
  final String channelId;
  final String sender;

  _Notified(this.message, this.channelId, this.sender);
}

DmConversation _conversation(
  String channelId, {
  String username = 'Amara',
  DmPreviewThread? latest,
}) {
  return DmConversation(
    channelId: channelId,
    username: username,
    participantId: 'u-participant',
    previewMessage: latest?.message ?? '',
    unreadCount: latest == null ? 0 : 1,
    previewThreads: latest == null ? const [] : [latest],
  );
}

DmPreviewThread _thread(
  String threadId, {
  String message = 'hello',
  String userId = 'sender-1',
  String username = 'Amara',
  DateTime? createdAt,
}) {
  return DmPreviewThread(
    threadId: threadId,
    message: message,
    userId: userId,
    username: username,
    createdAt: createdAt ?? DateTime(2026, 11, 5, 9),
  );
}

DmIncomingWatcher _watcher({
  required List<_DriveTimer> timers,
  required Future<List<DmConversation>> Function() fetchConversations,
  required bool Function(String channelId)? pollerActive,
  required List<_Notified> notified,
}) {
  bool Function(String) active = pollerActive ?? (_) => false;
  return DmIncomingWatcher(
    fetchConversations: fetchConversations,
    notify: (message, channelId, senderName) async {
      notified.add(_Notified(message, channelId, senderName));
    },
    pollerActive: active,
    createTimer: (interval, tick) {
      final timer = _DriveTimer(tick);
      timers.add(timer);
      return timer;
    },
  );
}

void main() {
  group('DmIncomingWatcher', () {
    test(
      'primes the first poll silently, then notifies only new threads',
      () async {
        final timers = <_DriveTimer>[];
        final notified = <_Notified>[];
        var threads = [_thread('t1', message: 'old message')];
        final service = _watcher(
          timers: timers,
          fetchConversations: () async => [
            _conversation('ch-1', latest: threads.first),
          ],
          pollerActive: null,
          notified: notified,
        );

        service.start();

        // First tick: baseline, no notification for the pre-existing message.
        await timers.single.fire();
        expect(notified, isEmpty);
        expect(service.latestThreadIds['ch-1'], 't1');

        // A brand-new message arrives in a conversation nobody opened.
        threads = [_thread('t2', message: 'new message')];
        await timers.single.fire();
        expect(notified, hasLength(1));
        expect(notified.single.channelId, 'ch-1');
        expect(notified.single.sender, 'Amara');
        expect(notified.single.message['id'], 't2');
        expect(notified.single.message['user_id'], 'sender-1');
        expect(notified.single.message['content'], 'new message');

        // The same thread again is not notified twice.
        await timers.single.fire();
        expect(notified, hasLength(1));

        service.stop();
      },
    );

    test(
      'channels with a live per-chat poller are left to their own poller',
      () async {
        final timers = <_DriveTimer>[];
        final notified = <_Notified>[];
        final openChannels = <String>{'ch-open'};
        final service = _watcher(
          timers: timers,
          fetchConversations: () async => [
            _conversation(
              'ch-open',
              latest: _thread('t1', message: 'direct hit'),
            ),
            _conversation(
              'ch-closed',
              latest: _thread('t2', message: 'watcher hit'),
            ),
          ],
          pollerActive: openChannels.contains,
          notified: notified,
        );

        service.start();
        await timers.single.fire();
        expect(notified, isEmpty);

        openChannels.remove('ch-open');
        await timers.single.fire();

        // The seen state was updated even while skipped, so once the chat is
        // closed the old thread is not announced all over again.
        expect(notified, isEmpty);
        service.stop();
      },
    );

    test('rows without a channel or without messages are ignored', () async {
      final timers = <_DriveTimer>[];
      final notified = <_Notified>[];
      var fromNetwork = false;
      final service = _watcher(
        timers: timers,
        fetchConversations: () async => fromNetwork
            ? [
                _conversation('', latest: _thread('t0')),
                _conversation('ch-empty'),
                _conversation(
                  'ch-real',
                  latest: _thread('t1', message: 'ping'),
                ),
              ]
            : [_conversation('ch-real', latest: _thread('t0'))],
        pollerActive: null,
        notified: notified,
      );

      service.start();
      await timers.single.fire();

      fromNetwork = true;
      await timers.single.fire();

      expect(notified, hasLength(1));
      expect(notified.single.channelId, 'ch-real');
      service.stop();
    });

    test(
      'a failed list poll is swallowed and the loop keeps working',
      () async {
        final timers = <_DriveTimer>[];
        final notified = <_Notified>[];
        var fail = false;
        var threads = [_thread('t1')];
        final service = _watcher(
          timers: timers,
          fetchConversations: () async {
            if (fail) throw Exception('network down');
            return [_conversation('ch-1', latest: threads.first)];
          },
          pollerActive: null,
          notified: notified,
        );

        service.start();
        await timers.single.fire();
        expect(service.isRunning, isTrue);

        fail = true;
        await timers.single.fire();
        expect(notified, isEmpty);

        fail = false;
        threads = [_thread('t2', message: 'after outage')];
        await timers.single.fire();
        expect(notified, hasLength(1));
        service.stop();
      },
    );

    test(
      'a slow poll does not pile ticks up and stop cancels the timer',
      () async {
        final timers = <_DriveTimer>[];
        final notified = <_Notified>[];
        final gate = Completer<void>();
        final service = _watcher(
          timers: timers,
          fetchConversations: () async {
            await gate.future;
            return [_conversation('ch-1', latest: _thread('t1'))];
          },
          pollerActive: null,
          notified: notified,
        );

        service.start();
        final timer = timers.single;

        // First poll still in flight: further ticks are dropped, not queued.
        unawaited(timer.fire());
        unawaited(timer.fire());
        timer.fire();
        gate.complete();
        await pumpEventQueue();

        expect(service.isRunning, isTrue);
        expect(timer.cancelled, isFalse);

        service.stop();
        expect(timer.cancelled, isTrue);
        expect(service.isRunning, isFalse);

        // A fresh start re-primes silently instead of replaying old threads.
        final notified2 = <_Notified>[];
        final timers2 = <_DriveTimer>[];
        final service2 = _watcher(
          timers: timers2,
          fetchConversations: () async => [
            _conversation('ch-1', latest: _thread('t1')),
          ],
          pollerActive: null,
          notified: notified2,
        );
        service2.start();
        await timers2.single.fire();
        expect(notified2, isEmpty);
        service2.stop();
      },
    );

    test('senders without a username fall back to Someone', () async {
      final timers = <_DriveTimer>[];
      final notified = <_Notified>[];
      var threads = [_thread('t1')];
      final service = _watcher(
        timers: timers,
        fetchConversations: () async => [
          _conversation('ch-1', username: '', latest: threads.first),
        ],
        pollerActive: null,
        notified: notified,
      );

      service.start();
      await timers.single.fire();

      threads = [_thread('t2', message: 'who is there')];
      await timers.single.fire();

      expect(notified, hasLength(1));
      expect(notified.single.sender, 'Someone');
      service.stop();
    });
  });
}
