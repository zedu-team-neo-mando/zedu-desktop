import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../../helpers/helpers.dart';

void main() {
  testWidgets('Delete organization uses the error colour token', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildTestMaterialApp(
        Scaffold(
          body: OrganizationSection(
            organization: const OrganizationProfile(
              id: 'org-1',
              name: 'Acme',
              natureOfBusiness: 'Technology',
              country: 'Nigeria',
            ),
            isSaving: false,
            onSave: (_) {},
            onDelete: () async {},
            onLeave: () async {},
          ),
        ),
      ),
    );

    final button = tester.widget<OutlinedButton>(
      find.ancestor(
        of: find.text('Delete organization'),
        matching: find.byType(OutlinedButton),
      ),
    );
    final style = button.style!;
    final error = AppPalette.light.error;

    expect(style.foregroundColor!.resolve({}), error);
    expect(style.side!.resolve({})!.color, error);
  });
}
