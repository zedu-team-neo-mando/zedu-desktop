import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// The sample list when the app runs with `USE_MOCK_DATA`, otherwise the real
/// datasource. Until `GET /planner/checkpoints` exists, mock mode is the only
/// way to see the planner populated, so it is wired here rather than in the
/// view.
final plannerRemoteDataSourceProvider = Provider<PlannerRemoteDataSource>((
  ref,
) {
  if (locator<AppConfig>().usesMockData) {
    return PlannerMockDataSource(now: ref.watch(plannerClockProvider));
  }
  return PlannerRemoteDataSourceImpl(apiBaseService: locator<ApiBaseService>());
});

final plannerRepositoryProvider = Provider<PlannerRepository>(
  (ref) => PlannerRepositoryImpl(
    remoteDataSource: ref.watch(plannerRemoteDataSourceProvider),
  ),
);

final plannerProvider = NotifierProvider<PlannerNotifier, PlannerState>(
  PlannerNotifier.new,
);

final checkpointListProvider =
    AsyncNotifierProvider<CheckpointListNotifier, List<Checkpoint>>(
      CheckpointListNotifier.new,
    );

/// The clock the planner reads. Overridden in tests so overdue and upcoming
/// stay deterministic.
final plannerClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// The current filter's checkpoints, split into overdue and upcoming.
final checkpointGroupsProvider = Provider<CheckpointGroups>((ref) {
  final filter = ref.watch(plannerProvider.select((s) => s.filter));
  final checkpoints = ref.watch(checkpointListProvider).value;
  final now = ref.watch(plannerClockProvider)();
  if (checkpoints == null) return const CheckpointGroups();
  return CheckpointGroups.from(checkpoints, filter: filter, now: now);
});
