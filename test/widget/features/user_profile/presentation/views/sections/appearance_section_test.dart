import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/core/theme/theme_mode_provider.dart';
import 'package:zedu/features/user_profile/presentation/views/sections/appearance_section.dart';

void main() {
  testWidgets('AppearanceSection renders options and toggles theme mode', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: AppearanceSection())),
      ),
    );

    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Color mode'), findsOneWidget);
    expect(
      find.text('Light'),
      findsNWidgets(2),
    ); // Card option and preview label
    expect(
      find.text('Dark'),
      findsNWidgets(2),
    ); // Card option and preview label
    expect(find.text('Auto'), findsOneWidget);

    // Tap on Dark card option
    await tester.tap(find.text("A darker look that's easier on the eyes."));
    await tester.pumpAndSettle();

    expect(container.read(themeModeProvider), ThemeMode.dark);

    // Tap on Light card option
    await tester.tap(find.text('A bright look for daytime use.'));
    await tester.pumpAndSettle();

    expect(container.read(themeModeProvider), ThemeMode.light);
  });
}
