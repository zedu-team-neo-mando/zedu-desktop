import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

abstract class PlannerRemoteDataSource {
  Future<List<Checkpoint>> fetchCheckpoints(PlannerQuery query);
}

/// Reads the workspace's checkpoints.
/// The server is expected to pick the organisation from the signed-in session
/// and to decide what a learner may see. The path below is NOT confirmed: no
/// route serves it in the API today (see the PR's Backend section), so every
/// call currently lands on a 404 and the view shows its error state.
class PlannerRemoteDataSourceImpl implements PlannerRemoteDataSource {
  PlannerRemoteDataSourceImpl({required this.apiBaseService});

  final ApiBaseService apiBaseService;

  /// Kept in one place so the path is easy to correct once the real endpoint
  /// is agreed with the backend.
  static const checkpointsPath = '/planner/checkpoints';

  @override
  Future<List<Checkpoint>> fetchCheckpoints(PlannerQuery query) async {
    final response = await apiBaseService.get<Map<String, dynamic>>(
      path: checkpointsPath,
      queryParameters: query.toQueryParameters(),
    );
    final data = response.data['data'];
    final body = data is Map ? data : const <String, dynamic>{};
    final raw = body['checkpoints'] ?? body['assignments'];
    return (raw is List ? raw : const <dynamic>[])
        .whereType<Map<dynamic, dynamic>>()
        .map((e) => Checkpoint.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
