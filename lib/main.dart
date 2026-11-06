import 'package:hive_flutter/hive_flutter.dart';

import 'package:zedu/core/core.dart';
import 'package:zedu/app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await loadAppEnv();
  setupLocator();
  // Saved messages (Later) live in a local Hive box.
  await Hive.initFlutter();

  runApp(const ProviderScope(child: App()));
}
