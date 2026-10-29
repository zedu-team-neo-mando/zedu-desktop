import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Zedu',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: AppRouter.router,
      builder: (context, child) => WindowTitleListener(
        child: CreditsPaymentDeepLinkListener(
          child: AuthDeepLinkListener(child: child ?? const SizedBox.shrink()),
        ),
      ),
    );
  }
}
