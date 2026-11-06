import 'package:zedu/core/core.dart';

final locator = GetIt.instance;

void setupLocator() {
  locator
    ..registerLazySingleton<AppConfig>(AppConfig.fromEnvironment)
    ..registerLazySingleton<SecureStorageService>(() => SecureStorageService());

  final config = locator<AppConfig>();
  final storage = locator<SecureStorageService>();

  final baseUrl = config.apiBaseUrl.endsWith('/')
      ? config.apiBaseUrl
      : '${config.apiBaseUrl}/';
  final dio = Dio(ApiBaseService.createOptions(baseUrl));
  final authInterceptor = AuthInterceptor(storage: storage, dio: dio)
    ..onRefreshToken = () async {
      // Another flow (login, magic link, Google) may have stored a newer
      // token; the interceptor only retries when it differs from the one
      // that was rejected.
      final token = await storage.getAccessToken();
      return (token == null || token.isEmpty) ? null : token;
    };
  locator.registerLazySingleton<AuthInterceptor>(() => authInterceptor);
  dio.interceptors.add(authInterceptor);

  locator.registerLazySingleton<ApiBaseService>(
    () => ApiBaseService(config: config, dio: dio),
  );
}
