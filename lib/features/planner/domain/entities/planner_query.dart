import 'package:zedu/features/features.dart';

/// The three lists the planner shows, in the order the filters appear.
enum PlannerFilter {
  todo('To do', CheckpointStatus.todo),
  submitted('Submitted', CheckpointStatus.submitted),
  reviewed('Reviewed', CheckpointStatus.reviewed);

  const PlannerFilter(this.label, this.status);

  final String label;

  /// The checkpoint status this filter keeps.
  final CheckpointStatus status;
}

/// What to ask the server for when listing checkpoints.
class PlannerQuery {
  final PlannerFilter filter;

  /// A cohort or channel id to narrow the list to, or null for the whole
  /// workspace.
  final String? cohortId;

  const PlannerQuery({this.filter = PlannerFilter.todo, this.cohortId});

  Map<String, dynamic> toQueryParameters() => {
    'status': filter.status.apiValue,
    if (cohortId != null && cohortId!.isNotEmpty) 'cohort_id': cohortId,
  };

  @override
  bool operator ==(Object other) =>
      other is PlannerQuery &&
      other.filter == filter &&
      other.cohortId == cohortId;

  @override
  int get hashCode => Object.hash(filter, cohortId);
}
