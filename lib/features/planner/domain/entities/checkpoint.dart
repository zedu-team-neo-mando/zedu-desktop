/// A learning checkpoint an educator publishes to a cohort or channel.
class Checkpoint {
  final String id;
  final String title;

  /// What the learner has to do, as the educator wrote it.
  final String instructions;

  /// When the work is due. Null when the checkpoint has no deadline.
  final DateTime? dueAt;
  final CheckpointPriority priority;
  final CheckpointStatus status;

  /// The cohort or channel the checkpoint belongs to, for grouping in the
  /// planner. Empty when the server does not send it.
  final String cohortName;
  final String assigneeName;

  /// The mentor's reply once the work is reviewed. Empty until then.
  final String mentorFeedback;
  final DateTime? submittedAt;

  const Checkpoint({
    required this.id,
    required this.title,
    this.instructions = '',
    this.dueAt,
    this.priority = CheckpointPriority.normal,
    this.status = CheckpointStatus.todo,
    this.cohortName = '',
    this.assigneeName = '',
    this.mentorFeedback = '',
    this.submittedAt,
  });

  /// Whether the work is late: due in the past and not handed in yet.
  bool isOverdue(DateTime now) {
    if (status != CheckpointStatus.todo) return false;
    final due = dueAt;
    return due != null && due.isBefore(now);
  }

  /// Whether the work is due within [window] and not handed in yet.
  bool isDueSoon(DateTime now, {Duration window = const Duration(days: 1)}) {
    if (status != CheckpointStatus.todo) return false;
    final due = dueAt;
    if (due == null) return false;
    final left = due.difference(now);
    return !left.isNegative && left <= window;
  }

  factory Checkpoint.fromJson(Map<String, dynamic> json) {
    String text(List<String> keys) {
      for (final key in keys) {
        final value = json[key]?.toString().trim() ?? '';
        if (value.isNotEmpty) return value;
      }
      return '';
    }

    return Checkpoint(
      id: text(['id']),
      title: text(['title', 'name']).isEmpty
          ? 'Untitled checkpoint'
          : text(['title', 'name']),
      instructions: text(['instructions', 'description', 'body']),
      dueAt: _date(text(['due_at', 'due_date', 'deadline'])),
      priority: CheckpointPriority.fromApi(text(['priority'])),
      status: CheckpointStatus.fromApi(text(['status'])),
      cohortName: text(['cohort_name', 'cohort', 'channel_name', 'channel']),
      assigneeName: text(['assignee_name', 'assignee', 'learner_name']),
      mentorFeedback: text(['mentor_feedback', 'feedback']),
      submittedAt: _date(text(['submitted_at'])),
    );
  }
}

/// How urgently a checkpoint needs attention.
enum CheckpointPriority {
  low('Low', 'low'),
  normal('Normal', 'normal'),
  high('High', 'high');

  const CheckpointPriority(this.label, this.apiValue);

  final String label;

  /// Value of the `priority` field.
  final String apiValue;

  /// Unknown or missing values fall back to [normal] rather than throwing.
  static CheckpointPriority fromApi(String value) {
    final normalized = value.trim().toLowerCase();
    for (final priority in values) {
      if (priority.apiValue == normalized) return priority;
    }
    return normal;
  }
}

/// Where a checkpoint sits in the learner's workflow.
enum CheckpointStatus {
  todo('To do', 'todo'),
  submitted('Submitted', 'submitted'),
  reviewed('Reviewed', 'reviewed');

  const CheckpointStatus(this.label, this.apiValue);

  final String label;

  /// Value of the `status` field.
  final String apiValue;

  /// Unknown or missing values fall back to [todo].
  static CheckpointStatus fromApi(String value) {
    final normalized = value.trim().toLowerCase();
    for (final status in values) {
      if (status.apiValue == normalized) return status;
    }
    return todo;
  }
}

/// Parses the several date shapes the API sends, as local time.
DateTime? _date(String value) {
  if (value.isEmpty) return null;
  return DateTime.tryParse(value)?.toLocal();
}
