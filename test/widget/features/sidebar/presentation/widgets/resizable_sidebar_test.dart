import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

/// Wires the sidebar the way the Home screen does, and lets a test remove and
/// show it again.
class _Host extends ConsumerWidget {
  const _Host({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!visible) return const SizedBox.shrink();
    return ResizableSidebar(
      initialWidth: ref.read(sidebarWidthProvider),
      onWidthChanged: ref.read(sidebarWidthProvider.notifier).setWidth,
      child: const SizedBox.expand(),
    );
  }
}

void main() {
  const sidebarKey = ValueKey('resizable-sidebar');
  const handleKey = ValueKey('resizable-sidebar-handle');

  Future<void> pumpHost(WidgetTester tester, {required bool visible}) =>
      tester.pumpWidget(
        ProviderScope(
          // Reusing the container keeps state across the two pumps below.
          key: const ValueKey('scope'),
          child: buildTestMaterialApp(Scaffold(body: _Host(visible: visible))),
        ),
      );

  testWidgets('draws the drag handle with the border token', (tester) async {
    await tester.pumpWidget(
      buildTestMaterialApp(
        const Scaffold(
          body: Row(children: [ResizableSidebar(child: SizedBox.expand())]),
        ),
      ),
    );

    final handle = tester.widget<Container>(
      find.byKey(const ValueKey('resizable-sidebar-handle-line')),
    );

    expect(handle.color, AppPalette.light.borderOutline);
  });

  testWidgets('keeps the dragged width when the sidebar is shown again', (
    tester,
  ) async {
    await pumpHost(tester, visible: true);
    expect(
      tester.getSize(find.byKey(sidebarKey)).width,
      ResizableSidebar.defaultWidth,
    );

    final drag = await tester.startGesture(
      tester.getCenter(find.byKey(handleKey)),
    );
    await drag.moveBy(const Offset(-80, 0));
    await drag.up();
    await tester.pump();
    final draggedWidth = tester.getSize(find.byKey(sidebarKey)).width;
    expect(draggedWidth, lessThan(ResizableSidebar.defaultWidth));

    await pumpHost(tester, visible: false);
    expect(find.byKey(sidebarKey), findsNothing);
    await pumpHost(tester, visible: true);

    expect(tester.getSize(find.byKey(sidebarKey)).width, draggedWidth);
  });

  test('sidebarWidthProvider starts at the default width', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(sidebarWidthProvider), ResizableSidebar.defaultWidth);
  });
}
