## 2.1.0

- `ViaLinkSDK.instance.payment.initiated(args)` Dart API 추가 (결제 시도 추적)
- Android plugin: `paymentInitiated` MethodChannel handler + native `ViaLinkSDK.payment.initiated` 브리지 (Android SDK 1.1.1)
- iOS plugin: `paymentInitiated` MethodChannel handler + native `ViaLinkSDK.shared.payment.initiated` 브리지 (iOS SDK 1.1.1)
- `PaymentInitiatedArgs`, `PaymentInitiatedResult`, `PaymentApi` 모델/클래스 export

## 2.0.9

- iOS SDK v1.0.8 바이너리 업데이트

## 2.0.8

- Android SDK v1.0.15 바이너리 업데이트

## 2.0.7

- iOS SDK v1.0.7 바이너리 업데이트

## 2.0.6

- iOS xcframework Modules 포함 (import ViaLinkCore 수정)

## 2.0.5

- iOS SDK v1.0.6 바이너리 업데이트

## 2.0.4

- Android SDK v1.0.13 바이너리 업데이트

## 2.0.3

- Android SDK v1.0.12 바이너리 업데이트 (딥링크 URL 파싱 수정 + fp 직접 매칭)
- 딥링크 /v1/resolve 요청이 누락되던 문제 수정

## 2.0.2

- AndroidManifest.xml에서 deprecated package 속성 제거 (AGP 8.x 호환)
- fp 파라미터 디퍼드 딥링크 직접 매칭 지원 (네이티브 SDK 업데이트)

## 2.0.1

- Android SDK v1.0.8 + iOS SDK v2.0.1 바이너리 업데이트
- API 도메인 vialink.app 반영

## 2.0.0

- Flutter Plugin 아키텍처로 전환 (네이티브 바이너리 기반)
- Dart 비즈니스 로직 제거 — MethodChannel 인터페이스만 제공
- Android: .aar 바이너리 포함 (소스코드 비공개)
- iOS: .xcframework 바이너리 포함 (소스코드 비공개)
- 외부 Dart 의존성 완전 제거 (app_links, device_info_plus, http, shared_preferences)
- 딥링크 자동 수신 (Android Intent / iOS Universal Link 네이티브 처리)
