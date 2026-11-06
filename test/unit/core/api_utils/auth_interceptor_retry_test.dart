import 'dart:io';

import '../../../helpers/helpers.dart';
import 'package:zedu/core/core.dart';

class _MemoryStorage extends SecureStorageService {
  String? token;
  int deleteCalls = 0;

  @override
  Future<String?> getAccessToken() async => token;

  @override
  Future<void> saveAccessToken(String token, {bool persist = true}) async =>
      this.token = token;

  @override
  Future<void> deleteAccessToken() async {
    token = null;
    deleteCalls++;
  }
}

void main() {
  late HttpServer server;
  late String baseUrl;
  late List<int> scriptedStatuses;
  late List<String?> seenAuthHeaders;

  Dio buildDio() => Dio(BaseOptions(baseUrl: baseUrl));

  setUp(() async {
    scriptedStatuses = [];
    seenAuthHeaders = [];
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    baseUrl = 'http://127.0.0.1:${server.port}/';
    server.listen((request) {
      seenAuthHeaders.add(request.headers.value('authorization'));
      final status = scriptedStatuses.length > 1
          ? scriptedStatuses.removeAt(0)
          : scriptedStatuses.first;
      request.response
        ..statusCode = status
        ..headers.contentType = ContentType.json
        ..write('{"ok":true}');
      request.response.close();
    });
  });

  tearDown(() async {
    await server.close(force: true);
  });

  test('retries the original request with the refreshed token after 401',
      () async {
    scriptedStatuses = [401, 200];
    final storage = _MemoryStorage()..token = 'old-token';
    var signedOut = 0;
    final dio = buildDio();
    dio.interceptors.add(
      AuthInterceptor(storage: storage, dio: dio)
        ..onRefreshToken = (() async => 'new-token')
        ..onUnauthorized = (() => signedOut++),
    );

    final response = await dio.get<dynamic>('a');

    expect(response.statusCode, 200);
    expect(seenAuthHeaders, ['Bearer old-token', 'Bearer new-token']);
    expect(storage.token, 'new-token');
    expect(storage.deleteCalls, 0);
    expect(signedOut, 0);
  });

  test('signs out without retrying when no refreshed token is available',
      () async {
    scriptedStatuses = [401];
    final storage = _MemoryStorage()..token = 'old-token';
    var signedOut = 0;
    final dio = buildDio();
    dio.interceptors.add(
      AuthInterceptor(storage: storage, dio: dio)
        ..onRefreshToken = (() async => null)
        ..onUnauthorized = (() => signedOut++),
    );

    await expectLater(
      dio.get<dynamic>('a'),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'statusCode',
          401,
        ),
      ),
    );

    expect(seenAuthHeaders, ['Bearer old-token']);
    expect(storage.deleteCalls, 1);
    expect(storage.token, isNull);
    expect(signedOut, 1);
  });

  test('does not re-dispatch when the token did not change', () async {
    scriptedStatuses = [401];
    final storage = _MemoryStorage()..token = 'old-token';
    var signedOut = 0;
    final dio = buildDio();
    dio.interceptors.add(
      AuthInterceptor(storage: storage, dio: dio)
        ..onRefreshToken = (() async => 'old-token')
        ..onUnauthorized = (() => signedOut++),
    );

    await expectLater(
      dio.get<dynamic>('a'),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'statusCode',
          401,
        ),
      ),
    );

    expect(seenAuthHeaders, ['Bearer old-token']);
    expect(signedOut, 1);
  });

  test('signs out when the retried request is rejected again', () async {
    scriptedStatuses = [401, 401];
    final storage = _MemoryStorage()..token = 'old-token';
    var signedOut = 0;
    final dio = buildDio();
    dio.interceptors.add(
      AuthInterceptor(storage: storage, dio: dio)
        ..onRefreshToken = (() async => 'new-token')
        ..onUnauthorized = (() => signedOut++),
    );

    await expectLater(
      dio.get<dynamic>('a'),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'statusCode',
          401,
        ),
      ),
    );

    expect(seenAuthHeaders, ['Bearer old-token', 'Bearer new-token']);
    expect(storage.deleteCalls, 1);
    expect(signedOut, 1);
  });
}
