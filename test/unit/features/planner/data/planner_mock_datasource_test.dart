import 'package:zedu/features/features.dart';

import '../../../../helpers/helpers.dart';

final _now = DateTime(2026, 11, 6, 12);

void main() {
  late PlannerMockDataSource datasource;

  setUp(() {
    datasource = PlannerMockDataSource(now: () => _now);
  });

  test('answers each filter with only that status', () async {
    for (final filter in PlannerFilter.values) {
      final checkpoints = await datasource.fetchCheckpoints(
        PlannerQuery(filter: filter),
      );

      expect(checkpoints, isNotEmpty, reason: '${filter.label} is empty');
      expect(
        checkpoints.every((c) => c.status == filter.status),
        isTrue,
        reason: '${filter.label} returned another status',
      );
    }
  });

  test(
    'the to-do list fills both the overdue and the upcoming section',
    () async {
      final checkpoints = await datasource.fetchCheckpoints(
        const PlannerQuery(),
      );

      expect(checkpoints.where((c) => c.isOverdue(_now)), hasLength(1));
      expect(
        checkpoints.where((c) => c.isDueSoon(_now)),
        isNotEmpty,
        reason: 'no checkpoint is due within a day',
      );
      expect(
        checkpoints.where((c) => c.dueAt == null),
        isNotEmpty,
        reason: 'a checkpoint without a deadline is worth seeing',
      );
    },
  );

  test('every sample checkpoint has a distinct id', () async {
    final ids = <String>[];
    for (final filter in PlannerFilter.values) {
      final checkpoints = await datasource.fetchCheckpoints(
        PlannerQuery(filter: filter),
      );
      ids.addAll(checkpoints.map((c) => c.id));
    }

    expect(ids, isNotEmpty);
    expect(ids.toSet(), hasLength(ids.length));
  });

  test('the reviewed sample carries mentor feedback', () async {
    final reviewed = await datasource.fetchCheckpoints(
      const PlannerQuery(filter: PlannerFilter.reviewed),
    );

    expect(reviewed.single.mentorFeedback, isNotEmpty);
  });

  test('ids are namespaced so they cannot collide with server rows', () async {
    final todos = await datasource.fetchCheckpoints(const PlannerQuery());

    expect(todos.every((c) => c.id.startsWith('mock-')), isTrue);
  });
}
