import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// Mounts the global DM incoming-message watcher: it runs while the user is
/// signed in with a workspace selected, and stops otherwise, so messages in
/// conversations nobody has opened still raise desktop notifications.
class DmIncomingWatcherListener extends ConsumerStatefulWidget {
  const DmIncomingWatcherListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DmIncomingWatcherListener> createState() =>
      _DmIncomingWatcherListenerState();
}

class _DmIncomingWatcherListenerState
    extends ConsumerState<DmIncomingWatcherListener> {
  @override
  void initState() {
    super.initState();
    ref.listenManual<AuthState>(
      authNotifierProvider,
      (previous, next) => _restart(),
      fireImmediately: true,
    );
    ref.listenManual<String>(
      currentOrgIdProvider,
      (previous, next) => _restart(),
      fireImmediately: true,
    );
  }

  void _restart() {
    final watcher = ref.read(dmIncomingWatcherProvider);
    watcher.stop();
    final signedIn =
        ref.read(authNotifierProvider).status == AuthStatus.authenticated;
    final orgId = ref.read(currentOrgIdProvider);
    if (signedIn && orgId.isNotEmpty) watcher.start();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
