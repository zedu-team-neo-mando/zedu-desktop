import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class PlannerRepositoryImpl implements PlannerRepository {
  final PlannerRemoteDataSource remoteDataSource;

  PlannerRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Result<List<Checkpoint>>> fetchCheckpoints(PlannerQuery query) async {
    try {
      return Success(await remoteDataSource.fetchCheckpoints(query));
    } on ApiFailure catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(ApiFailure(message: e.toString()));
    }
  }
}
