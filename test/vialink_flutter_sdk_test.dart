import 'package:flutter_test/flutter_test.dart';
import 'package:vialink_flutter_plugin/vialink_flutter_plugin.dart';

void main() {
  group('DeepLinkData', () {
    test('기본 생성 및 toString', () {
      const data = DeepLinkData(
        path: '/product/123',
        params: {'promo_code': 'FRIEND'},
        shortCode: 'aB3xK',
        linkId: 42,
      );

      expect(data.path, '/product/123');
      expect(data.params['promo_code'], 'FRIEND');
      expect(data.shortCode, 'aB3xK');
      expect(data.linkId, 42);
      expect(data.toString(), contains('/product/123'));
    });

    test('동등성 비교', () {
      const a = DeepLinkData(
        path: '/test',
        params: {'key': 'value'},
        shortCode: 'abc',
        linkId: 1,
      );
      const b = DeepLinkData(
        path: '/test',
        params: {'key': 'value'},
        shortCode: 'abc',
        linkId: 1,
      );
      const c = DeepLinkData(
        path: '/other',
        params: {},
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('기본값', () {
      const data = DeepLinkData(path: '/');

      expect(data.params, isEmpty);
      expect(data.shortCode, isNull);
      expect(data.linkId, isNull);
    });
  });

  group('PaymentResult', () {
    test('기본 생성', () {
      const result = PaymentResult(
        success: true,
        paymentEventId: '12345',
      );

      expect(result.success, isTrue);
      expect(result.paymentEventId, '12345');
    });
  });

  group('ViaLinkSDK', () {
    test('싱글턴 인스턴스', () {
      final a = ViaLinkSDK.instance;
      final b = ViaLinkSDK.instance;
      expect(identical(a, b), isTrue);
    });
  });
}
