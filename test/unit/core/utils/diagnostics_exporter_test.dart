import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:zedu/core/core.dart';

void main() {
  group('DiagnosticsExporter.buildZipBytes', () {
    test(
      'bundles app and OS version info plus recent logs into one zip',
      () async {
        AppLogger.i('Unique diagnostics log line 42');

        final bytes = await DiagnosticsExporter.buildZipBytes(
          packageInfoLoader: () async => PackageInfo(
            appName: 'Zedu Desktop',
            packageName: 'com.zedu.desktop',
            version: '1.2.3',
            buildNumber: '45',
            buildSignature: '',
            installerStore: null,
          ),
        );

        final archive = ZipDecoder().decodeBytes(Uint8List.fromList(bytes));
        final names = archive.map((f) => f.name).toList();
        expect(names, containsAll(['system-info.txt', 'app.log']));

        final systemInfo = String.fromCharCodes(
          archive.firstWhere((f) => f.name == 'system-info.txt').content
              as List<int>,
        );
        expect(systemInfo, contains('App: Zedu Desktop'));
        expect(systemInfo, contains('Package: com.zedu.desktop'));
        expect(systemInfo, contains('Version: 1.2.3'));
        expect(systemInfo, contains('Build number: 45'));
        expect(systemInfo, contains('Platform: ${Platform.operatingSystem}'));
        expect(
          systemInfo,
          contains('OS version: ${Platform.operatingSystemVersion}'),
        );

        final log = String.fromCharCodes(
          archive.firstWhere((f) => f.name == 'app.log').content as List<int>,
        );
        expect(log, contains('Unique diagnostics log line 42'));
      },
    );
  });

  group('AppLogger.logDump', () {
    test('renders buffered entries oldest first with level and tag', () {
      AppLogger.d('First line');
      AppLogger.e('Second line', tag: 'TestTag');

      final dump = AppLogger.logDump();
      expect(dump, contains('First line'));
      expect(dump, contains('Second line'));
      expect(dump, contains('TestTag'));
      expect(dump.indexOf('First line'), lessThan(dump.indexOf('Second line')));
    });
  });
}
