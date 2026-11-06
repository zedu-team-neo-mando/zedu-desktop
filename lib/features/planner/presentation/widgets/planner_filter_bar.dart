import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// The three filters above the planner list. Chips are focusable and driven by
/// the keyboard like the rest of the app's buttons.
class PlannerFilterBar extends ConsumerWidget {
  const PlannerFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(plannerProvider.select((s) => s.filter));
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final filter in PlannerFilter.values)
          _FilterChip(
            filter: filter,
            isSelected: filter == selected,
            onTap: () => ref.read(plannerProvider.notifier).setFilter(filter),
          ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.filter,
    required this.isSelected,
    required this.onTap,
  });

  final PlannerFilter filter;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${filter.label} checkpoints',
      child: Material(
        color: isSelected ? colors.primaryBg : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected ? colors.primary : colors.borderOutline,
              ),
            ),
            child: Text(
              filter.label,
              style: context.textTheme.labelLarge?.copyWith(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? colors.primary : colors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
