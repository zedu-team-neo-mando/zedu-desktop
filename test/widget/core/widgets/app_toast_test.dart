import 'package:zedu/core/core.dart';

import '../../../helpers/helpers.dart';

void main() {
  testWidgets('dismissing a toast twice does not throw', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      buildTestMaterialApp(
        Scaffold(
          body: Builder(
            builder: (ctx) {
              context = ctx;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    AppToastService.show(context, type: AppToastType.info, message: 'first');
    await tester.pump();

    // Two close taps start two dismiss animations. The second must not remove
    // an OverlayEntry that the first already removed. Invoke the callbacks
    // directly because the toast is laid out against the app's design size,
    // outside the default 800x600 test surface.
    final close = find.byIcon(Icons.close_rounded);
    final gesture = tester.widget<GestureDetector>(
      find.ancestor(of: close, matching: find.byType(GestureDetector)).first,
    );
    gesture.onTap!();
    gesture.onTap!();

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // Drain the 4s auto-dismiss timer.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
