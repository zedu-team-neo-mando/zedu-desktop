import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/core/core.dart';

void main() {
  group('AppConfig connectUrl', () {
    test(
      'constructor default sets connectUrl to staging websocket default',
      () {
        const config = AppConfig(
          apiBaseUrl: 'https://example.com/',
          usesMockData: false,
        );

        expect(
          config.connectUrl,
          'wss://connect.staging.zedu.chat/connection/websocket',
        );
        expect(config.connectUrl, kDefaultCentrifugoConnectUrl);
      },
    );

    test('constructor accepts custom connectUrl override', () {
      const config = AppConfig(
        apiBaseUrl: 'https://example.com/',
        usesMockData: false,
        connectUrl: 'wss://connect.custom.domain/ws',
      );

      expect(config.connectUrl, 'wss://connect.custom.domain/ws');
    });

    test(
      'fromEnvironment falls back to default connectUrl when absent from dotenv',
      () {
        dotenv.loadFromString(envString: 'API_BASE_URL=https://api.test/');
        final config = AppConfig.fromEnvironment();

        expect(
          config.connectUrl,
          'wss://connect.staging.zedu.chat/connection/websocket',
        );
        expect(config.connectUrl, kDefaultCentrifugoConnectUrl);
      },
    );

    test('fromEnvironment resolves connectUrl override from dotenv', () {
      dotenv.loadFromString(
        envString:
            'API_BASE_URL=https://api.test/\nCONNECT_URL=wss://connect.production.zedu.chat/connection/websocket',
      );
      final config = AppConfig.fromEnvironment();

      expect(
        config.connectUrl,
        'wss://connect.production.zedu.chat/connection/websocket',
      );
    });
  });
}
