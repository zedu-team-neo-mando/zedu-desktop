import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/core/core.dart';

const generic = 'Something went wrong. Please try again.';

void main() {
  group('ApiFailure.friendlyMessage', () {
    const detail = "type 'Null' is not a subtype of type 'String'";

    test('hides the raw text of a parsing failure', () {
      final failure = ApiFailure(
        message: 'Could not parse response: $detail',
        kind: ApiFailureKind.parsing,
      );

      expect(failure.friendlyMessage, generic);
      expect(failure.message, contains(detail));
      expect(failure.toString(), contains(detail));
    });

    test('hides the raw text of an unknown failure', () {
      final failure = ApiFailure(message: detail, kind: ApiFailureKind.unknown);

      expect(failure.friendlyMessage, generic);
      expect(failure.message, contains(detail));
    });

    test('the parsing constructor keeps its detail for the log', () {
      final failure = ApiFailure.fromParsingError(
        Exception('decoder complained here'),
        path: 'auth/login',
      );

      expect(failure.kind, ApiFailureKind.parsing);
      expect(failure.friendlyMessage, generic);
      expect(failure.message, contains('decoder complained here'));
    });

    test('the unknown constructor keeps its detail for the log', () {
      final failure = ApiFailure.unknown(StateError('bad state'));

      expect(failure.kind, ApiFailureKind.unknown);
      expect(failure.friendlyMessage, generic);
      expect(failure.message, contains('bad state'));
    });

    test('a client failure still shows the servers own copy', () {
      const failure = ApiFailure(
        message: 'Invalid credentials',
        kind: ApiFailureKind.client,
      );

      expect(failure.friendlyMessage, 'Invalid credentials');
    });

    test('network and server kinds keep their actionable copy', () {
      const network = ApiFailure(
        message: 'connection refused',
        kind: ApiFailureKind.network,
      );
      const server = ApiFailure(
        message: 'upstream 503',
        kind: ApiFailureKind.server,
      );

      expect(
        network.friendlyMessage,
        'No internet connection. Check your network and try again.',
      );
      expect(
        server.friendlyMessage,
        'Something went wrong on our end. Please try again later.',
      );
    });
  });
}
