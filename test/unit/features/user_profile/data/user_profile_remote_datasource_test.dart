import '../../../../helpers/helpers.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockApiBaseService extends Mock implements ApiBaseService {}

void main() {
  group('UserProfileRemoteDataSourceImpl.updateAccount', () {
    late MockApiBaseService mockApi;
    late UserProfileRemoteDataSourceImpl datasource;

    setUp(() {
      mockApi = MockApiBaseService();
      datasource = UserProfileRemoteDataSourceImpl(
        config: const AppConfig(apiBaseUrl: '', usesMockData: false),
        apiBaseService: mockApi,
      );
      when(
        () => mockApi.patch<Map<String, dynamic>>(
          path: any(named: 'path'),
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => const ApiResponseModel<Map<String, dynamic>>(
          data: {'status': 'success'},
          statusCode: 200,
        ),
      );
    });

    test('sends the phone number to PATCH /profile as form data', () async {
      const account = ProfileAccount(
        name: 'Odofin Moronke',
        email: '',
        timezone: '',
        phoneNumber: '+2348012345678',
      );

      final saved = await datasource.updateAccount(account);

      final data =
          verify(
                () => mockApi.patch<Map<String, dynamic>>(
                  path: '/profile',
                  data: captureAny(named: 'data'),
                ),
              ).captured.single
              as FormData;
      expect(Map.fromEntries(data.fields), {
        'full_name': 'Odofin Moronke',
        'phone': '+2348012345678',
      });
      expect(saved.phoneNumber, '+2348012345678');
    });
  });

  group('UserProfileRemoteDataSourceImpl.deleteOrganization', () {
    late MockApiBaseService mockApi;

    setUp(() => mockApi = MockApiBaseService());

    UserProfileRemoteDataSourceImpl dataSource({required bool mock}) =>
        UserProfileRemoteDataSourceImpl(
          config: AppConfig(apiBaseUrl: '', usesMockData: mock),
          apiBaseService: mockApi,
        );

    test('calls DELETE /organisations/{orgId}', () async {
      when(
        () => mockApi.delete<Map<String, dynamic>>(path: any(named: 'path')),
      ).thenAnswer(
        (_) async => const ApiResponseModel<Map<String, dynamic>>(
          data: {},
          statusCode: 200,
        ),
      );

      await dataSource(mock: false).deleteOrganization('org_1');

      verify(
        () =>
            mockApi.delete<Map<String, dynamic>>(path: '/organisations/org_1'),
      ).called(1);
    });

    test('makes no request in mock mode', () async {
      await dataSource(mock: true).deleteOrganization('org_1');

      verifyNever(
        () => mockApi.delete<Map<String, dynamic>>(path: any(named: 'path')),
      );
    });
  });
}
