import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import '../../../../../helpers/helpers.dart';

// Fake notifier that skips the repository lookup and profile load in build().
class FakeUserProfileNotifier extends UserProfileNotifier {
  @override
  UserProfileState build() => const UserProfileState();
}

Widget buildCreateOrganizationViewUnderTest() {
  return ProviderScope(
    overrides: [
      userProfileNotifierProvider.overrideWith(FakeUserProfileNotifier.new),
    ],
    child: buildTestMaterialApp(const CreateOrganizationView()),
  );
}

void main() {
  group('CreateOrganizationView', () {
    testWidgets('shows corrected hint text for name and type fields', (
      tester,
    ) async {
      await tester.pumpWidget(buildCreateOrganizationViewUnderTest());

      expect(find.text('Enter your organization name'), findsOneWidget);
      expect(find.text('What does your organization do?'), findsOneWidget);
      expect(find.text('Enter your organization Name'), findsNothing);
      expect(find.text('What does your organization do'), findsNothing);
    });

    testWidgets('country dropdown lists every country in kCountries', (
      tester,
    ) async {
      await tester.pumpWidget(buildCreateOrganizationViewUnderTest());

      final menu = tester.widget<DropdownMenu<String>>(
        find.byType(DropdownMenu<String>),
      );
      expect(menu.dropdownMenuEntries.length, kCountries.length);
      expect(
        menu.dropdownMenuEntries.map((entry) => entry.value),
        containsAll(['Ireland', 'Spain']),
      );
    });
  });
}
