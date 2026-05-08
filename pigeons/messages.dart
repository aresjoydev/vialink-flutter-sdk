// Pigeon 인터페이스 정의
// 실행: dart run pigeon --input pigeons/messages.dart

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/generated/messages.g.dart',
  kotlinOut:
      'android/src/main/kotlin/com/vialink/flutter/Messages.g.kt',
  kotlinOptions: KotlinOptions(package: 'com.vialink.flutter'),
  swiftOut: 'ios/Classes/Messages.g.swift',
))

// ──────────────────────────────────────────────
// 데이터 모델
// ──────────────────────────────────────────────

/// 딥링크 데이터 (Flutter ↔ Native 공유)
class VLDeepLinkData {
  VLDeepLinkData({
    required this.path,
    this.params,
    this.shortCode,
    this.linkId,
  });

  final String path;
  final Map<String?, String?>? params;
  final String? shortCode;
  final int? linkId;
}

/// 링크 생성 요청 인자
class VLCreateLinkArgs {
  VLCreateLinkArgs({
    required this.path,
    required this.linkType,
    this.data,
    this.campaign,
    this.iosUrl,
    this.androidUrl,
    this.webUrl,
    this.ogTitle,
    this.ogDescription,
    this.ogImageUrl,
    this.channel,
    this.feature,
    this.tags,
    this.expiresAt,
  });

  final String path;
  final String linkType;
  final Map<String?, String?>? data;
  final String? campaign;
  final String? iosUrl;
  final String? androidUrl;
  final String? webUrl;
  final String? ogTitle;
  final String? ogDescription;
  final String? ogImageUrl;
  final String? channel;
  final String? feature;
  final List<String?>? tags;
  final String? expiresAt;
}

/// 결제 시도 요청 인자
class VLPaymentArgs {
  VLPaymentArgs({
    required this.orderId,
    required this.amount,
    required this.currency,
    this.linkId,
    this.paymentMethod,
    this.metadata,
  });

  final String orderId;
  final double amount;
  final String currency;
  final int? linkId;
  final String? paymentMethod;
  final Map<String?, String?>? metadata;
}

/// 결제 시도 응답
class VLPaymentResult {
  VLPaymentResult({
    required this.success,
    required this.paymentEventId,
  });

  final bool success;
  final String paymentEventId;
}

// ──────────────────────────────────────────────
// Flutter → Native (Host API)
// ──────────────────────────────────────────────

/// Flutter에서 네이티브 SDK를 호출하는 인터페이스
@HostApi()
abstract class ViaLinkHostApi {
  /// SDK 초기화
  void configure(String apiKey);

  /// URL 기반 딥링크 수동 처리
  void handleDeepLink(String url);

  /// 커스텀 이벤트 추적
  void track(String eventName, Map<String?, String?>? data);

  /// (Pull API) 마지막 수신된 딥링크 데이터 (동기)
  VLDeepLinkData? getDeepLinkData();

  /// (Pull API) 디퍼드 매칭 결과 캐시 (동기)
  VLDeepLinkData? getDeferredLinkData();

  /// (Pull API) 딥링크 도착까지 대기 (3초 타임아웃)
  @async
  VLDeepLinkData? awaitDeepLinkData();

  /// (Pull API) 디퍼드 매칭 결과까지 대기
  @async
  VLDeepLinkData? awaitDeferredLinkData();

  /// 링크 생성
  @async
  String createLink(VLCreateLinkArgs args);

  /// 결제 시도 기록
  @async
  VLPaymentResult trackPayment(VLPaymentArgs args);
}

// ──────────────────────────────────────────────
// Native → Flutter (Flutter API) — 콜백/이벤트
// ──────────────────────────────────────────────

/// 네이티브에서 Flutter로 이벤트를 전달하는 인터페이스
@FlutterApi()
abstract class ViaLinkFlutterApi {
  /// App Link / Universal Link 딥링크 수신 콜백
  void onDeepLink(VLDeepLinkData data);

  /// 디퍼드 딥링크 매칭 결과 콜백
  void onDeferredDeepLink(VLDeepLinkData? data, String? error);
}
