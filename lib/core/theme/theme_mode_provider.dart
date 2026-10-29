import 'package:zedu/core/core.dart';

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _storageKey = 'app_theme_mode';

  @override
  ThemeMode build() {
    _loadFromStorage();
    return ThemeMode.system;
  }

  Future<void> _loadFromStorage() async {
    try {
      final storage = locator<SecureStorageService>();
      final saved = await storage.readData(_storageKey);
      if (saved != null) {
        state = switch (saved) {
          'light' => ThemeMode.light,
          'dark' => ThemeMode.dark,
          _ => ThemeMode.system,
        };
      }
    } catch (_) {
      // Default to system on storage read failure
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final storage = locator<SecureStorageService>();
      final val = switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
      await storage.writeData(_storageKey, val);
    } catch (_) {
      // Best-effort storage persistence
    }
  }
}
