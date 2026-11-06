import 'dart:async';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import '../../../../../helpers/helpers.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

User _user({
  String email = 'ada@zedu.chat',
  String fullName = 'Ada Lovelace',
  int creditBalance = 120,
  String subscriptionPlanId = 'pro',
  bool aiCreditsPurchasable = true,
}) {
  return User(
    id: 'u-1',
    firstName: 'Ada',
    lastName: 'Lovelace',
    fullName: fullName,
    email: email,
    phone: '',
    username: 'ada',
    isVerified: true,
    isOnboarded: true,
    createdAt: DateTime(2026, 1, 1),
    currentOrg: 'org-1',
    currentOrganisationSlug: 'org-one',
    avatarUrl: '',
    defaultAvatarUrl: '',
    creditBalance: creditBalance,
    subscriptionPlanId: subscriptionPlanId,
    aiCreditsPurchasable: aiCreditsPurchasable,
  );
}

void main() {
  group('AuthNotifier.refreshCurrentUser (Ziki #2856)', () {
    late MockAuthRepository repository;
    late MockSecureStorageService storage;
    late ProviderContainer container;

    setUp(() {
      repository = MockAuthRepository();
      storage = MockSecureStorageService();

      when(() => storage.deleteAccessToken()).thenAnswer((_) async {});
      when(() => storage.getAccessToken()).thenAnswer(
        (_) async => 'saved-token',
      );
      when(() => repository.getCurrentUser()).thenAnswer(
        (_) async => Success<User>(_user()),
      );

      locator.registerSingleton<SecureStorageService>(storage);
      locator.registerSingleton<AuthInterceptor>(
        AuthInterceptor(storage: storage),
      );

      container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
    });

    tearDown(() async {
      await locator.reset();
    });

    Future<void> waitForUser() async {
      final completer = Completer<void>();
      final subscription = container.listen<AuthState>(
        authNotifierProvider,
        (previous, next) {
          if (next.user != null && !completer.isCompleted) {
            completer.complete();
          }
        },
        fireImmediately: true,
      );
      addTearDown(subscription.close);
      await completer.future.timeout(const Duration(seconds: 5));
    }

    test('preserves locally tracked credit fields while updating profile', () async {
      final fresh = _user(
        email: 'new@zedu.chat',
        fullName: 'Ada B. Lovelace',
        creditBalance: 0,
        subscriptionPlanId: 'free',
        aiCreditsPurchasable: false,
      );

      await waitForUser();
      final before = container.read(authNotifierProvider).user!;
      expect(before.creditBalance, 120);
      expect(before.subscriptionPlanId, 'pro');
      expect(before.aiCreditsPurchasable, isTrue);

      when(() => repository.getCurrentUser()).thenAnswer(
        (_) async => Success<User>(fresh),
      );
      await container.read(authNotifierProvider.notifier).refreshCurrentUser();

      final after = container.read(authNotifierProvider).user!;
      expect(after.email, 'new@zedu.chat');
      expect(after.fullName, 'Ada B. Lovelace');
      expect(after.creditBalance, 120);
      expect(after.subscriptionPlanId, 'pro');
      expect(after.aiCreditsPurchasable, isTrue);
    });

    test('keeps the fresh credit values when there is no current user', () async {
      when(() => storage.getAccessToken()).thenAnswer((_) async => null);
      when(() => repository.getCurrentUser()).thenAnswer(
        (_) async => Success<User>(
          _user(
            creditBalance: 7,
            subscriptionPlanId: 'team',
            aiCreditsPurchasable: false,
          ),
        ),
      );

      await container.read(authNotifierProvider.notifier).refreshCurrentUser();

      final user = container.read(authNotifierProvider).user!;
      expect(user.creditBalance, 7);
      expect(user.subscriptionPlanId, 'team');
      expect(user.aiCreditsPurchasable, isFalse);
    });
  });
}
