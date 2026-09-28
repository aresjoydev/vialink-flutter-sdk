# ViaLink Flutter SDK

[![ViaLink — Deep links for 6 platforms. Start free.](docs/banner-en.png)](https://vialink.app/?utm_source=github&utm_medium=readme&utm_campaign=flutter-sdk)

**English** | [한국어](README.ko.md)

ViaLink deep link SDK for Flutter — a bridge plugin built on the native SDKs (AAR/XCFramework).

Built as a bridge over the native Android and iOS SDKs, so a single Dart codebase
handles deep linking and deferred deep linking on both platforms. Users who install from
a link land on the intended screen at first launch, and click, install, open, event, and
payment flow through one attribution pipeline.

Unlike most deep link and attribution tools, which require a sales call and an annual
contract, **ViaLink is free to start.** No credit card — all six platform SDKs are
available the moment you sign up.

**→ [vialink.app](https://vialink.app/?utm_source=github&utm_medium=readme&utm_campaign=flutter-sdk)**

## Opens the app from in-app browsers, too

Links shared on KakaoTalk, Naver, LINE, Instagram, or Threads open in the app's built-in
browser, where Universal Links and App Links often don't fire. ViaLink's link server
detects the in-app browser and takes the route that works there:

- **KakaoTalk · Naver · LINE (iOS)** — hands the link off to Safari automatically, so the Universal Link fires
- **Android in-app browsers** — launches the app with an `intent://` URL, falling back to the store if it isn't installed
- **Instagram · Facebook · Threads and others** — tries your app's custom URL scheme (if registered) and shows an "Open in external browser" guide as a backup

This runs on the link server — no extra SDK code needed.

## Features

- **Deep link routing** — automatic handling of App Links / Universal Links
- **Deferred deep linking** — fingerprint-based matching on the first launch after install
- **Event tracking** — batched delivery of custom events
- **Payment attribution** — records payment attempts and automatically attaches `link_id`
- **Link creation** — generate deep links from within the app (static/dynamic)

## Installation

```yaml
dependencies:
  vialink_flutter_plugin: ^3.2.16
```

## Usage

### 1. Initialization

```dart
import 'package:vialink_flutter_plugin/vialink_flutter_plugin.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ViaLinkSDK.instance.configure(apiKey: 'YOUR_API_KEY');
  runApp(MyApp());
}
```

### 2. Deep link callbacks

```dart
// Receive App Links / Universal Links
ViaLinkSDK.instance.onDeepLink((data) {
  Navigator.pushNamed(context, data.path);
  print('params: ${data.params}');
});

// Deferred deep link (matched after the first install)
ViaLinkSDK.instance.onDeferredDeepLink((data, error) {
  if (error != null) {
    print('deferred match failed: ${error.message}');
    return;
  }
  if (data != null) {
    print('deferred match succeeded: ${data.path}');
    Navigator.pushNamed(context, data.path);
  } else {
    print('no match (organic install)');
  }
});
```

### 3. Pull API

```dart
// Synchronous (returns the cached value immediately)
final deepLink = ViaLinkSDK.instance.getDeepLinkData();
final deferred = ViaLinkSDK.instance.getDeferredLinkData();

// Asynchronous (waits until the result arrives)
final deepLinkAsync = await ViaLinkSDK.instance.awaitDeepLinkData();    // 3-second timeout
final deferredAsync = await ViaLinkSDK.instance.awaitDeferredLinkData(); // waits until the result
```

### 4. Event tracking

```dart
ViaLinkSDK.instance.track('purchase', data: {
  'product_id': '123',
  'revenue': '29900',
  'currency': 'KRW',
});
```

### 5. Payment tracking

```dart
final result = await ViaLinkSDK.instance.trackPayment(
  orderId: 'ORD-2026-0001',
  amount: 19900,
  currency: 'KRW',
  paymentMethod: 'card',
);
print('success: ${result.success}, id: ${result.paymentEventId}');
```

### 6. Link creation

```dart
final url = await ViaLinkSDK.instance.createLink(
  path: '/product/123',
  data: {'promo_code': 'FRIEND'},
  campaign: 'referral',
  linkType: 'dynamic', // when click tracking is needed
);
print('created link: $url');
```

## Additional platform setup

### Android setup

Set `minSdkVersion 21` or higher in `android/app/build.gradle`.

### iOS setup

Configure Associated Domains in `ios/Runner/Info.plist`:

```xml
<key>com.apple.developer.associated-domains</key>
<array>
  <string>applinks:vialink.app</string>
</array>
```

## Documentation

- [SDK Guide](https://docs.vialink.app/#sdk-flutter-install)

## License

Proprietary — © 2026 Aresjoy Inc. All rights reserved.
Use is governed by the [ViaLink Terms of Service](https://vialink.app/terms). See [LICENSE](LICENSE).
