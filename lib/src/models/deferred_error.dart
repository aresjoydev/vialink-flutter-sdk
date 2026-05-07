/// 디퍼드 매칭 실패 정보
///
/// `onDeferredDeepLink((data, error) => ...)` 콜백의 두 번째 인자로 전달된다.
/// `data == null && error == null`이면 매칭 결과가 "없음"(organic install)이다.
///
/// [code] 가능한 값:
/// - `'timeout'`: 5초 데드라인 만료
/// - `'network'`: DNS 실패, 연결 거부 등 (3회 재시도 모두 실패)
/// - `'server_error'`: HTTP 5xx (3회 재시도 모두 실패)
/// - `'invalid_response'`: 응답 JSON 파싱 실패
/// - `'unknown'`: 그 외 모든 예외
///
/// [retryable]이 true면 SDK가 다음 앱 실행에서 자동으로 다시 시도한다.
/// 이 경우 사용자가 앱을 사용 중일 때 콜백이 도착할 수 있다.
class DeferredError {
  static const String codeTimeout = 'timeout';
  static const String codeNetwork = 'network';
  static const String codeServerError = 'server_error';
  static const String codeInvalidResponse = 'invalid_response';
  static const String codeUnknown = 'unknown';

  final String code;
  final String message;
  final int? httpStatus;
  final bool retryable;

  const DeferredError({
    required this.code,
    required this.message,
    this.httpStatus,
    required this.retryable,
  });

  factory DeferredError.fromMap(Map<String, dynamic> map) {
    final rawStatus = map['httpStatus'] ?? map['http_status'];
    final int? httpStatus = rawStatus is int
        ? rawStatus
        : (rawStatus is num ? rawStatus.toInt() : null);
    return DeferredError(
      code: (map['code'] as String?) ?? codeUnknown,
      message: (map['message'] as String?) ?? '',
      httpStatus: httpStatus,
      retryable: (map['retryable'] as bool?) ?? false,
    );
  }

  @override
  String toString() {
    return 'DeferredError(code: $code, retryable: $retryable, message: $message'
        '${httpStatus != null ? ', httpStatus: $httpStatus' : ''})';
  }
}
