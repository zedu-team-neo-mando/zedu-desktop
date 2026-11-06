import 'package:zedu/features/features.dart';

import '../../../../helpers/helpers.dart';

void main() {
  final now = DateTime(2026, 11, 6, 12);

  group('isOverdue', () {
    test('is true for work due in the past and not handed in', () {
      final checkpoint = Checkpoint(
        id: 'c-1',
        title: 'Fractions',
        dueAt: now.subtract(const Duration(minutes: 1)),
      );

      expect(checkpoint.isOverdue(now), isTrue);
    });

    test('is false at exactly the due moment', () {
      final checkpoint = Checkpoint(id: 'c-1', title: 'Fractions', dueAt: now);

      expect(checkpoint.isOverdue(now), isFalse);
    });

    test('is false once the work is submitted or reviewed', () {
      for (final status in [
        CheckpointStatus.submitted,
        CheckpointStatus.reviewed,
      ]) {
        final checkpoint = Checkpoint(
          id: 'c-1',
          title: 'Fractions',
          dueAt: now.subtract(const Duration(days: 2)),
          status: status,
        );

        expect(checkpoint.isOverdue(now), isFalse, reason: status.name);
      }
    });

    test('is false when there is no due date', () {
      const checkpoint = Checkpoint(id: 'c-1', title: 'Fractions');

      expect(checkpoint.isOverdue(now), isFalse);
    });
  });

  group('isDueSoon', () {
    test('is true inside the window and false outside it', () {
      final soon = Checkpoint(
        id: 'c-1',
        title: 'Fractions',
        dueAt: now.add(const Duration(hours: 6)),
      );
      final later = Checkpoint(
        id: 'c-2',
        title: 'Decimals',
        dueAt: now.add(const Duration(days: 3)),
      );

      expect(soon.isDueSoon(now), isTrue);
      expect(later.isDueSoon(now), isFalse);
    });

    test('is false for work already late or already handed in', () {
      final late = Checkpoint(
        id: 'c-1',
        title: 'Fractions',
        dueAt: now.subtract(const Duration(hours: 1)),
      );
      final submitted = Checkpoint(
        id: 'c-2',
        title: 'Decimals',
        dueAt: now.add(const Duration(hours: 1)),
        status: CheckpointStatus.submitted,
      );

      expect(late.isDueSoon(now), isFalse);
      expect(submitted.isDueSoon(now), isFalse);
    });
  });

  group('fromJson', () {
    test('reads the fields the API sends', () {
      final checkpoint = Checkpoint.fromJson({
        'id': 'c-9',
        'title': 'Essay draft',
        'instructions': 'Write 300 words',
        'due_at': '2026-11-08T09:00:00Z',
        'priority': 'high',
        'status': 'submitted',
        'cohort_name': 'Cohort A',
        'assignee_name': 'Ada Lovelace',
        'mentor_feedback': 'Good start',
        'submitted_at': '2026-11-05T18:30:00Z',
      });

      expect(checkpoint.id, 'c-9');
      expect(checkpoint.title, 'Essay draft');
      expect(checkpoint.instructions, 'Write 300 words');
      expect(checkpoint.dueAt, DateTime.utc(2026, 11, 8, 9).toLocal());
      expect(checkpoint.priority, CheckpointPriority.high);
      expect(checkpoint.status, CheckpointStatus.submitted);
      expect(checkpoint.cohortName, 'Cohort A');
      expect(checkpoint.assigneeName, 'Ada Lovelace');
      expect(checkpoint.mentorFeedback, 'Good start');
      expect(
        checkpoint.submittedAt,
        DateTime.utc(2026, 11, 5, 18, 30).toLocal(),
      );
    });

    test('falls back for missing and unknown values', () {
      final checkpoint = Checkpoint.fromJson({'priority': 'urgent'});

      expect(checkpoint.title, 'Untitled checkpoint');
      expect(checkpoint.priority, CheckpointPriority.normal);
      expect(checkpoint.status, CheckpointStatus.todo);
      expect(checkpoint.dueAt, isNull);
      expect(checkpoint.instructions, isEmpty);
    });

    test('accepts the alternative keys the web app uses', () {
      final checkpoint = Checkpoint.fromJson({
        'title': 'Quiz',
        'description': 'Five questions',
        'due_date': '2026-11-09T00:00:00.000',
        'channel': 'general',
      });

      expect(checkpoint.instructions, 'Five questions');
      expect(checkpoint.cohortName, 'general');
      expect(checkpoint.dueAt, isNotNull);
    });
  });
}
