import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vialink_flutter_plugin/vialink_flutter_plugin.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.vialink.sdk/methods');

  group('PaymentInitiatedResult.fromMap', () {
    test('정상 응답 파싱', () {
      final r = PaymentInitiatedResult.fromMap(
        const {'success': true, 'paymentEventId': 'evt_123'},
      );
      expect(r.success, isTrue);
      expect(r.paymentEventId, 'evt_123');
    });

    test('숫자 paymentEventId는 문자열로 정규화', () {
      final r = PaymentInitiatedResult.fromMap(
        const {'success': true, 'paymentEventId': 42},
      );
      expect(r.paymentEventId, '42');
    });

    test('누락된 paymentEventId는 빈 문자열', () {
      final r = PaymentInitiatedResult.fromMap(const {'success': false});
      expect(r.success, isFalse);
      expect(r.paymentEventId, '');
    });
  });

  group('PaymentApi.initiated 입력 검증', () {
    final api = ViaLinkSDK.instance.payment;

    test('잘못된 orderId는 ArgumentError 발생', () async {
      await expectLater(
        api.initiated(const PaymentInitiatedArgs(
          orderId: '',
          amount: 1000,
          currency: 'KRW',
        )),
        throwsArgumentError,
      );
    });

    test('100자 초과 orderId는 ArgumentError 발생', () async {
      await expectLater(
        api.initiated(PaymentInitiatedArgs(
          orderId: 'a' * 101,
          amount: 1000,
          currency: 'KRW',
        )),
        throwsArgumentError,
      );
    });

    test('금지 문자 포함된 orderId는 ArgumentError 발생', () async {
      await expectLater(
        api.initiated(const PaymentInitiatedArgs(
          orderId: 'order id',
          amount: 1000,
          currency: 'KRW',
        )),
        throwsArgumentError,
      );
    });

    test('amount <= 0은 ArgumentError 발생', () async {
      await expectLater(
        api.initiated(const PaymentInitiatedArgs(
          orderId: 'order_1',
          amount: 0,
          currency: 'KRW',
        )),
        throwsArgumentError,
      );
    });

    test('빈 currency는 ArgumentError 발생', () async {
      await expectLater(
        api.initiated(const PaymentInitiatedArgs(
          orderId: 'order_1',
          amount: 1000,
          currency: '   ',
        )),
        throwsArgumentError,
      );
    });
  });

  group('PaymentApi.initiated MethodChannel 호출', () {
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'paymentInitiated') {
          // payload 검증: currency는 trim+upper, optional 키는 유지
          final args = Map<String, dynamic>.from(call.arguments as Map);
          expect(args['orderId'], 'order_42');
          expect(args['amount'], 1500.0);
          expect(args['currency'], 'KRW');
          expect(args['linkId'], 7);
          expect(args['paymentMethod'], 'card');
          expect(args['metadata'], {'campaign': 'spring'});
          return {'success': true, 'paymentEventId': 'evt_42'};
        }
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('정상 호출은 PaymentInitiatedResult 반환', () async {
      final api = ViaLinkSDK.instance.payment;
      final r = await api.initiated(const PaymentInitiatedArgs(
        orderId: 'order_42',
        amount: 1500,
        currency: 'krw',
        linkId: 7,
        paymentMethod: 'card',
        metadata: {'campaign': 'spring'},
      ));
      expect(r.success, isTrue);
      expect(r.paymentEventId, 'evt_42');
    });
  });
}
