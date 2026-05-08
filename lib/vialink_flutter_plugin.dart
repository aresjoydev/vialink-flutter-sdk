/// ViaLink Flutter SDK
///
/// 네이티브 SDK(AAR/XCFramework) 기반 브릿지 플러그인입니다.
/// 딥링크 라우팅, 디퍼드 딥링킹, 이벤트 추적, 결제 어트리뷰션을 제공합니다.
///
/// ```dart
/// import 'package:vialink_flutter_plugin/vialink_flutter_plugin.dart';
///
/// await ViaLinkSDK.instance.configure(apiKey: 'YOUR_API_KEY');
/// ViaLinkSDK.instance.onDeepLink((data) { ... });
/// ViaLinkSDK.instance.track('purchase', data: {'revenue': '29900'});
/// ```
library;

export 'src/vialink_sdk.dart';
export 'src/models/deep_link_data.dart';
export 'src/models/payment_result.dart';
