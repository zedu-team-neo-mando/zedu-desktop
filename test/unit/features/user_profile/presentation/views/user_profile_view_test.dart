import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

ProfileAccount buildAccount({
  String name = 'Stored Name',
  String email = 'stored@zedu.chat',
  String username = 'storedname',
  String? avatarUrl = 'https://example.com/stored.png',
  String phoneNumber = '08011111111',
}) {
  return ProfileAccount(
    name: name,
    email: email,
    timezone: 'Africa/Lagos',
    username: username,
    avatarUrl: avatarUrl,
    phoneNumber: phoneNumber,
  );
}

User buildSessionUser({
  String id = 'user-1',
  String firstName = 'Ada',
  String lastName = 'Okafor',
  String email = 'ada@zedu.chat',
  String username = 'ada',
  String phone = '08000000000',
  String avatarUrl = 'https://example.com/session.png',
}) {
  return User(
    id: id,
    firstName: firstName,
    lastName: lastName,
    email: email,
    phone: phone,
    username: username,
    isVerified: true,
    isOnboarded: true,
    createdAt: DateTime(2026, 1, 1),
    currentOrg: 'org-1',
    currentOrganisationSlug: 'zedu-org',
    avatarUrl: avatarUrl,
    defaultAvatarUrl: '',
  );
}

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

class MockAuthNotifier extends Notifier<AuthState>
    with Mock
    implements AuthNotifier {
  MockAuthNotifier(this._initialState);
  final AuthState _initialState;

  @override
  AuthState build() => _initialState;

  void emit(AuthState newState) => state = newState;
}

class MockWorkspaceNotifier extends Notifier<WorkspaceState>
    with Mock
    implements WorkspaceNotifier {
  @override
  WorkspaceState build() => const WorkspaceState();
}

void main() {
  group('accountForAuthenticatedUser', () {
    test('leaves the account untouched when there is no session user', () {
      final account = buildAccount();

      expect(accountForAuthenticatedUser(account, null), same(account));
    });

    group('Bug 1: Full-name resolution and display', () {
      test(
        'uses the authenticated user full name when account name is empty',
        () {
          final account = accountForAuthenticatedUser(
            buildAccount(name: '', email: 'ada@zedu.chat'),
            buildSessionUser(firstName: 'Ada', lastName: 'Okafor'),
          );

          expect(account.name, 'Ada Okafor');
        },
      );

      test(
        'uses the authenticated user full name when account name is placeholder',
        () {
          final account = accountForAuthenticatedUser(
            buildAccount(name: 'Anonymous user', email: 'ada@zedu.chat'),
            buildSessionUser(firstName: 'Ada', lastName: 'Okafor'),
          );

          expect(account.name, 'Ada Okafor');
        },
      );

      test(
        'overrides account name when it is only the raw username, prioritizing full name',
        () {
          final sessionUser = buildSessionUser(
            firstName: 'Pauline',
            lastName: 'Banye',
            username: 'pauline',
            email: 'pauline@zedu.chat',
          );
          final account = accountForAuthenticatedUser(
            buildAccount(
              name: 'pauline',
              email: 'pauline@zedu.chat',
              username: 'pauline',
            ),
            sessionUser,
          );

          expect(account.name, 'Pauline Banye');
        },
      );

      test('derives full name from first and last name', () {
        final sessionUser = buildSessionUser(
          firstName: 'Pauline',
          lastName: 'Banye',
          username: 'pauline',
          email: 'pauline@zedu.chat',
        );
        final account = accountForAuthenticatedUser(
          buildAccount(name: '', email: 'pauline@zedu.chat'),
          sessionUser,
        );

        expect(account.name, 'Pauline Banye');
      });

      test('retains an updated real full name for the same user account', () {
        final account = accountForAuthenticatedUser(
          buildAccount(name: 'Ada N. Okafor', email: 'ada@zedu.chat'),
          buildSessionUser(
            email: 'ada@zedu.chat',
            firstName: 'Ada',
            lastName: 'Okafor',
          ),
        );

        expect(account.name, 'Ada N. Okafor');
      });
    });

    group('Email and profile field resolution', () {
      test('uses the session email when account email is empty', () {
        final account = accountForAuthenticatedUser(
          buildAccount(email: ''),
          buildSessionUser(email: 'ada@zedu.chat'),
        );

        expect(account.email, 'ada@zedu.chat');
      });

      test('uses the session email when account email is placeholder', () {
        final account = accountForAuthenticatedUser(
          buildAccount(email: 'anonymoususer@email.com'),
          buildSessionUser(email: 'ada@zedu.chat'),
        );

        expect(account.email, 'ada@zedu.chat');
      });

      test(
        'uses session username when account username is empty or placeholder',
        () {
          final emptyAccount = accountForAuthenticatedUser(
            buildAccount(username: '', email: 'ada@zedu.chat'),
            buildSessionUser(username: 'ada', email: 'ada@zedu.chat'),
          );
          expect(emptyAccount.username, 'ada');

          final placeholderAccount = accountForAuthenticatedUser(
            buildAccount(username: 'anonymoususer', email: 'ada@zedu.chat'),
            buildSessionUser(username: 'ada', email: 'ada@zedu.chat'),
          );
          expect(placeholderAccount.username, 'ada');
        },
      );

      test('uses session avatar and phone when available', () {
        final account = accountForAuthenticatedUser(
          buildAccount(
            email: 'ada@zedu.chat',
            avatarUrl: null,
            phoneNumber: '',
          ),
          buildSessionUser(
            email: 'ada@zedu.chat',
            avatarUrl: 'https://example.com/ada-session.png',
            phone: '08099999999',
          ),
        );

        expect(account.avatarUrl, 'https://example.com/ada-session.png');
        expect(account.phoneNumber, '08099999999');
      });
    });

    group('Bug 2: Account switching across users', () {
      test(
        'discards User A info and renders User B info without restarting app',
        () {
          // User A was previously loaded into the account state.
          final userAAccount = buildAccount(
            name: 'Pauline Banye',
            email: 'pauline@zedu.chat',
            username: 'pauline',
            avatarUrl: 'https://example.com/pauline.png',
            phoneNumber: '08011111111',
          );

          // User B logs in without restarting the application.
          final userBSession = buildSessionUser(
            id: 'user-b',
            firstName: 'Maureen',
            lastName: 'Chidera',
            email: 'maureen@zedu.chat',
            username: 'maureen',
            phone: '08022222222',
            avatarUrl: 'https://example.com/maureen.png',
          );

          final resolvedAccount = accountForAuthenticatedUser(
            userAAccount,
            userBSession,
          );

          // User A's data must be completely discarded.
          expect(resolvedAccount.name, 'Maureen Chidera');
          expect(resolvedAccount.name, isNot('Pauline Banye'));
          expect(resolvedAccount.name, isNot('pauline'));

          expect(resolvedAccount.email, 'maureen@zedu.chat');
          expect(resolvedAccount.email, isNot('pauline@zedu.chat'));

          expect(resolvedAccount.username, 'maureen');
          expect(resolvedAccount.username, isNot('pauline'));

          expect(resolvedAccount.avatarUrl, 'https://example.com/maureen.png');
          expect(resolvedAccount.phoneNumber, '08022222222');
        },
      );

      test(
        'clears previous user custom fields when switching to a user with empty fields',
        () {
          final userAAccount = buildAccount(
            name: 'Pauline Banye',
            email: 'pauline@zedu.chat',
            username: 'pauline',
            avatarUrl: 'https://example.com/pauline.png',
          );

          // User B has no avatar and no phone.
          final userBSession = buildSessionUser(
            id: 'user-b',
            firstName: 'Maureen',
            lastName: 'Chidera',
            email: 'maureen@zedu.chat',
            username: 'maureen',
            phone: '',
            avatarUrl: '',
          );

          final resolvedAccount = accountForAuthenticatedUser(
            userAAccount,
            userBSession,
          );

          expect(resolvedAccount.name, 'Maureen Chidera');
          expect(resolvedAccount.email, 'maureen@zedu.chat');
          expect(resolvedAccount.username, 'maureen');
          expect(resolvedAccount.avatarUrl, isNull);
          expect(resolvedAccount.phoneNumber, '');
        },
      );
    });
  });

  group('UserProfileNotifier lifecycle & concurrency (Bug 2)', () {
    late MockUserProfileRepository mockRepository;

    setUp(() {
      mockRepository = MockUserProfileRepository();
      when(() => mockRepository.getAccount()).thenAnswer(
        (_) async => const Success(
          ProfileAccount(name: '', email: '', timezone: 'Africa/Lagos'),
        ),
      );
      when(
        () => mockRepository.getNotificationPreferences(),
      ).thenAnswer((_) async => Success(NotificationPreferences.empty()));
      when(
        () => mockRepository.getSecuritySessions(),
      ).thenAnswer((_) async => const Success([]));
      when(
        () => mockRepository.getOrganization(),
      ).thenAnswer((_) async => Success(OrganizationProfile.empty()));
      when(
        () => mockRepository.getTeamMembers(orgId: any(named: 'orgId')),
      ).thenAnswer((_) async => const Success([]));
      when(
        () => mockRepository.getRolesAndPermissions(),
      ).thenAnswer((_) async => const Success([]));
      when(
        () => mockRepository.getBillingInfo(),
      ).thenAnswer((_) async => Success(BillingInfo.empty()));
    });

    test('initializes empty state when user is unauthenticated', () {
      final mockAuth = MockAuthNotifier(
        const AuthState(status: AuthStatus.unauthenticated),
      );

      final container = ProviderContainer(
        overrides: [
          userProfileRepositoryProvider.overrideWithValue(mockRepository),
          workspaceProvider.overrideWith(MockWorkspaceNotifier.new),
          authNotifierProvider.overrideWith(() => mockAuth),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(userProfileNotifierProvider);
      expect(state.account, isNull);
      expect(state.isLoading, isFalse);
    });

    test(
      'initializes immediately with authenticated user full name and email',
      () async {
        final userA = buildSessionUser(
          id: 'user-a',
          firstName: 'Pauline',
          lastName: 'Banye',
          email: 'pauline@zedu.chat',
          username: 'pauline',
        );

        final mockAuth = MockAuthNotifier(
          AuthState(status: AuthStatus.authenticated, user: userA),
        );

        final container = ProviderContainer(
          overrides: [
            userProfileRepositoryProvider.overrideWithValue(mockRepository),
            workspaceProvider.overrideWith(MockWorkspaceNotifier.new),
            authNotifierProvider.overrideWith(() => mockAuth),
          ],
        );
        addTearDown(container.dispose);

        // Immediate state before microtask completes
        final immediateState = container.read(userProfileNotifierProvider);
        expect(immediateState.account, isNotNull);
        expect(immediateState.account!.name, 'Pauline Banye');
        expect(immediateState.account!.email, 'pauline@zedu.chat');
        expect(immediateState.account!.username, 'pauline');
        expect(immediateState.isLoading, isTrue);

        // Allow microtask load() to settle
        await Future<void>.delayed(Duration.zero);
        final loadedState = container.read(userProfileNotifierProvider);
        expect(loadedState.account!.name, 'Pauline Banye');
        expect(loadedState.account!.email, 'pauline@zedu.chat');
        expect(loadedState.isLoading, isFalse);
      },
    );

    test('resets state completely on logout', () async {
      final userA = buildSessionUser(
        id: 'user-a',
        firstName: 'Pauline',
        lastName: 'Banye',
        email: 'pauline@zedu.chat',
        username: 'pauline',
      );

      final mockAuth = MockAuthNotifier(
        AuthState(status: AuthStatus.authenticated, user: userA),
      );

      final container = ProviderContainer(
        overrides: [
          userProfileRepositoryProvider.overrideWithValue(mockRepository),
          workspaceProvider.overrideWith(MockWorkspaceNotifier.new),
          authNotifierProvider.overrideWith(() => mockAuth),
        ],
      );
      addTearDown(container.dispose);

      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(userProfileNotifierProvider).account?.name,
        'Pauline Banye',
      );

      // Logout
      mockAuth.emit(const AuthState(status: AuthStatus.unauthenticated));

      final stateAfterLogout = container.read(userProfileNotifierProvider);
      expect(stateAfterLogout.account, isNull);
      expect(stateAfterLogout.isLoading, isFalse);
    });

    test(
      'switches to User B profile and clears User A data without restart',
      () async {
        final userA = buildSessionUser(
          id: 'user-a',
          firstName: 'Pauline',
          lastName: 'Banye',
          email: 'pauline@zedu.chat',
          username: 'pauline',
        );
        final userB = buildSessionUser(
          id: 'user-b',
          firstName: 'Maureen',
          lastName: 'Chidera',
          email: 'maureen@zedu.chat',
          username: 'maureen',
        );

        final mockAuth = MockAuthNotifier(
          AuthState(status: AuthStatus.authenticated, user: userA),
        );

        final container = ProviderContainer(
          overrides: [
            userProfileRepositoryProvider.overrideWithValue(mockRepository),
            workspaceProvider.overrideWith(MockWorkspaceNotifier.new),
            authNotifierProvider.overrideWith(() => mockAuth),
          ],
        );
        addTearDown(container.dispose);

        await Future<void>.delayed(Duration.zero);
        expect(
          container.read(userProfileNotifierProvider).account?.name,
          'Pauline Banye',
        );
        expect(
          container.read(userProfileNotifierProvider).account?.email,
          'pauline@zedu.chat',
        );

        // Switch user to User B
        mockAuth.emit(AuthState(status: AuthStatus.authenticated, user: userB));
        await Future<void>.delayed(Duration.zero);

        final stateUserB = container.read(userProfileNotifierProvider);
        expect(stateUserB.account?.name, 'Maureen Chidera');
        expect(stateUserB.account?.email, 'maureen@zedu.chat');
        expect(stateUserB.account?.username, 'maureen');

        // Ensure User A data does not persist
        expect(stateUserB.account?.name, isNot('Pauline Banye'));
        expect(stateUserB.account?.email, isNot('pauline@zedu.chat'));
        expect(stateUserB.account?.username, isNot('pauline'));
      },
    );

    test(
      'in-flight request for User A completing after User B authenticates does not overwrite User B state',
      () async {
        final userA = buildSessionUser(
          id: 'user-a',
          firstName: 'Pauline',
          lastName: 'Banye',
          email: 'pauline@zedu.chat',
          username: 'pauline',
        );
        final userB = buildSessionUser(
          id: 'user-b',
          firstName: 'Maureen',
          lastName: 'Chidera',
          email: 'maureen@zedu.chat',
          username: 'maureen',
        );

        final userAAccountCompleter = Completer<Result<ProfileAccount>>();
        var accountRequestCount = 0;

        when(() => mockRepository.getAccount()).thenAnswer((_) {
          accountRequestCount++;
          if (accountRequestCount == 1) {
            // Request 1 is User A's in-flight request, held pending.
            return userAAccountCompleter.future;
          }
          // Request 2 is User B's request, which resolves with User B's account.
          return Future.value(
            const Success(
              ProfileAccount(
                name: 'Maureen Loaded',
                email: 'maureen@zedu.chat',
                timezone: 'Africa/Lagos',
              ),
            ),
          );
        });

        final mockAuth = MockAuthNotifier(
          AuthState(status: AuthStatus.authenticated, user: userA),
        );

        final container = ProviderContainer(
          overrides: [
            userProfileRepositoryProvider.overrideWithValue(mockRepository),
            workspaceProvider.overrideWith(MockWorkspaceNotifier.new),
            authNotifierProvider.overrideWith(() => mockAuth),
          ],
        );
        addTearDown(container.dispose);

        // Keep active subscription so notifier reacts eagerly to auth transitions
        container.listen(userProfileNotifierProvider, (previous, next) {});

        // User A starts loading (request 1 is in flight).
        await Future<void>.delayed(Duration.zero);

        // Before User A's getAccount finishes, User B signs in.
        mockAuth.emit(AuthState(status: AuthStatus.authenticated, user: userB));
        // Allow User B's load() microtask to start and complete.
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // User A's delayed in-flight request now finally completes with stale User A data.
        userAAccountCompleter.complete(
          const Success(
            ProfileAccount(
              name: 'Pauline Stale',
              email: 'pauline@zedu.chat',
              timezone: 'Africa/Lagos',
            ),
          ),
        );
        // Allow any pending microtasks from User A's completion to run.
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // State must remain User B's state, NOT overwritten by User A's stale response.
        final finalState = container.read(userProfileNotifierProvider);
        expect(finalState.account?.name, isNot(contains('Pauline')));
        expect(finalState.account?.email, 'maureen@zedu.chat');
        expect(finalState.account?.name, 'Maureen Loaded');
      },
    );
  });
}
