import 'package:flutter/services.dart';

/// MethodChannel / EventChannel 통신 레이어
class ViaLinkMethodChannel {
  static const _method = MethodChannel('com.vialink.sdk/methods');
  static const _deepLinks = EventChannel('com.vialink.sdk/deeplinks');
  static const _deferred = EventChannel('com.vialink.sdk/deferred');

  Future<void> configure({required String apiKey}) {
    return _method.invokeMethod('configure', {'apiKey': apiKey});
  }

  void track(String eventName, {Map<String, dynamic>? data}) {
    _method.invokeMethod('track', {'eventName': eventName, 'data': data});
  }

  Future<String> createLink({
    required String path,
    Map<String, dynamic>? data,
    String? campaign,
  }) async {
    final result = await _method.invokeMethod<String>(
      'createLink',
      {'path': path, 'data': data, 'campaign': campaign},
    );
    return result!;
  }

  Stream<Map<String, dynamic>> get deepLinkStream =>
      _deepLinks.receiveBroadcastStream().map(
            (event) => Map<String, dynamic>.from(event as Map),
          );

  Stream<Map<String, dynamic>> get deferredDeepLinkStream =>
      _deferred.receiveBroadcastStream().map(
            (event) => Map<String, dynamic>.from(event as Map),
          );

  Future<void> dispose() => _method.invokeMethod('dispose');
}
