import 'package:zedu/core/core.dart';

/// Registers the [AppConfig] the app's providers read through the locator.
///
/// Widget tests that pump a notifier which resolves configuration — the
/// workspace notifier does — need this, or they fail with "GetIt: Object/factory
/// with type AppConfig is not registered". Mock data keeps the fetch local and
/// deterministic.
void registerTestAppConfig({bool usesMockData = true}) {
  if (locator.isRegistered<AppConfig>()) locator.unregister<AppConfig>();
  locator.registerSingleton<AppConfig>(
    AppConfig(apiBaseUrl: 'http://test', usesMockData: usesMockData),
  );
}

/// Drops the registration between tests.
void unregisterTestAppConfig() {
  if (locator.isRegistered<AppConfig>()) locator.unregister<AppConfig>();
}
