/// 결제 시도 응답 모델
class PaymentResult {
  final bool success;
  final String paymentEventId;

  const PaymentResult({
    required this.success,
    required this.paymentEventId,
  });

  @override
  String toString() =>
      'PaymentResult(success: $success, paymentEventId: $paymentEventId)';
}
