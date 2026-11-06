import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// One checkpoint in the planner list.
class CheckpointCard extends StatelessWidget {
  const CheckpointCard({
    super.key,
    required this.checkpoint,
    required this.now,
  });

  final Checkpoint checkpoint;

  /// The moment the redraw is compared against, so a card that says "Overdue"
  /// and the section it sits under agree.
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isOverdue = checkpoint.isOverdue(now);
    final due = _dueLabel(checkpoint, now);

    return Semantics(
      container: true,
      label: [
        checkpoint.title,
        '${checkpoint.priority.label} priority',
        checkpoint.status.label,
        if (due.isNotEmpty) due,
        if (checkpoint.cohortName.isNotEmpty) checkpoint.cohortName,
      ].join(', '),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isOverdue ? colors.error : colors.borderOutline,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    checkpoint.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _Tag(
                  label: checkpoint.priority.label,
                  color: _priorityColor(checkpoint.priority, colors),
                  background: _priorityBackground(checkpoint.priority, colors),
                ),
                const SizedBox(width: 8),
                _Tag(
                  label: checkpoint.status.label,
                  color: colors.textSecondary,
                  background: colors.sidebar,
                ),
              ],
            ),
            if (checkpoint.instructions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                checkpoint.instructions,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  color: colors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (due.isNotEmpty)
                  Text(
                    due,
                    style: context.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      fontWeight: isOverdue ? FontWeight.w600 : FontWeight.w400,
                      color: isOverdue ? colors.error : colors.textHint,
                    ),
                  ),
                if (checkpoint.cohortName.isNotEmpty)
                  Text(
                    checkpoint.cohortName,
                    style: context.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: colors.textHint,
                    ),
                  ),
              ],
            ),
            if (checkpoint.mentorFeedback.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.successBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  checkpoint.mentorFeedback,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: context.textTheme.labelSmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

Color _priorityColor(CheckpointPriority priority, AppPalette colors) =>
    switch (priority) {
      CheckpointPriority.high => colors.error,
      CheckpointPriority.normal => colors.primary,
      CheckpointPriority.low => colors.textSecondary,
    };

Color _priorityBackground(CheckpointPriority priority, AppPalette colors) =>
    switch (priority) {
      CheckpointPriority.high => colors.errorBg,
      CheckpointPriority.normal => colors.primaryBg,
      CheckpointPriority.low => colors.sidebar,
    };

/// "Overdue by 2 days", "Due today", "Due 4 Nov 2026", or empty when the
/// checkpoint has no due date.
String _dueLabel(Checkpoint checkpoint, DateTime now) {
  final due = checkpoint.dueAt;
  if (due == null) return '';

  final today = DateTime(now.year, now.month, now.day);
  final dueDay = DateTime(due.year, due.month, due.day);
  final days = dueDay.difference(today).inDays;

  if (checkpoint.isOverdue(now)) {
    final late = today.difference(dueDay).inDays;
    if (late <= 0) return 'Overdue';
    return late == 1 ? 'Overdue by 1 day' : 'Overdue by $late days';
  }
  if (days == 0) return 'Due today';
  if (days == 1) return 'Due tomorrow';
  return 'Due ${_shortDate(due)}';
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _shortDate(DateTime date) =>
    '${date.day} ${_months[date.month - 1]} ${date.year}';
