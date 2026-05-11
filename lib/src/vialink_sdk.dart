import 'package:flutter/widgets.dart';
import 'generated/messages.g.dart';
import 'models/deep_link_data.dart';
import 'models/payment_result.dart';

/// ViaLink Flutter SDK
///
/// 네이티브 SDK(AAR/XCFramework) 기반 브릿지 플러그인입니다.
/// 모든 비즈니스 로직은 네이티브 SDK에 위임하고,
/// Flutter 측은 Pigeon 타입-안전 채널을 통한 래퍼만 제공합니다.
///
/// ```dart
/// // 1. 초기화
/// await ViaLinkSDK.instance.configure(apiKey: 'YOUR_API_KEY');
///
/// // 2. 콜백 등록 (init 전후 무관 — 미등록 시 네이티브에서 캐시)
/// ViaLinkSDK.instance.onDeepLink((data) {
///   Navigator.pushNamed(context, data.path);
/// });
/// ViaLinkSDK.instance.onDeferredDeepLink((data, error) {
///   if (data != null) Navigator.pushNamed(context, data.path);
/// });
///
/// // 3. Pull API
/// final deferred = await ViaLinkSDK.instance.awaitDeferredLinkData();
/// final last = ViaLinkSDK.instance.getDeepLinkData();
///
/// // 4. 이벤트 추적
/// ViaLinkSDK.instance.track('purchase', data: {'revenue': '29900'});
/// ```
class ViaLinkSDK {
  // 싱글턴
  ViaLinkSDK._internal();
  static final ViaLinkSDK instance = ViaLinkSDK._internal();

  final ViaLinkHostApi _hostApi = ViaLinkHostApi();
  bool _flutterApiRegistered = false;

  // 콜백
  void Function(DeepLinkData data)? _deepLinkCallback;
  void Function(DeepLinkData? data, String? error)? _deferredCallback;

  /// SDK 초기화 — main.dart 또는 App Widget에서 호출
  ///
  /// 네이티브 SDK의 `init()`/`configure()`를 호출합니다.
  /// 내부적으로 디퍼드 딥링크 매칭, 이벤트 추적 타이머 등이 시작됩니다.
  Future<void> configure({required String apiKey}) async {
    // FlutterApi 등록 (네이티브 → Flutter 콜백 수신)
    if (!_flutterApiRegistered) {
      ViaLinkFlutterApi.setUp(_ViaLinkFlutterApiHandler(this));
      _flutterApiRegistered = true;
    }
    _hostApi.configure(apiKey);
    debugPrint('[ViaLink] Flutter SDK 초기화 완료');
  }

  /// 딥링크 수신 콜백 등록
  ///
  /// App Link / Universal Link로 앱이 실행되었을 때 호출됩니다.
  /// init 전에 등록해도 됩니다 — 결과가 먼저 도착하면 네이티브에서 캐시했다가 등록 시 즉시 전달합니다.
  ///
  /// ```dart
  /// ViaLinkSDK.instance.onDeepLink((data) {
  ///   Navigator.pushNamed(context, data.path);
  /// });
  /// ```
  void onDeepLink(void Function(DeepLinkData data) callback) {
    _deepLinkCallback = callback;
  }

  /// 디퍼드 딥링크 콜백 등록
  ///
  /// 첫 실행 시 매칭 결과가 결정되면 1회 호출됩니다.
  /// `data == null && error == null`이면 organic install입니다.
  ///
  /// ```dart
  /// ViaLinkSDK.instance.onDeferredDeepLink((data, error) {
  ///   if (error != null) { /* 매칭 실패 */ return; }
  ///   if (data != null) Navigator.pushNamed(context, data.path);
  ///   // else: organic install
  /// });
  /// ```
  void onDeferredDeepLink(
    void Function(DeepLinkData? data, String? error) callback,
  ) {
    _deferredCallback = callback;
  }

  /// URL 기반 딥링크 수동 처리
  ///
  /// 일반적으로 네이티브 SDK가 자동 처리하므로 호출 불필요합니다.
  /// SwiftUI onOpenURL 등에서 수동으로 전달해야 하는 경우에 사용합니다.
  void handleDeepLink(String url) {
    _hostApi.handleDeepLink(url);
  }

  // ──────────────────────────────────────────────
  // Pull API
  // ──────────────────────────────────────────────

  /// 마지막으로 수신된 딥링크 데이터
  ///
  /// handleIntent()를 통해 수신된 가장 최근 딥링크 데이터입니다.
  /// 수신된 적이 없으면 null을 반환합니다.
  Future<DeepLinkData?> getDeepLinkData() async {
    final pigeon = await _hostApi.getDeepLinkData();
    return pigeon?.toDart();
  }

  /// 디퍼드 매칭 결과 캐시
  ///
  /// 매칭이 아직 완료되지 않았으면 null을 반환합니다.
  Future<DeepLinkData?> getDeferredLinkData() async {
    final pigeon = await _hostApi.getDeferredLinkData();
    return pigeon?.toDart();
  }

  /// 딥링크 도착까지 대기 (3초 타임아웃)
  ///
  /// 이미 수신된 경우 즉시 반환합니다.
  /// ⚠️ App Link 없이 앱이 열리면 3초 후 null 반환 — withTimeout 없이 안전합니다.
  Future<DeepLinkData?> awaitDeepLinkData() async {
    final pigeon = await _hostApi.awaitDeepLinkData();
    return pigeon?.toDart();
  }

  /// 디퍼드 매칭 결과까지 대기
  ///
  /// 앱 첫 실행 시 서버 매칭 결과가 결정될 때까지 대기합니다.
  /// 이미 결과가 결정된 경우 즉시 반환합니다.
  Future<DeepLinkData?> awaitDeferredLinkData() async {
    final pigeon = await _hostApi.awaitDeferredLinkData();
    return pigeon?.toDart();
  }

  // ──────────────────────────────────────────────
  // 이벤트 추적
  // ──────────────────────────────────────────────

  /// 커스텀 이벤트 추적
  ///
  /// ```dart
  /// ViaLinkSDK.instance.track('purchase', data: {'product_id': '123', 'revenue': '29900'});
  /// ```
  void track(String eventName, {Map<String, String>? data}) {
    _hostApi.track(eventName, data);
  }

  // ──────────────────────────────────────────────
  // 링크 생성
  // ──────────────────────────────────────────────

  /// 앱 내에서 딥링크 생성
  ///
  /// ```dart
  /// final url = await ViaLinkSDK.instance.createLink(
  ///   path: '/product/123',
  ///   data: {'promo_code': 'FRIEND'},
  ///   campaign: 'referral',
  /// );
  /// ```
  Future<String> createLink({
    required String path,
    Map<String, String>? data,
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
  }) async {
    final args = VLCreateLinkArgs(
      path: path,
      linkType: linkType,
      data: data,
      campaign: campaign,
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
    return _hostApi.createLink(args);
  }

  // ──────────────────────────────────────────────
  // 결제 추적
  // ──────────────────────────────────────────────

  /// 결제 시도 기록
  ///
  /// 결제창을 띄우기 직전에 호출합니다. 즉시 전송(배치 X).
  ///
  /// ```dart
  /// final result = await ViaLinkSDK.instance.trackPayment(
  ///   orderId: 'ORD-2026-0001',
  ///   amount: 19900,
  ///   currency: 'KRW',
  ///   paymentMethod: 'card',
  /// );
  /// ```
  Future<PaymentResult> trackPayment({
    required String orderId,
    required double amount,
    required String currency,
    int? linkId,
    String? paymentMethod,
    Map<String, String>? metadata,
  }) async {
    final args = VLPaymentArgs(
      orderId: orderId,
      amount: amount,
      currency: currency,
      linkId: linkId,
      paymentMethod: paymentMethod,
      metadata: metadata,
    );
    final pigeon = await _hostApi.trackPayment(args);
    return PaymentResult(
      success: pigeon.success,
      paymentEventId: pigeon.paymentEventId,
    );
  }
}

// ──────────────────────────────────────────────
// FlutterApi 구현 — 네이티브 → Flutter 콜백 수신
// ──────────────────────────────────────────────

class _ViaLinkFlutterApiHandler implements ViaLinkFlutterApi {
  final ViaLinkSDK _sdk;
  _ViaLinkFlutterApiHandler(this._sdk);

  @override
  void onDeepLink(VLDeepLinkData data) {
    final dartData = data.toDart();
    _sdk._deepLinkCallback?.call(dartData);
  }

  @override
  void onDeferredDeepLink(VLDeepLinkData? data, String? error) {
    final dartData = data?.toDart();
    _sdk._deferredCallback?.call(dartData, error);
  }
}

// ──────────────────────────────────────────────
// Pigeon → Dart 모델 변환 extension
// ──────────────────────────────────────────────

extension _VLDeepLinkDataToDart on VLDeepLinkData {
  DeepLinkData toDart() {
    final dartParams = <String, String>{};
    params?.forEach((key, value) {
      if (key != null && value != null) {
        dartParams[key] = value;
      }
    });
    return DeepLinkData(
      path: path,
      params: dartParams,
      shortCode: shortCode,
      linkId: linkId,
    );
  }
}
