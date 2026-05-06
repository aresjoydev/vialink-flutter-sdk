import 'package:flutter_test/flutter_test.dart';
import 'package:vialink_flutter_plugin/src/models/deferred_error.dart';

/// 디퍼드 콜백 redesign(3.0) 후 DeferredError 모델 분기 검증.
///
/// 실제 EventChannel 흐름은 native plugin과 통합 테스트에서 검증한다.
void main() {
  group('DeferredError', () {
    test('timeout 기본 필드', () {
      const err = DeferredError(
        code: DeferredError.codeTimeout,
        message: '5초 안에 완료되지 않았습니다.',
        retryable: true,
      );
      expect(err.code, 'timeout');
      expect(err.retryable, true);
      expect(err.httpStatus, isNull);
    });

    test('server_error는 httpStatus 포함', () {
      const err = DeferredError(
        code: DeferredError.codeServerError,
        message: 'HTTP 503',
        httpStatus: 503,
        retryable: true,
      );
      expect(err.httpStatus, 503);
      expect(err.retryable, true);
    });

    test('invalid_response는 retryable false', () {
      const err = DeferredError(
        code: DeferredError.codeInvalidResponse,
        message: 'JSON parse failure',
        retryable: false,
      );
      expect(err.retryable, false);
    });

    test('code 상수가 plan §2.4 표와 일치', () {
      // plan §2.4 DeferredError.code 표
      expect(DeferredError.codeTimeout, 'timeout');
      expect(DeferredError.codeNetwork, 'network');
      expect(DeferredError.codeServerError, 'server_error');
      expect(DeferredError.codeInvalidResponse, 'invalid_response');
      expect(DeferredError.codeUnknown, 'unknown');
    });

    test('fromMap — native plugin이 보낸 페이로드 파싱', () {
      // Android plugin이 보내는 포맷
      final err = DeferredError.fromMap(<String, dynamic>{
        'code': 'timeout',
        'message': '5초 안에 완료되지 않았습니다.',
        'httpStatus': null,
        'retryable': true,
      });
      expect(err.code, 'timeout');
      expect(err.retryable, true);
      expect(err.httpStatus, isNull);
    });

    test('fromMap — server_error httpStatus int 변환', () {
      final err = DeferredError.fromMap(<String, dynamic>{
        'code': 'server_error',
        'message': 'HTTP 503',
        'httpStatus': 503,
        'retryable': true,
      });
      expect(err.code, 'server_error');
      expect(err.httpStatus, 503);
    });

    test('fromMap — snake_case http_status도 허용', () {
      final err = DeferredError.fromMap(<String, dynamic>{
        'code': 'server_error',
        'message': 'HTTP 503',
        'http_status': 503,
        'retryable': true,
      });
      expect(err.httpStatus, 503);
    });

    test('fromMap — 누락 필드는 기본값', () {
      final err = DeferredError.fromMap(<String, dynamic>{});
      expect(err.code, DeferredError.codeUnknown);
      expect(err.message, isEmpty);
      expect(err.retryable, false);
    });
  });
}
