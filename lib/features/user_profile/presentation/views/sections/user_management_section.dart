import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

enum _UserManagementTab { members, invites }

class UserManagementSection extends StatefulWidget {
  const UserManagementSection({
    super.key,
    required this.members,
    required this.isSaving,
    required this.onInvite,
    required this.onUpdate,
    required this.onRemove,
    this.invitesCount = 0,
  });

  final List<TeamMember> members;
  final bool isSaving;
  final Future<void> Function({required String email, required String role})
  onInvite;
  final ValueChanged<TeamMember> onUpdate;
  final ValueChanged<String> onRemove;

  /// Number of outstanding invitations shown on the `Invites` tab badge.
  final int invitesCount;

  @override
  State<UserManagementSection> createState() => _UserManagementSectionState();
}

class _UserManagementSectionState extends State<UserManagementSection> {
  final _searchController = TextEditingController();
  String _roleFilter = 'All Roles';
  int _currentPage = 1;
  _UserManagementTab _tab = _UserManagementTab.members;
  static const int _pageSize = 10;

  void _selectTab(_UserManagementTab tab) {
    if (_tab == tab) return;
    setState(() {
      _tab = tab;
      _currentPage = 1;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final hasActiveFilter = query.isNotEmpty || _roleFilter != 'All Roles';
    final filtered = widget.members.where((member) {
      final matchesQuery =
          query.isEmpty ||
          member.email.toLowerCase().contains(query) ||
          (member.name?.toLowerCase().contains(query) ?? false);
      final matchesRole =
          _roleFilter == 'All Roles' || member.role == _roleFilter;
      return matchesQuery && matchesRole;
    }).toList();

    final totalPages = (filtered.length / _pageSize).ceil();
    final currentPage = totalPages == 0 ? 1 : _currentPage.clamp(1, totalPages);
    final startIndex = (currentPage - 1) * _pageSize;
    final paginatedMembers = filtered.skip(startIndex).take(_pageSize).toList();

    // One layout shared by both tabs so they are exactly equal and compact.
    final tabLayout = _TabMetrics.resolve(context, const [
      'Members',
      'Invites',
    ]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileSectionHeader(
          title: 'Your Team',
          subtitle: 'Manage all members of your team.',
          trailing: AppButton(
            label: 'Invite People',
            expand: false,
            height: 44,
            loading: widget.isSaving,
            onPressed: () => _showInviteDialog(context, widget.onInvite),
          ),
        ),
        const SizedBox(height: 34),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _TabLabel(
              label: 'Members',
              width: tabLayout.width,
              headerHeight: tabLayout.headerHeight,
              count: widget.members.length,
              active: _tab == _UserManagementTab.members,
              onTap: () => _selectTab(_UserManagementTab.members),
            ),
            const SizedBox(width: _TabMetrics.tabSpacing),
            _TabLabel(
              label: 'Invites',
              width: tabLayout.width,
              headerHeight: tabLayout.headerHeight,
              count: widget.invitesCount,
              active: _tab == _UserManagementTab.invites,
              onTap: () => _selectTab(_UserManagementTab.invites),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ProfileCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    SizedBox(
                      width: 300,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {
                          _currentPage = 1;
                        }),
                        decoration: InputDecoration(
                          hintText: 'Search by name or email',
                          prefixIcon: const Icon(Icons.search, size: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: _roleFilter,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(
                          value: 'All Roles',
                          child: Text('All Roles'),
                        ),
                        DropdownMenuItem(
                          value: 'Administrator',
                          child: Text('Administrator'),
                        ),
                        DropdownMenuItem(
                          value: 'Manager',
                          child: Text('Manager'),
                        ),
                        DropdownMenuItem(value: 'User', child: Text('User')),
                      ],
                      onChanged: (value) => setState(() {
                        _roleFilter = value ?? 'All Roles';
                        _currentPage = 1;
                      }),
                    ),
                  ],
                ),
              ),
              if (_tab == _UserManagementTab.invites)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 48,
                    horizontal: 24,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: context.colors.divider,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.mail_outline_rounded,
                            size: 28,
                            color: context.colors.textHint,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.invitesCount == 0
                              ? 'No pending invites.'
                              : '${widget.invitesCount} pending invite'
                                    '${widget.invitesCount == 1 ? '' : 's'}.',
                          style: context.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: context.colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 48,
                    horizontal: 24,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: context.colors.divider,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            hasActiveFilter
                                ? Icons.search_off_rounded
                                : Icons.people_outline_rounded,
                            size: 28,
                            color: context.colors.textHint,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          hasActiveFilter
                              ? 'No members match your search.'
                              : 'No members found.',
                          style: context.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: context.colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          hasActiveFilter
                              ? 'Try adjusting your search terms or role filters.'
                              : 'Invite people to your team to start collaborating.',
                          textAlign: TextAlign.center,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colors.textSecondary.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 880),
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        const Color(0xFFFAFAFA),
                      ),
                      columns: const [
                        DataColumn(label: Text('Email Address')),
                        DataColumn(label: Text('Role')),
                        DataColumn(label: Text('Date Joined')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: paginatedMembers.map((member) {
                        return DataRow(
                          cells: [
                            DataCell(_MemberIdentity(email: member.email)),
                            DataCell(Text(member.role)),
                            DataCell(Text(member.dateJoined)),
                            DataCell(
                              ProfileStatusPill(status: member.status.name),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SquareIconButton(
                                    icon: Icons.edit_outlined,
                                    size: 28,
                                    onTap: () => _showMemberDialog(
                                      context,
                                      member,
                                      widget.onUpdate,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SquareIconButton(
                                    icon: Icons.delete_outline,
                                    size: 28,
                                    onTap: () => _confirmRemove(
                                      context,
                                      member.email,
                                      () async => widget.onRemove(member.id),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              if (_tab == _UserManagementTab.members && totalPages > 1) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      AppButton.outlined(
                        label: 'Previous',
                        expand: false,
                        height: 36,
                        disabled: currentPage <= 1,
                        onPressed: currentPage > 1
                            ? () =>
                                  setState(() => _currentPage = currentPage - 1)
                            : null,
                      ),
                      const Spacer(),
                      Text(
                        '$currentPage',
                        key: const Key('user_management_page_number'),
                        style: context.textTheme.bodySmall,
                      ),
                      const Spacer(),
                      AppButton.outlined(
                        label: 'Next',
                        expand: false,
                        height: 36,
                        disabled: currentPage >= totalPages,
                        onPressed: currentPage < totalPages
                            ? () =>
                                  setState(() => _currentPage = currentPage + 1)
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showInviteDialog(
    BuildContext context,
    Future<void> Function({required String email, required String role})
    onInvite,
  ) => showInviteMemberDialog(context, onInvite);

  void _showMemberDialog(
    BuildContext context,
    TeamMember member,
    ValueChanged<TeamMember> onUpdate,
  ) => showEditMemberDialog(context, member, onUpdate);

  Future<void> _confirmRemove(
    BuildContext context,
    String email,
    Future<void> Function() onConfirm,
  ) => showProfileConfirmDialog(
    context,
    title: 'Remove team member?',
    message: '$email will lose access to this organization.',
    confirmLabel: 'Remove member',
    onConfirm: onConfirm,
    destructive: true,
  );
}

/// Fixed geometry shared by every tab so the labels, badges and active
/// indicator line up regardless of the label/badge text width.
class _TabMetrics {
  const _TabMetrics._();

  /// Gap between the label and its count badge.
  static const double labelToBadge = 8;

  /// Gap below the label row before the active underline.
  static const double labelToUnderline = 6;

  /// Total height reserved for the underline area so switching tabs and
  /// changing counts never shifts the table below the tab strip.
  static const double underlineHeight = 3;

  /// Badge text style. Shared with [_TabMetrics.resolve] so the reserved badge
  /// width always matches what actually renders.
  static const double badgeFontSize = 10;
  static const double badgeLineHeight = 1.3;

  /// Symmetric padding around the badge count. It is intentionally small so a
  /// single digit reads as a compact pill instead of a wide, padded block.
  static const double badgeHorizontalPadding = 5;
  static const double badgeVerticalPadding = 2;

  /// Widest count the badge must accommodate without clipping or resizing the
  /// tab. The shared width reserves room for this, so 0–999 are all safe.
  static const String badgeMaxCount = '999';

  /// Gap between the two tabs.
  static const double tabSpacing = 12;

  /// Padding applied symmetrically to each tab. Only the horizontal component
  /// contributes to the shared width; the vertical component contributes to
  /// the shared header height. Extra top padding balances the underline gap.
  static const EdgeInsets tabPadding = EdgeInsets.fromLTRB(4, 8, 4, 2);

  /// Resolves the geometry shared by both tabs.
  ///
  /// [width] is the wider of [labels] measured with the selected (semibold)
  /// style, plus the label→badge gap, the widest badge and the tab padding.
  /// [headerHeight] is the taller of the label and badge boxes plus the tab's
  /// vertical padding, so both tabs get an identical content area and their
  /// label + badge can be vertically centred in it.
  static _TabLayout resolve(BuildContext context, List<String> labels) {
    final labelStyle = context.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
    );
    final badgeStyle = context.textTheme.labelSmall?.copyWith(
      fontSize: badgeFontSize,
      height: badgeLineHeight,
    );
    final textDirection = Directionality.of(context);
    final textScaler = MediaQuery.textScalerOf(context);

    TextPainter measure(String text, TextStyle? style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: textDirection,
        textScaler: textScaler,
        maxLines: 1,
      )..layout();
      return painter;
    }

    var widestLabel = 0.0;
    var labelHeight = 0.0;
    for (final label in labels) {
      final painter = measure(label, labelStyle);
      if (painter.width > widestLabel) widestLabel = painter.width;
      if (painter.height > labelHeight) labelHeight = painter.height;
      painter.dispose();
    }

    final badge = measure(badgeMaxCount, badgeStyle);
    final badgeWidth = badge.width + badgeHorizontalPadding * 2;
    final badgeHeight = badge.height + badgeVerticalPadding * 2;
    badge.dispose();

    final contentHeight = labelHeight > badgeHeight ? labelHeight : badgeHeight;

    return _TabLayout(
      width: (widestLabel + labelToBadge + badgeWidth + tabPadding.horizontal)
          .ceilToDouble(),
      headerHeight: contentHeight + tabPadding.vertical,
    );
  }
}

/// Geometry resolved once per build and applied to both tabs.
class _TabLayout {
  const _TabLayout({required this.width, required this.headerHeight});

  /// Shared outer width of each tab.
  final double width;

  /// Shared height of the label + badge content area (tab padding included).
  final double headerHeight;
}

class _TabLabel extends StatelessWidget {
  const _TabLabel({
    required this.label,
    required this.width,
    required this.headerHeight,
    required this.count,
    required this.active,
    this.onTap,
  });

  final String label;
  final double width;
  final double headerHeight;
  final int count;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final labelColor = active
        ? context.colors.sidebar
        : const Color(0xFF6B7280);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      // Both tabs receive the same width and header height, so they stay
      // identical regardless of label length, count or active state. The
      // underline stays anchored to the bottom and spans the full width.
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: headerHeight,
              // Centering the whole label + badge row inside the shared header
              // keeps their vertical geometry identical on both tabs.
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        key: Key('tab_label_$label'),
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontWeight: active
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: labelColor,
                        ),
                      ),
                      const SizedBox(width: _TabMetrics.labelToBadge),
                      // The badge hugs its count with symmetric padding, so a
                      // single digit stays compact. The shared tab width already
                      // reserves room for the widest count, so growing from 0 to
                      // 999 never clips the badge or resizes the tab. A
                      // DecoratedBox (rather than a Container with alignment) is
                      // used so the pill keeps its intrinsic height instead of
                      // stretching to fill the header.
                      DecoratedBox(
                        key: Key('tab_badge_$label'),
                        decoration: BoxDecoration(
                          color: active
                              ? context.colors.primaryBg
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: _TabMetrics.badgeHorizontalPadding,
                            vertical: _TabMetrics.badgeVerticalPadding,
                          ),
                          child: Text(
                            count.toString(),
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.fade,
                            textAlign: TextAlign.center,
                            style: context.textTheme.labelSmall?.copyWith(
                              color: labelColor,
                              fontSize: _TabMetrics.badgeFontSize,
                              height: _TabMetrics.badgeLineHeight,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: _TabMetrics.labelToUnderline),
            // Always reserve the underline height so switching tabs or
            // changing counts never shifts the strip. Only the active tab
            // paints the indicator, using the design system's primary colour.
            Container(
              key: Key('tab_underline_$label'),
              height: _TabMetrics.underlineHeight,
              decoration: BoxDecoration(
                color: active ? context.colors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(
                  _TabMetrics.underlineHeight / 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberIdentity extends StatelessWidget {
  const _MemberIdentity({required this.email});
  final String email;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Color(0xFFE9FBFA),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.person, size: 18, color: Color(0xFF17C9BD)),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            email,
            style: context.textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
