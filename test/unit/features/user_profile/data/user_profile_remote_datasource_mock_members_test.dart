import '../../../../helpers/helpers.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockApiBaseService extends Mock implements ApiBaseService {}

void main() {
  group('UserProfileRemoteDataSourceImpl.getTeamMembers mock data', () {
    late MockApiBaseService mockApi;
    late UserProfileRemoteDataSourceImpl datasource;

    setUp(() {
      mockApi = MockApiBaseService();
      datasource = UserProfileRemoteDataSourceImpl(
        config: const AppConfig(apiBaseUrl: '', usesMockData: true),
        apiBaseService: mockApi,
      );
    });

    test(
      'returns the real curated member list, never fabricated teammates '
      '(Ziki #2877)',
      () async {
        final members = await datasource.getTeamMembers();

        expect(members, isNotEmpty);
        expect(members.length, lessThan(100));
        expect(
          members.where((m) => (m.name ?? '').startsWith('Teammate ')),
          isEmpty,
        );
        expect(
          members.where(
            (m) =>
                m.email.contains('@zedu.app') &&
                m.id.startsWith('member-mock'),
          ),
          isEmpty,
        );
        expect(members.first.name, 'Anonymoususer');
      },
    );
  });
}
