import 'package:zedu/features/features.dart';
import '../../../../../helpers/helpers.dart';

void main() {
  testWidgets('disposes the search controller when the panel unmounts', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestMaterialApp(Scaffold(body: SearchPanel(onClose: () {}))),
    );
    final controller = tester
        .widget<TextField>(find.byType(TextField))
        .controller!;

    await tester.pumpWidget(buildTestMaterialApp(const SizedBox()));

    // A disposed ChangeNotifier rejects new listeners.
    expect(() => controller.addListener(() {}), throwsFlutterError);
  });
}
