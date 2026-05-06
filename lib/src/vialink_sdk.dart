import 'dart:async';
import 'package:flutter/widgets.dart';
import 'vialink_method_channel.dart';
import 'models/deep_link_data.dart';
import 'models/deferred_error.dart';
import 'models/payment_event.dart';

export 'models/deferred_error.dart';

/// ViaLink Flutter SDK
///
/// 딥링크 라우팅, 디퍼드 딥링킹, 이벤트 추적을 제공합니다.
///
/// ```dart
/// await ViaLinkSDK.instance.configure(apiKey: 'YOUR_API_KEY');
///
/// ViaLinkSDK.instance.onDeepLink((data) {
///   Navigator.pushNamed(context, data.path);
/// });
/// ```
class ViaLinkSDK {
  ViaLinkSDK._();
  static final ViaLinkSDK instance = ViaLinkSDK._();

  final _channel = ViaLinkMethodChannel();
  StreamSubscription? _deepLinkSub;
  StreamSubscription? _deferredSub;

  /// 결제 추적 namespace. `ViaLinkSDK.instance.payment.initiated(args)` 형태로 사용.
  late final PaymentApi payment = PaymentApi(_channel);

  /// SDK 초기화
  Future<void> configure({required String apiKey}) async {
    await _channel.configure(apiKey: apiKey);
    debugPrint('[ViaLink] SDK 초기화 완료');
  }

  /// 딥링크 콜백 등록
  void onDeepLink(void Function(DeepLinkData data) callback) {
    _deepLinkSub?.cancel();
    _deepLinkSub = _channel.deepLinkStream.listen((map) {
      callback(DeepLinkData.fromMap(map));
    });
  }

  /// 디퍼드 딥링크 콜백 등록
  ///
  /// 앱 첫 실행 시 매칭 결과가 결정되는 즉시 항상 1회 호출됩니다.
  /// 5초 안에 결과가 결정되지 않으면 `error.code == 'timeout'`으로 호출됩니다.
  ///
  /// ```dart
  /// ViaLinkSDK.instance.onDeferredDeepLink((data, error) {
  ///   if (error != null) {
  ///     // 매칭 실패 (timeout/network/server_error 등) — 일반 진입
  ///     return;
  ///   }
  ///   if (data == null) {
  ///     // organic install — 일반 진입
  ///     return;
  ///   }
  ///   Navigator.pushNamed(context, data.path, arguments: data.params);
  /// });
  /// ```
  ///
  /// 콜백은 멱등성을 보장합니다 (총 1회 호출).
  /// `error.retryable`이 true면 다음 앱 실행에서 자동 재시도되며, 그 경우 사용자가 앱을 사용 중일 때 콜백이 도착할 수 있습니다.
  void onDeferredDeepLink(
    void Function(DeepLinkData? data, DeferredError? error) callback,
  ) {
    _deferredSub?.cancel();
    _deferredSub = _channel.deferredDeepLinkStream.listen((event) {
      final rawData = event['data'];
      final rawError = event['error'];
      final data = rawData != null
          ? DeepLinkData.fromMap(Map<String, dynamic>.from(rawData as Map))
          : null;
      final error = rawError != null
          ? DeferredError.fromMap(Map<String, dynamic>.from(rawError as Map))
          : null;
      callback(data, error);
    });
  }

  /// 커스텀 이벤트 추적
  void track(String eventName, {Map<String, dynamic>? data}) {
    _channel.track(eventName, data: data);
  }

  /// 딥링크 생성
  ///
  /// [path] 딥링크 경로 (예: `/product/12345`)
  /// [data] 딥링크에 첨부할 커스텀 데이터
  /// [campaign] 마케팅 캠페인 식별자
  /// [linkType] 링크 유형.
  ///   - `'static'` (기본값): 단순 URL 리다이렉트만 수행하는 정적 링크.
  ///   - `'dynamic'`: 앱 설치 여부에 따라 앱 또는 스토어로 분기하는 동적 링크.
  ///
  /// [iosUrl]/[androidUrl]/[webUrl]: 폴백 URL (앱 미설치 시 또는 비대상 플랫폼에서 사용).
  /// [ogTitle]/[ogDescription]/[ogImageUrl]: 링크 미리보기 OG 메타태그.
  /// [channel]/[feature]: 어트리뷰션 분류 (예: `'email'`, `'product_share'`).
  /// [tags]: 분류용 태그 배열.
  /// [expiresAt]: 만료일 (ISO 8601, 예: `'2026-12-31T23:59:59Z'`).
  Future<String> createLink({
    required String path,
    Map<String, dynamic>? data,
    String? campaign,
    String linkType = 'static',
    String? iosUrl,
    String? androidUrl,
    String? webUrl,
    String? ogTitle,
    String? ogDescription,
    String? ogImageUrl,
    String? channel,
    String? feature,
    List<String>? tags,
    String? expiresAt,
  }) {
    return _channel.createLink(
      path: path,
      data: data,
      campaign: campaign,
      linkType: linkType,
      iosUrl: iosUrl,
      androidUrl: androidUrl,
      webUrl: webUrl,
      ogTitle: ogTitle,
      ogDescription: ogDescription,
      ogImageUrl: ogImageUrl,
      channel: channel,
      feature: feature,
      tags: tags,
      expiresAt: expiresAt,
    );
  }

  /// SDK 정리
  void dispose() {
    _deepLinkSub?.cancel();
    _deferredSub?.cancel();
    _channel.dispose();
  }
}
