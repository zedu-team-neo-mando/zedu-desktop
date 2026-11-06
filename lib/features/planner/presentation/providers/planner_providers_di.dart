import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

final plannerRemoteDataSourceProvider = Provider<PlannerRemoteDataSource>(
  (ref) =>
      PlannerRemoteDataSourceImpl(apiBaseService: locator<ApiBaseService>()),
);

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
