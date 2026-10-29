import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/app/app.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class _FakeAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.unauthenticated);

  @override
  Future<void> login({required String email, required String password}) async {}

  @override
  Future<void> logout() async {}
}

class _FakeDmListNotifier extends DmListNotifier {
  @override
  Future<List<DmConversation>> build() async => const [];
}

class _FakeChannelNotifier extends ChannelNotifier {
  @override
  ChannelState build() => const ChannelState();
}

void main() {
  setUp(() {
    dotenv.loadFromString(
      envString: 'API_BASE_URL=https://api.example.com\nUSE_MOCK_DATA=true\n',
    );
    setupLocator();
  });

  tearDown(() async {
    await locator.reset();
    dotenv.clean();
  });

  testWidgets(
    'App installs WindowTitleListener, deep-link listeners and applies theme mode',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(_FakeAuthNotifier.new),
          dmListProvider.overrideWith(_FakeDmListNotifier.new),
          channelProvider.overrideWith(_FakeChannelNotifier.new),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const App()),
      );
      await tester.pump();

      // Verify listeners in App.builder are installed
      expect(find.byType(WindowTitleListener), findsOneWidget);
      expect(find.byType(CreditsPaymentDeepLinkListener), findsOneWidget);
      expect(find.byType(AuthDeepLinkListener), findsOneWidget);

      // Verify MaterialApp responds to themeModeProvider
      final initialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(initialApp.themeMode, ThemeMode.system);

      container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
      await tester.pump();

      final darkApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(darkApp.themeMode, ThemeMode.dark);

      container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
      await tester.pump();

      final lightApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(lightApp.themeMode, ThemeMode.light);
    },
  );
}
