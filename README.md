# ViaLink Flutter Plugin

ViaLink 딥링크 인프라 서비스를 위한 Flutter Plugin입니다.

## Features

- **딥링크 자동 수신** - App Links / Universal Links 자동 캡처
- **디퍼드 딥링킹** - 앱 미설치 → 설치 후 원래 딥링크로 이동
- **이벤트 추적** - 커스텀 이벤트 배치 전송
- **링크 생성** - 앱 내 공유용 단축 딥링크 생성

## Usage

```dart
import 'package:vialink_flutter_plugin/vialink_flutter_plugin.dart';

// 초기화
await ViaLinkSDK.instance.configure(apiKey: 'YOUR_API_KEY');

// 딥링크 콜백
ViaLinkSDK.instance.onDeepLink((data) {
  Navigator.pushNamed(context, data.path, arguments: data.params);
});

// 디퍼드 딥링크 콜백
ViaLinkSDK.instance.onDeferredDeepLink((data) {
  Navigator.pushNamed(context, data.path, arguments: data.params);
});

// 이벤트 추적
ViaLinkSDK.instance.track('purchase', data: {'revenue': 29900});

// 링크 생성
final url = await ViaLinkSDK.instance.createLink(path: '/product/123');
```

## Additional information

- [SDK 가이드 문서](https://docs.vialink.app)
