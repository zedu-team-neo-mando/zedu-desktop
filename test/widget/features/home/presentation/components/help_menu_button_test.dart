import 'package:zedu/features/features.dart';
import '../../../../../helpers/helpers.dart';

void main() {
  group('HelpMenuButton', () {
    testWidgets('opens a Help menu with an Export diagnostics option', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestMaterialApp(
          const Scaffold(body: Row(children: [HelpMenuButton()])),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('help-menu-button')));
      await tester.pumpAndSettle();

      expect(find.text('Export diagnostics'), findsOneWidget);
    });

    testWidgets('choosing Export diagnostics runs the export flow', (
      tester,
    ) async {
      var exports = 0;
      await tester.pumpWidget(
        buildTestMaterialApp(
          Scaffold(
            body: Row(
              children: [
                HelpMenuButton(
                  onExport: () async {
                    exports++;
                    return 'test.zip';
                  },
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('help-menu-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Export diagnostics'));
      await tester.pumpAndSettle();

      expect(exports, 1);

      // Let the success toast's auto-dismiss timer fire before the test ends.
      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(milliseconds: 400));
    });
  });
}
