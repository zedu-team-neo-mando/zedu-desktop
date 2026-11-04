import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

class FakeSignUpAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.unauthenticated);
}

void main() {
  testWidgets('sign-up form fits the default 1280x720 window', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(FakeSignUpAuthNotifier.new),
        ],
        child: buildTestMaterialApp(const SignUpView()),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    // The two social buttons share a row instead of stacking.
    final google = tester.getRect(find.text('Sign up with Google'));
    final apple = tester.getRect(find.text('Sign up with Apple'));
    expect((google.center.dy - apple.center.dy).abs(), lessThan(1));
    expect(google.right, lessThan(apple.left));

    // The terms text, the last item in the column, is visible without scrolling.
    final terms = tester.getRect(find.textContaining('By signing up'));
    expect(terms.bottom, lessThanOrEqualTo(720));
  });
}
