import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

abstract class PlannerRepository {
  /// Checkpoints in the workspace that match [query]. An empty list is a
  /// valid answer: the learner or educator has none for that filter yet.
  Future<Result<List<Checkpoint>>> fetchCheckpoints(PlannerQuery query);
}
