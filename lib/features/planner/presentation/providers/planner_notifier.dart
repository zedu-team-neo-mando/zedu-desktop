import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// Which filter the planner is on. Switching filters relists the checkpoints.
class PlannerNotifier extends Notifier<PlannerState> {
  @override
  PlannerState build() {
    // Checkpoints belong to one workspace, so start over when it changes.
    ref.watch(currentOrgIdProvider);
    return const PlannerState();
  }

  void setFilter(PlannerFilter filter) {
    if (filter == state.filter) return;
    state = state.copyWith(filter: filter);
  }

  void setCohort(String? cohortId) {
    if (cohortId == state.cohortId) return;
    state = state.copyWith(cohortId: () => cohortId);
  }
}

/// The checkpoints for the current filter, as the server returns them.
class CheckpointListNotifier extends AsyncNotifier<List<Checkpoint>> {
  @override
  Future<List<Checkpoint>> build() async {
    final query = ref.watch(plannerProvider.select((s) => s.query));
    final result = await ref
        .read(plannerRepositoryProvider)
        .fetchCheckpoints(query);
    return switch (result) {
      Success<List<Checkpoint>>(:final value) => value,
      Failure<List<Checkpoint>>(:final error) => throw error,
    };
  }
}
