import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

abstract class PlannerRemoteDataSource {
  Future<List<Checkpoint>> fetchCheckpoints(PlannerQuery query);
}

/// Reads the workspace's checkpoints from the same API the web planner uses.
/// The server picks the organisation from the signed-in session, and decides
/// what a learner may see.
class PlannerRemoteDataSourceImpl implements PlannerRemoteDataSource {
  PlannerRemoteDataSourceImpl({required this.apiBaseService});

  final ApiBaseService apiBaseService;

  /// Kept in one place so the path is easy to correct when the web app's
  /// planner endpoint settles.
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
