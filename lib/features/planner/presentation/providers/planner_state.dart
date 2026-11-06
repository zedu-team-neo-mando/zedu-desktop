import 'package:zedu/features/features.dart';

/// What the planner is showing: which of the three filters, and the cohort or
/// channel it is narrowed to, if any.
class PlannerState {
  final PlannerFilter filter;
  final String? cohortId;

  const PlannerState({this.filter = PlannerFilter.todo, this.cohortId});

  PlannerQuery get query => PlannerQuery(filter: filter, cohortId: cohortId);

  PlannerState copyWith({
    PlannerFilter? filter,
    String? Function()? cohortId,
  }) => PlannerState(
    filter: filter ?? this.filter,
    cohortId: cohortId != null ? cohortId() : this.cohortId,
  );
}
