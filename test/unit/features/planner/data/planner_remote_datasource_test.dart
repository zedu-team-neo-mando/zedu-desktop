import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../helpers/helpers.dart';

class MockApiBaseService extends Mock implements ApiBaseService {}

void main() {
  late MockApiBaseService api;
  late PlannerRemoteDataSourceImpl datasource;

  setUp(() {
    api = MockApiBaseService();
    datasource = PlannerRemoteDataSourceImpl(apiBaseService: api);
  });

  test('asks for the filtered checkpoints and reads them', () async {
    when(
      () => api.get<Map<String, dynamic>>(
        path: '/planner/checkpoints',
        queryParameters: {'status': 'submitted', 'cohort_id': 'cohort-1'},
      ),
    ).thenAnswer(
      (_) async => const ApiResponseModel<Map<String, dynamic>>(
        statusCode: 200,
        data: {
          'data': {
            'checkpoints': [
              {
                'id': 'c-1',
                'title': 'Essay draft',
                'status': 'submitted',
                'priority': 'high',
                'due_at': '2026-11-08T09:00:00Z',
              },
            ],
          },
        },
      ),
    );

    final checkpoints = await datasource.fetchCheckpoints(
      const PlannerQuery(filter: PlannerFilter.submitted, cohortId: 'cohort-1'),
    );

    expect(checkpoints, hasLength(1));
    expect(checkpoints.single.title, 'Essay draft');
    expect(checkpoints.single.status, CheckpointStatus.submitted);
    expect(checkpoints.single.priority, CheckpointPriority.high);
    verify(
      () => api.get<Map<String, dynamic>>(
        path: '/planner/checkpoints',
        queryParameters: {'status': 'submitted', 'cohort_id': 'cohort-1'},
      ),
    ).called(1);
  });

  test(
    'leaves cohort out of the query when the whole workspace is shown',
    () async {
      when(
        () => api.get<Map<String, dynamic>>(
          path: '/planner/checkpoints',
          queryParameters: {'status': 'todo'},
        ),
      ).thenAnswer(
        (_) async => const ApiResponseModel<Map<String, dynamic>>(
          statusCode: 200,
          data: {},
        ),
      );

      final checkpoints = await datasource.fetchCheckpoints(
        const PlannerQuery(),
      );

      expect(checkpoints, isEmpty);
    },
  );

  test(
    'accepts the assignments key and skips entries that are not maps',
    () async {
      when(
        () => api.get<Map<String, dynamic>>(
          path: '/planner/checkpoints',
          queryParameters: {'status': 'todo'},
        ),
      ).thenAnswer(
        (_) async => const ApiResponseModel<Map<String, dynamic>>(
          statusCode: 200,
          data: {
            'data': {
              'assignments': [
                {'id': 'c-2', 'title': 'Quiz'},
                'not-a-map',
              ],
            },
          },
        ),
      );

      final checkpoints = await datasource.fetchCheckpoints(
        const PlannerQuery(),
      );

      expect(checkpoints.map((c) => c.id), ['c-2']);
    },
  );
}
