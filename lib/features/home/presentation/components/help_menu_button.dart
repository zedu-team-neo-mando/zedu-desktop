import 'package:zedu/core/core.dart';

/// The Help menu in the home app bar. Its Export diagnostics action bundles
/// recent app logs with app and OS version info into a zip the user saves.
class HelpMenuButton extends StatelessWidget {
  const HelpMenuButton({super.key, this.onExport});

  /// Test hook; defaults to the real [DiagnosticsExporter.export] flow.
  final Future<String?> Function()? onExport;

  Future<void> _export(BuildContext context) async {
    try {
      final path = await (onExport ?? DiagnosticsExporter.export)();
      if (path == null) return; // User cancelled the save dialog.
      if (!context.mounted) return;
      AppToastService.show(
        context,
        type: AppToastType.success,
        message: 'Diagnostics saved to $path',
      );
    } catch (error) {
      if (!context.mounted) return;
      AppToastService.show(
        context,
        type: AppToastType.error,
        message: 'Could not export diagnostics: $error',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return PopupMenuButton<String>(
      key: const ValueKey('help-menu-button'),
      tooltip: 'Help',
      position: PopupMenuPosition.under,
      icon: Icon(Icons.help_outline, color: colors.onPrimary, size: 20),
      onSelected: (value) {
        if (value == 'export-diagnostics') _export(context);
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'export-diagnostics',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.download_outlined,
                size: 18,
                color: colors.textPrimary,
              ),
              const SizedBox(width: 12),
              const Flexible(
                child: Text('Export diagnostics', overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
