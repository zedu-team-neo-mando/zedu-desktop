import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:zedu/core/utils/logger.dart';

/// Bundles recent app logs with app and OS version info into one zip file
/// the user can save from the Help menu.
abstract final class DiagnosticsExporter {
  DiagnosticsExporter._();

  /// Builds the diagnostics zip bytes in memory. [packageInfoLoader] is
  /// injectable so tests can pin the version values.
  static Future<List<int>> buildZipBytes({
    Future<PackageInfo> Function()? packageInfoLoader,
  }) async {
    final info = await (packageInfoLoader ?? PackageInfo.fromPlatform)();
    final now = DateTime.now().toUtc();

    final systemInfo = StringBuffer()
      ..writeln('Zedu Desktop diagnostics')
      ..writeln('Exported: ${now.toIso8601String()}')
      ..writeln()
      ..writeln('App: ${info.appName}')
      ..writeln('Package: ${info.packageName}')
      ..writeln('Version: ${info.version}')
      ..writeln('Build number: ${info.buildNumber}')
      ..writeln()
      ..writeln('Platform: ${Platform.operatingSystem}')
      ..writeln('OS version: ${Platform.operatingSystemVersion}');

    final logDump = AppLogger.logDump();
    final archive = Archive()
      ..addFile(
        ArchiveFile(
          'system-info.txt',
          systemInfo.length,
          systemInfo.toString().codeUnits,
        ),
      )
      ..addFile(ArchiveFile('app.log', logDump.length, logDump.codeUnits));
    return ZipEncoder().encode(archive);
  }

  /// Shows the save dialog, writes the zip, and returns the saved path,
  /// or null when the user cancels.
  static Future<String?> export() async {
    final bytes = await buildZipBytes();
    final stamp = DateTime.now()
        .toUtc()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final path = await FilePicker.saveFile(
      dialogTitle: 'Export diagnostics',
      fileName: 'zedu-diagnostics-$stamp.zip',
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    if (path == null) return null;
    await File(path).writeAsBytes(bytes);
    return path;
  }
}
