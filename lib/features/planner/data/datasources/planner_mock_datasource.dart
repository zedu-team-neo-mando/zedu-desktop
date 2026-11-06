import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// Sample checkpoints for runs with `USE_MOCK_DATA`, so the planner can be
/// opened and looked at while `GET /planner/checkpoints` does not exist yet.
///
/// It answers the same [PlannerQuery] as [PlannerRemoteDataSourceImpl], so the
/// filters, the Overdue/Upcoming split and the cards behave exactly as they
/// will once the real list arrives. The dates are relative to the clock it is
/// given, which keeps both sections populated whenever it is run.
///
/// Nothing here is real learner data, and it is only reachable when
/// [AppConfig.usesMockData] is true.
class PlannerMockDataSource implements PlannerRemoteDataSource {
  PlannerMockDataSource({required this.now});

  /// Supplies "now" so the sample due dates stay current.
  final DateTime Function() now;

  @override
  Future<List<Checkpoint>> fetchCheckpoints(PlannerQuery query) async {
    return _seed(
      now(),
    ).where((checkpoint) => checkpoint.status == query.filter.status).toList();
  }

  List<Checkpoint> _seed(DateTime reference) {
    final today = DateTime(reference.year, reference.month, reference.day);
    return [
      Checkpoint(
        id: 'mock-todo-1',
        title: 'Submit the week 3 case study',
        instructions: 'One-page write-up with the data you collected in class.',
        dueAt: today.subtract(const Duration(days: 2)),
        priority: CheckpointPriority.high,
        status: CheckpointStatus.todo,
        cohortName: 'Cohort 7 · Product Design',
        assigneeName: 'Ada',
      ),
      Checkpoint(
        id: 'mock-todo-2',
        title: 'Peer review two cohort pitches',
        instructions: 'Leave one strength and one question on each pitch.',
        dueAt: today.add(const Duration(hours: 18)),
        status: CheckpointStatus.todo,
        cohortName: 'Cohort 7 · Product Design',
        assigneeName: 'Ada',
      ),
      Checkpoint(
        id: 'mock-todo-3',
        title: 'Reflect on the research interview',
        dueAt: today.add(const Duration(days: 4)),
        priority: CheckpointPriority.normal,
        status: CheckpointStatus.todo,
        cohortName: 'Cohort 4 · Frontend',
        assigneeName: 'Tunde',
      ),
      Checkpoint(
        id: 'mock-todo-4',
        title: 'Read the accessibility checklist',
        dueAt: today.add(const Duration(days: 9)),
        priority: CheckpointPriority.low,
        status: CheckpointStatus.todo,
        cohortName: 'Cohort 4 · Frontend',
        assigneeName: 'Tunde',
      ),
      Checkpoint(
        id: 'mock-todo-5',
        title: 'Set up your project repository',
        // No deadline: the card should say so rather than invent one.
        status: CheckpointStatus.todo,
        cohortName: 'Cohort 9 · Data',
        assigneeName: 'Ife',
      ),
      Checkpoint(
        id: 'mock-submitted-1',
        title: 'Design critique of the checkout flow',
        status: CheckpointStatus.submitted,
        submittedAt: today.subtract(const Duration(days: 1)),
        dueAt: today.add(const Duration(days: 1)),
        cohortName: 'Cohort 7 · Product Design',
        assigneeName: 'Ada',
      ),
      Checkpoint(
        id: 'mock-submitted-2',
        title: 'Database schema for the booking app',
        status: CheckpointStatus.submitted,
        submittedAt: today.subtract(const Duration(days: 3)),
        cohortName: 'Cohort 9 · Data',
        assigneeName: 'Ife',
      ),
      Checkpoint(
        id: 'mock-reviewed-1',
        title: 'Ship the onboarding screen',
        status: CheckpointStatus.reviewed,
        submittedAt: today.subtract(const Duration(days: 6)),
        mentorFeedback:
            'Clear hierarchy and good empty state. Tighten the copy on step two '
            'and resubmit if you want another pass.',
        cohortName: 'Cohort 4 · Frontend',
        assigneeName: 'Tunde',
      ),
    ];
  }
}
