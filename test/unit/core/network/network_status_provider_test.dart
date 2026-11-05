import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/core/core.dart';

void main() {
  group('NetworkStatusNotifier', () {
    test(
      'initializes as online and updates to offline when reachability fails',
      () async {
        final container = ProviderContainer(
          overrides: [
            reachabilityCheckerProvider.overrideWithValue(() async => false),
          ],
        );
        addTearDown(container.dispose);

        // Trigger build
        expect(container.read(networkStatusProvider), NetworkStatus.online);

        // Allow async reachability check to complete
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(container.read(networkStatusProvider), NetworkStatus.offline);
      },
    );

    test('updates to online when reachability succeeds', () async {
      final container = ProviderContainer(
        overrides: [
          reachabilityCheckerProvider.overrideWithValue(() async => true),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(networkStatusProvider), NetworkStatus.online);

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(container.read(networkStatusProvider), NetworkStatus.online);
    });

    test('manual controls override network state correctly', () async {
      final container = ProviderContainer(
        overrides: [
          reachabilityCheckerProvider.overrideWithValue(() async => true),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(networkStatusProvider.notifier);

      notifier.setOffline();
      expect(container.read(networkStatusProvider), NetworkStatus.offline);

      notifier.setOnline();
      expect(container.read(networkStatusProvider), NetworkStatus.online);

      notifier.toggle();
      expect(container.read(networkStatusProvider), NetworkStatus.offline);

      notifier.toggle();
      expect(container.read(networkStatusProvider), NetworkStatus.online);
    });

    test(
      'checkReachability transitions state dynamically on network recovery',
      () async {
        bool isConnected = false;
        final container = ProviderContainer(
          overrides: [
            reachabilityCheckerProvider.overrideWithValue(
              () async => isConnected,
            ),
          ],
        );
        addTearDown(container.dispose);

        // Initialize provider
        container.read(networkStatusProvider);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(container.read(networkStatusProvider), NetworkStatus.offline);

        // Simulate connection restored
        isConnected = true;
        await container
            .read(networkStatusProvider.notifier)
            .checkReachability();
        expect(container.read(networkStatusProvider), NetworkStatus.online);
      },
    );

    test('disposing container cleanly cancels monitoring timer', () async {
      final container = ProviderContainer(
        overrides: [
          reachabilityCheckerProvider.overrideWithValue(() async => true),
        ],
      );

      container.read(networkStatusProvider);
      expect(() => container.dispose(), returnsNormally);
    });

    test('drops an older check that lands after a newer one', () async {
      final pending = <Completer<bool>>[];
      final container = ProviderContainer(
        overrides: [
          reachabilityCheckerProvider.overrideWithValue(
            _completerChecker(pending),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(networkStatusProvider.notifier);
      final second = notifier.checkReachability();
      expect(pending.length, 2);

      pending[1].complete(true);
      await second;
      expect(container.read(networkStatusProvider), NetworkStatus.online);

      // The first check finishes late, saying the opposite of the newer one.
      pending[0].complete(false);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(networkStatusProvider), NetworkStatus.online);
    });

    test('an explicit mark wins over a check already in flight', () async {
      final pending = <Completer<bool>>[];
      final container = ProviderContainer(
        overrides: [
          reachabilityCheckerProvider.overrideWithValue(
            _completerChecker(pending),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(networkStatusProvider.notifier);
      notifier.setOffline();

      pending[0].complete(true);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(networkStatusProvider), NetworkStatus.offline);
    });

    test('a failing newest check still marks the network offline', () async {
      final container = ProviderContainer(
        overrides: [
          reachabilityCheckerProvider.overrideWithValue(() async {
            throw StateError('lookup blew up');
          }),
        ],
      );
      addTearDown(container.dispose);

      container.read(networkStatusProvider);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(networkStatusProvider), NetworkStatus.offline);
    });
  });
}

/// A checker that hands back a pending Completer per call, so the test decides
/// the order in which checks finish instead of the runtime deciding it.
ReachabilityChecker _completerChecker(List<Completer<bool>> sink) {
  return () {
    final completer = Completer<bool>();
    sink.add(completer);
    return completer.future;
  };
}
