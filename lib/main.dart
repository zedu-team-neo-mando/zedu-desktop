import 'dart:io' show exit;

import 'package:zedu/core/core.dart';
import 'package:zedu/app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  // A second launch must focus the running window, not open another one.
  final singleInstance = SingleInstance(
    onSecondLaunch: () async {
      try {
        if (await windowManager.isMinimized()) {
          await windowManager.restore();
        }
        await windowManager.show();
        await windowManager.focus();
      } catch (error) {
        debugPrint('Failed to focus the running window: $error');
      }
    },
  );
  if (!await singleInstance.ensurePrimary()) {
    exit(0);
  }

  await loadAppEnv();
  setupLocator();

  runApp(const ProviderScope(child: App()));
}
