import '../vialink_method_channel.dart';

/// 결제 시도 입력 인자.
///
/// - [orderId]: 운영자가 발급하는 주문번호 (1~100자, 영문/숫자/하이픈/언더스코어)
/// - [amount]: 결제 금액 (통화 단위 그대로, > 0)
/// - [currency]: ISO 4217 통화 코드 (예: "KRW", "USD", "JPY")
/// - [linkId]: (옵션) 사용자가 진입한 링크 id
/// - [paymentMethod]: (옵션) 결제 수단 식별자 (예: "card", "kakao_pay")
/// - [metadata]: (옵션) 운영자 자유 메타데이터 (문자열만 허용)
class PaymentInitiatedArgs {
  final String orderId;
  final double amount;
  final String currency;
  final int? linkId;
  final String? paymentMethod;
  final Map<String, String>? metadata;

  const PaymentInitiatedArgs({
    required this.orderId,
    required this.amount,
    required this.currency,
    this.linkId,
    this.paymentMethod,
    this.metadata,
  });
}

/// 결제 시도 응답.
///
/// - [success]: 서버에서 성공 처리되었는지 여부
/// - [paymentEventId]: 서버에서 발급한 결제 이벤트 ID (문자열로 정규화)
class PaymentInitiatedResult {
  final bool success;
  final String paymentEventId;

  const PaymentInitiatedResult({
    required this.success,
    required this.paymentEventId,
  });

  factory PaymentInitiatedResult.fromMap(Map<String, dynamic> map) {
    return PaymentInitiatedResult(
      success: map['success'] == true,
      paymentEventId: (map['paymentEventId'] ?? '').toString(),
    );
  }
}

/// 결제 추적 namespace API. `ViaLinkSDK.instance.payment` 으로 접근.
class PaymentApi {
  final ViaLinkMethodChannel _channel;
  PaymentApi(this._channel);

  static final RegExp _orderIdRegex = RegExp(r'^[A-Za-z0-9_\-]{1,100}$');

  /// 결제 시도 기록 (POST /v1/payments/initiated).
  ///
  /// 입력 검증을 거쳐 native SDK의 `payment.initiated`로 전달한다.
  Future<PaymentInitiatedResult> initiated(PaymentInitiatedArgs args) async {
    if (!_orderIdRegex.hasMatch(args.orderId)) {
      throw ArgumentError(
        'order_id 형식이 올바르지 않습니다 (1~100자, 영문/숫자/하이픈/언더스코어).',
      );
    }
    if (!args.amount.isFinite || args.amount <= 0) {
      throw ArgumentError('amount는 0보다 큰 숫자여야 합니다.');
    }
    if (args.currency.trim().isEmpty) {
      throw ArgumentError('currency가 필요합니다.');
    }

    final payload = <String, dynamic>{
      'orderId': args.orderId,
      'amount': args.amount,
      'currency': args.currency.trim().toUpperCase(),
      if (args.linkId != null) 'linkId': args.linkId,
      if (args.paymentMethod != null) 'paymentMethod': args.paymentMethod,
      if (args.metadata != null) 'metadata': args.metadata,
    };

    final result = await _channel.paymentInitiated(payload);
    return PaymentInitiatedResult.fromMap(result);
  }
}
