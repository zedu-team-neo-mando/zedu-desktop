import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

const _workspaceA = Workspace(id: 'org-a', name: 'Workspace A', avatar: '');

class _FakeWorkspaceNotifier extends WorkspaceNotifier {
  @override
  WorkspaceState build() =>
      const WorkspaceState(selectedWorkspace: _workspaceA);
}

void main() {
  late ProviderContainer container;

  Future<void> pumpToolbar(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    container = ProviderContainer(
      overrides: [workspaceProvider.overrideWith(_FakeWorkspaceNotifier.new)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: buildTestMaterialApp(const Scaffold(body: FilesToolbar())),
      ),
    );
  }

  testWidgets('the sort control states the sort that is applied', (
    tester,
  ) async {
    await pumpToolbar(tester);

    expect(find.text('Sort: Newest to oldest'), findsOneWidget);
  });

  testWidgets('the sort control is marked active', (tester) async {
    await pumpToolbar(tester);

    final label = tester.widget<Text>(find.text('Sort: Newest to oldest'));
    expect(label.style?.color, AppPalette.light.primary);
  });

  testWidgets('choosing a sort updates the control without opening the menu', (
    tester,
  ) async {
    await pumpToolbar(tester);

    await tester.tap(find.text('Sort: Newest to oldest'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oldest to newest'));
    await tester.pumpAndSettle();

    expect(find.text('Sort: Oldest to newest'), findsOneWidget);
    expect(find.text('Sort: Newest to oldest'), findsNothing);
    expect(container.read(filesProvider).sort, FilesSort.oldestFirst);
  });

  testWidgets('the other filters keep their own placeholder', (tester) async {
    await pumpToolbar(tester);

    expect(find.text('File Type'), findsOneWidget);
    expect(find.text('Date Modified'), findsOneWidget);
  });
}
