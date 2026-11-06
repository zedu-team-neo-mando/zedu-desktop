import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

class _FakeWorkspaceNotifier extends WorkspaceNotifier {
  @override
  WorkspaceState build() => const WorkspaceState(
    selectedWorkspace: Workspace(id: 'org-1', name: 'Workspace A', avatar: ''),
  );
}

class _FakePlannerRepository implements PlannerRepository {
  _FakePlannerRepository({
    Map<PlannerFilter, List<Checkpoint>>? checkpoints,
    this.failing = false,
  }) : checkpoints = checkpoints ?? const {};

  final Map<PlannerFilter, List<Checkpoint>> checkpoints;

  /// Whether every call fails, until a test says otherwise.
  bool failing;
  final queries = <PlannerQuery>[];

  @override
  Future<Result<List<Checkpoint>>> fetchCheckpoints(PlannerQuery query) async {
    queries.add(query);
    if (failing) {
      return const Failure(ApiFailure(message: 'offline'));
    }
    return Success(checkpoints[query.filter] ?? const []);
  }
}

final _now = DateTime(2026, 11, 6, 12);

Future<void> _pump(
  WidgetTester tester,
  _FakePlannerRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        workspaceProvider.overrideWith(_FakeWorkspaceNotifier.new),
        plannerRepositoryProvider.overrideWithValue(repository),
        plannerClockProvider.overrideWithValue(() => _now),
      ],
      child: buildTestMaterialApp(const Scaffold(body: PlannerView())),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('splits the filter into overdue and upcoming sections', (
    tester,
  ) async {
    final repository = _FakePlannerRepository(
      checkpoints: {
        PlannerFilter.todo: [
          Checkpoint(
            id: 'c-1',
            title: 'Fractions worksheet',
            dueAt: _now.subtract(const Duration(days: 2)),
          ),
          Checkpoint(
            id: 'c-2',
            title: 'Essay draft',
            dueAt: _now.add(const Duration(days: 3)),
          ),
          Checkpoint(
            id: 'c-3',
            title: 'Reading log',
            dueAt: _now.add(const Duration(days: 5)),
          ),
        ],
      },
    );

    await _pump(tester, repository);

    expect(find.text('Overdue (1)'), findsOneWidget);
    expect(find.text('Upcoming (2)'), findsOneWidget);
    expect(find.text('Fractions worksheet'), findsOneWidget);
    expect(find.text('Essay draft'), findsOneWidget);
    expect(find.text('Overdue by 2 days'), findsOneWidget);
  });

  testWidgets('switching filter asks the repository for that status', (
    tester,
  ) async {
    final repository = _FakePlannerRepository(
      checkpoints: {
        PlannerFilter.todo: [
          Checkpoint(id: 'c-1', title: 'Fractions worksheet', dueAt: _now),
        ],
        PlannerFilter.submitted: [
          Checkpoint(
            id: 'c-2',
            title: 'Book review',
            status: CheckpointStatus.submitted,
          ),
        ],
      },
    );

    await _pump(tester, repository);
    expect(find.text('Fractions worksheet'), findsOneWidget);

    await tester.tap(find.text('Submitted'));
    await tester.pumpAndSettle();

    expect(find.text('Book review'), findsOneWidget);
    expect(find.text('Fractions worksheet'), findsNothing);
    expect(repository.queries.last.filter, PlannerFilter.submitted);
  });

  testWidgets('shows the empty state for a filter with no work', (
    tester,
  ) async {
    await _pump(tester, _FakePlannerRepository());

    expect(find.text('Nothing to do'), findsOneWidget);
    expect(find.text('Overdue (1)'), findsNothing);
  });

  testWidgets('shows the error state and recovers when retried', (
    tester,
  ) async {
    final repository = _FakePlannerRepository(
      checkpoints: {
        PlannerFilter.todo: [Checkpoint(id: 'c-1', title: 'Fractions')],
      },
      failing: true,
    );

    await _pump(tester, repository);
    expect(find.text('Could not load checkpoints'), findsOneWidget);

    repository.failing = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Could not load checkpoints'), findsNothing);
    expect(find.text('Fractions'), findsOneWidget);
  });
}
