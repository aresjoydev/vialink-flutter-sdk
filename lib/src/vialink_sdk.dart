import 'dart:async';
import 'package:flutter/widgets.dart';
import 'vialink_method_channel.dart';
import 'models/deep_link_data.dart';

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
  void onDeferredDeepLink(void Function(DeepLinkData data) callback) {
    _deferredSub?.cancel();
    _deferredSub = _channel.deferredDeepLinkStream.listen((map) {
      callback(DeepLinkData.fromMap(map));
    });
  }

  /// 커스텀 이벤트 추적
  void track(String eventName, {Map<String, dynamic>? data}) {
    _channel.track(eventName, data: data);
  }

  /// 딥링크 생성
  Future<String> createLink({
    required String path,
    Map<String, dynamic>? data,
    String? campaign,
  }) {
    return _channel.createLink(path: path, data: data, campaign: campaign);
  }

  /// SDK 정리
  void dispose() {
    _deepLinkSub?.cancel();
    _deferredSub?.cancel();
    _channel.dispose();
  }
}
