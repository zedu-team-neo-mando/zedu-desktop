import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// Main area of the Planner tab: the checkpoints of the selected filter, split
/// into what is overdue and what is still ahead.
class PlannerView extends ConsumerWidget {
  const PlannerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final checkpoints = ref.watch(checkpointListProvider);

    return Container(
      color: colors.onPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 60,
            padding: const EdgeInsets.only(left: 24, right: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.divider)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Cohort Planner',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  icon: Icon(Icons.refresh, color: colors.textSecondary),
                  onPressed: () => ref.invalidate(checkpointListProvider),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              children: [
                const PlannerFilterBar(),
                const SizedBox(height: 20),
                switch (checkpoints) {
                  AsyncLoading() => const _Loading(),
                  AsyncError() => _Message(
                    icon: Icons.error_outline,
                    title: 'Could not load checkpoints',
                    body: 'Check your connection and try again.',
                    onRetry: () => ref.invalidate(checkpointListProvider),
                  ),
                  _ => const _Sections(),
                },
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Sections extends ConsumerWidget {
  const _Sections();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final groups = ref.watch(checkpointGroupsProvider);
    final now = ref.watch(plannerClockProvider)();
    final filter = ref.watch(plannerProvider.select((s) => s.filter));

    if (groups.isEmpty) {
      return _Message(
        icon: Icons.checklist_rounded,
        title: 'Nothing ${filter.label.toLowerCase()}',
        body: 'Checkpoints for this filter appear here.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (groups.overdue.isNotEmpty) ...[
          _SectionHeading(
            label: 'Overdue',
            count: groups.overdue.length,
            color: colors.error,
          ),
          const SizedBox(height: 12),
          for (final checkpoint in groups.overdue)
            CheckpointCard(checkpoint: checkpoint, now: now),
          const SizedBox(height: 12),
        ],
        if (groups.upcoming.isNotEmpty) ...[
          _SectionHeading(
            label: 'Upcoming',
            count: groups.upcoming.length,
            color: colors.textPrimary,
          ),
          const SizedBox(height: 12),
          for (final checkpoint in groups.upcoming)
            CheckpointCard(checkpoint: checkpoint, now: now),
        ],
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: '$label, $count ${count == 1 ? 'checkpoint' : 'checkpoints'}',
      child: Text(
        '$label ($count)',
        style: context.textTheme.titleMedium?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48),
    child: Center(
      child: CircularProgressIndicator(color: context.colors.primary),
    ),
  );
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(icon, size: 40, color: colors.textHint),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.textTheme.titleMedium?.copyWith(
              fontSize: 15,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              color: colors.textHint,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ],
      ),
    );
  }
}
