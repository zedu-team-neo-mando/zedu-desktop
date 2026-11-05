import 'dart:io';

import 'package:pdfrx/pdfrx.dart';
import 'package:zedu/core/core.dart';

/// Downloads [url] and saves it as [fileName]. Returns whether the file was
/// saved, so tests can replace the platform picker and network call.
typedef PdfDownloadCallback =
    Future<bool> Function(String url, String fileName);

/// Full-screen in-app viewer for a PDF attachment.
///
/// Mirrors [ImageAttachmentViewer]: the document opens over a dark backdrop
/// with page navigation, zoom controls and a download button instead of
/// launching the external browser.
class PdfAttachmentViewer extends StatefulWidget {
  const PdfAttachmentViewer({
    super.key,
    required this.fileUrl,
    required this.fileName,
    this.onDownload,
  });

  /// Network URL or bundled asset path of the PDF.
  final String fileUrl;

  /// Name used for the save dialog and the viewer title.
  final String fileName;

  final PdfDownloadCallback? onDownload;

  @override
  State<PdfAttachmentViewer> createState() => _PdfAttachmentViewerState();
}

class _PdfAttachmentViewerState extends State<PdfAttachmentViewer> {
  final PdfViewerController _controller = PdfViewerController();
  bool _saving = false;

  bool get _isNetwork => widget.fileUrl.startsWith('http');

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChange);
  }

  void _onControllerChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChange);
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final download = widget.onDownload ?? _download;
    final saved = await download(widget.fileUrl, widget.fileName);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            saved
                ? 'Saved ${widget.fileName}'
                : 'Could not save ${widget.fileName}',
          ),
        ),
      );
  }

  Future<bool> _download(String url, String fileName) async {
    try {
      final bytes = await _readBytes(url);
      if (bytes.isEmpty) return false;
      final path = await FilePicker.saveFile(
        dialogTitle: 'Save PDF',
        fileName: fileName,
      );
      if (path == null) return false;
      await File(path).writeAsBytes(bytes);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Uint8List> _readBytes(String url) async {
    if (_isNetwork) {
      final response = await Dio().get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data ?? const []);
    }
    final data = await rootBundle.load(url);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  PdfViewerParams _viewerParams(AppPalette colors) {
    return PdfViewerParams(
      backgroundColor: colors.textPrimary,
      margin: 8,
      loadingBannerBuilder: (context, bytesDownloaded, totalBytes) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: CircularProgressIndicator(color: colors.onPrimary),
        ),
      ),
      errorBannerBuilder: (context, error, stackTrace, documentRef) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: colors.onPrimary.withValues(alpha: 0.8),
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                'Could not open this PDF',
                style: TextStyle(
                  color: colors.onPrimary.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPdf(AppPalette colors) {
    if (_isNetwork) {
      return PdfViewer.uri(
        Uri.parse(widget.fileUrl),
        controller: _controller,
        params: _viewerParams(colors),
      );
    }
    return PdfViewer.asset(
      widget.fileUrl,
      controller: _controller,
      params: _viewerParams(colors),
    );
  }

  void _goToPage(int page) {
    final current = _controller.pageNumber ?? 1;
    final target = (current + page).clamp(1, _controller.pageCount);
    _controller.goToPage(pageNumber: target);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final iconColor = colors.onPrimary;
    final ready = _controller.isReady;
    final pageNumber = ready ? (_controller.pageNumber ?? 1) : 0;
    final pageCount = ready ? _controller.pageCount : 0;

    return Scaffold(
      backgroundColor: colors.textPrimary,
      appBar: AppBar(
        backgroundColor: colors.textPrimary,
        foregroundColor: iconColor,
        elevation: 0,
        title: Text(
          widget.fileName,
          style: TextStyle(color: iconColor, fontSize: 15),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            onPressed: _saving ? null : _save,
            icon: Icon(Icons.download_outlined, color: iconColor),
            tooltip: 'Download PDF',
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close, color: iconColor),
            tooltip: 'Close preview',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildPdf(colors)),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: colors.textPrimary,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: ready && pageNumber > 1
                      ? () => _goToPage(-1)
                      : null,
                  icon: Icon(Icons.chevron_left, color: iconColor),
                  tooltip: 'Previous page',
                ),
                Text(
                  ready ? '$pageNumber / $pageCount' : 'Loading...',
                  style: TextStyle(color: iconColor, fontSize: 13),
                ),
                IconButton(
                  onPressed: ready && pageNumber < pageCount
                      ? () => _goToPage(1)
                      : null,
                  icon: Icon(Icons.chevron_right, color: iconColor),
                  tooltip: 'Next page',
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: ready ? () => _controller.zoomDown() : null,
                  icon: Icon(Icons.zoom_out, color: iconColor),
                  tooltip: 'Zoom out',
                ),
                IconButton(
                  onPressed: ready ? () => _controller.zoomUp() : null,
                  icon: Icon(Icons.zoom_in, color: iconColor),
                  tooltip: 'Zoom in',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
