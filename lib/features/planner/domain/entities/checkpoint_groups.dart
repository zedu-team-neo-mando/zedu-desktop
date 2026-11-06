import 'package:zedu/features/features.dart';

/// One filter's checkpoints, split into what is late and what is still ahead.
class CheckpointGroups {
  final List<Checkpoint> overdue;
  final List<Checkpoint> upcoming;

  const CheckpointGroups({this.overdue = const [], this.upcoming = const []});

  bool get isEmpty => overdue.isEmpty && upcoming.isEmpty;

  /// Keeps the checkpoints in [filter] and splits them by [now]: anything due
  /// before it is late, everything else is upcoming. Both lists are ordered by
  /// due date, with checkpoints that have no due date last.
  static CheckpointGroups from(
    List<Checkpoint> checkpoints, {
    required PlannerFilter filter,
    required DateTime now,
  }) {
    final overdue = <Checkpoint>[];
    final upcoming = <Checkpoint>[];
    for (final checkpoint in checkpoints) {
      if (checkpoint.status != filter.status) continue;
      (checkpoint.isOverdue(now) ? overdue : upcoming).add(checkpoint);
    }
    overdue.sort(_byDueDate);
    upcoming.sort(_byDueDate);
    return CheckpointGroups(overdue: overdue, upcoming: upcoming);
  }
}

/// Ascending due date, undated last, ties kept in their original order.
int _byDueDate(Checkpoint a, Checkpoint b) {
  final aDue = a.dueAt;
  final bDue = b.dueAt;
  if (aDue == null && bDue == null) return 0;
  if (aDue == null) return 1;
  if (bDue == null) return -1;
  return aDue.compareTo(bDue);
}
