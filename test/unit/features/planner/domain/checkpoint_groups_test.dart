import 'package:zedu/features/features.dart';

import '../../../../helpers/helpers.dart';

Checkpoint _checkpoint(
  String id, {
  CheckpointStatus status = CheckpointStatus.todo,
  DateTime? dueAt,
}) => Checkpoint(id: id, title: id, status: status, dueAt: dueAt);

void main() {
  final now = DateTime(2026, 11, 6, 12);

  test('keeps only the filter status', () {
    final groups = CheckpointGroups.from(
      [
        _checkpoint('todo', dueAt: now.add(const Duration(days: 1))),
        _checkpoint(
          'submitted',
          status: CheckpointStatus.submitted,
          dueAt: now.add(const Duration(days: 1)),
        ),
      ],
      filter: PlannerFilter.submitted,
      now: now,
    );

    expect(groups.upcoming.map((c) => c.id), ['submitted']);
    expect(groups.overdue, isEmpty);
  });

  test('splits late work from upcoming and orders each by due date', () {
    final groups = CheckpointGroups.from(
      [
        _checkpoint('later', dueAt: now.add(const Duration(days: 5))),
        _checkpoint('late-two', dueAt: now.subtract(const Duration(days: 2))),
        _checkpoint('soon', dueAt: now.add(const Duration(days: 1))),
        _checkpoint('late-one', dueAt: now.subtract(const Duration(days: 1))),
      ],
      filter: PlannerFilter.todo,
      now: now,
    );

    expect(groups.overdue.map((c) => c.id), ['late-two', 'late-one']);
    expect(groups.upcoming.map((c) => c.id), ['soon', 'later']);
  });

  test('puts checkpoints without a due date last among upcoming', () {
    final groups = CheckpointGroups.from(
      [
        const Checkpoint(id: 'undated', title: 'undated'),
        _checkpoint('dated', dueAt: now.add(const Duration(days: 2))),
      ],
      filter: PlannerFilter.todo,
      now: now,
    );

    expect(groups.upcoming.map((c) => c.id), ['dated', 'undated']);
  });

  test('reports empty when nothing matches the filter', () {
    final groups = CheckpointGroups.from(
      [_checkpoint('todo', dueAt: now)],
      filter: PlannerFilter.reviewed,
      now: now,
    );

    expect(groups.isEmpty, isTrue);
    expect(groups.overdue, isEmpty);
    expect(groups.upcoming, isEmpty);
  });
}
