import 'package:zedu/core/core.dart';

class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentThemeMode = ref.watch(themeModeProvider);
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 24),
        Divider(height: 1, color: colors.divider),
        const SizedBox(height: 28),
        Text(
          'Appearance',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Choose how Zedu looks to you. Select a single color mode, or sync with your computer\'s appearance.',
          style: TextStyle(fontSize: 14, color: colors.textSecondary),
        ),
        const SizedBox(height: 24),
        Text(
          'Color mode',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Changing this only affects this device, just like Slack.',
          style: TextStyle(fontSize: 13, color: colors.textHint),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _ModeOptionCard(
                title: 'Light',
                description: 'A bright look for daytime use.',
                isSelected: currentThemeMode == ThemeMode.light,
                onTap: () => ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(ThemeMode.light),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ModeOptionCard(
                title: 'Dark',
                description: 'A darker look that\'s easier on the eyes.',
                isSelected: currentThemeMode == ThemeMode.dark,
                onTap: () => ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(ThemeMode.dark),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ModeOptionCard(
                title: 'Auto',
                description: 'Match your computer\'s appearance.',
                isSelected: currentThemeMode == ThemeMode.system,
                onTap: () => ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(ThemeMode.system),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            _ThemePreviewCard(
              title: 'Light',
              isSelected: currentThemeMode == ThemeMode.light,
              isPreviewDark: false,
              onTap: () => ref
                  .read(themeModeProvider.notifier)
                  .setThemeMode(ThemeMode.light),
            ),
            const SizedBox(width: 20),
            _ThemePreviewCard(
              title: 'Dark',
              isSelected: currentThemeMode == ThemeMode.dark,
              isPreviewDark: true,
              onTap: () => ref
                  .read(themeModeProvider.notifier)
                  .setThemeMode(ThemeMode.dark),
            ),
          ],
        ),
      ],
    );
  }
}

class _ModeOptionCard extends StatelessWidget {
  const _ModeOptionCard({
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final cardBg = colors.background;
    final cardBorder = isSelected ? colors.primary : colors.divider;
    final titleColor = colors.textPrimary;
    final descColor = colors.textHint;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 84,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cardBorder, width: isSelected ? 1.5 : 1),
          color: cardBg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                _RadioIndicator(isSelected: isSelected),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(
                description,
                style: TextStyle(fontSize: 12, color: descColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadioIndicator extends StatelessWidget {
  const _RadioIndicator({required this.isSelected});
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? colors.primary : colors.textHint,
          width: 1.5,
        ),
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.primary,
                ),
              ),
            )
          : null,
    );
  }
}

class _ThemePreviewCard extends StatelessWidget {
  const _ThemePreviewCard({
    required this.title,
    required this.isSelected,
    required this.isPreviewDark,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final bool isPreviewDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final previewBorder = isSelected ? colors.primary : colors.divider;
    final labelColor = colors.textPrimary;
    final previewPalette = isPreviewDark ? AppPalette.dark : AppPalette.light;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 250,
            height: 130,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: previewBorder,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Row(
                children: [
                  // Mock Sidebar
                  Container(
                    width: 75,
                    color: previewPalette.sidebar,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 14,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 5,
                          width: 45,
                          decoration: BoxDecoration(
                            color: previewPalette.onPrimary.withValues(
                              alpha: 0.35,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 5,
                          width: 35,
                          decoration: BoxDecoration(
                            color: previewPalette.onPrimary.withValues(
                              alpha: 0.25,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 5,
                          width: 50,
                          decoration: BoxDecoration(
                            color: previewPalette.onPrimary.withValues(
                              alpha: 0.25,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Mock Main Chat/Content Area
                  Expanded(
                    child: Container(
                      color: previewPalette.background,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: previewPalette.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: previewPalette.divider,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: previewPalette.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: previewPalette.divider,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }
}
