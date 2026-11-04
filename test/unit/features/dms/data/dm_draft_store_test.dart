import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late MockSecureStorageService storage;

  setUp(() {
    storage = MockSecureStorageService();
  });

  group('DmDraftStore.clearAllForUser', () {
    test('deletes only the signed-in user draft keys', () async {
      when(() => storage.readAllData()).thenAnswer(
        (_) async => {
          'dm_draft_user-1_org-1_channel-1': '{"text":"a","updatedAt":1}',
          'dm_draft_user-1_org-2_channel-2': '{"text":"b","updatedAt":2}',
          'dm_draft_user-2_org-1_channel-1': '{"text":"c","updatedAt":3}',
          'access_token': 'token',
        },
      );
      when(() => storage.deleteValue(any())).thenAnswer((_) async {});

      await DmDraftStore.clearAllForUser(storage, userId: 'user-1');

      verify(
        () => storage.deleteValue('dm_draft_user-1_org-1_channel-1'),
      ).called(1);
      verify(
        () => storage.deleteValue('dm_draft_user-1_org-2_channel-2'),
      ).called(1);
      verifyNever(() => storage.deleteValue('dm_draft_user-2_org-1_channel-1'));
      verifyNever(() => storage.deleteValue('access_token'));
    });

    test('does nothing for an empty user id', () async {
      await DmDraftStore.clearAllForUser(storage, userId: '');

      verifyNever(() => storage.readAllData());
    });
  });
}
