## 3.2.9

- Flutter 플러그인 업데이트 (기능 개선 및 버그 수정)

## 3.2.8

- iOS SDK v3.0.15 바이너리 업데이트

## 3.2.7

- iOS SDK v3.0.14 dedup 보정 — `flushPendingDeepLinks` 재처리 경로가 dedup 에 잘못 막혀 cold start 시 콜백이 발사되지 않던 문제 fix
- 3.2.6 은 dedup 도입은 됐으나 flush 차단 버그가 있어 cold start 시나리오에서 onDeepLink 미발사 → 3.2.7 로 교체 권장

## 3.2.6

- iOS SDK v3.0.14 바이너리 업데이트 — SceneDelegate 환경 중복 dispatch 차단

## 3.2.5

- iOS SDK v3.0.13 바이너리 업데이트

## 3.2.4

- iOS SDK v3.0.12 바이너리 업데이트

## 3.2.3

- iOS SDK v3.0.11 바이너리 업데이트
- Android SDK v3.2.18 바이너리 업데이트

## 3.2.2

- Flutter 플러그인 업데이트 (기능 개선 및 버그 수정)

## 3.2.1

- Flutter 플러그인 업데이트 (기능 개선 및 버그 수정)

## 2.0.3

- Flutter 플러그인 업데이트 (기능 개선 및 버그 수정)

## 2.0.2

- Flutter 플러그인 업데이트 (기능 개선 및 버그 수정)

## 2.0.1

- iOS SDK v3.0.10 바이너리 업데이트

## 2.0.0

### ⚠️ Breaking Change: 네이티브 SDK 기반 브릿지 플러그인으로 전면 재설계

- **아키텍처 전환**: Dart 비즈니스 로직 → 네이티브 SDK(AAR/XCFramework) 브릿지
- **Pigeon 도입**: Flutter ↔ Native 통신을 타입-안전 코드 생성으로 처리
- **패키지명 변경**: `vialink_flutter_sdk` → `vialink_flutter_plugin`
- **콜백 분리**: `onDeepLink` / `onDeferredDeepLink` 완전 분리 (Android SDK v3.2.x 아키텍처 동기화)
- **Pending Cache**: 콜백 미등록 시 네이티브에서 결과 캐시 → 등록 시 즉시 flush
- **Pull API 추가**: `getDeepLinkData()`, `getDeferredLinkData()`, `awaitDeepLinkData()`, `awaitDeferredLinkData()`
- **결제 추적**: `trackPayment()` API 추가 (POST /v1/payments/initiated)
- **링크 생성 확장**: `createLink()`에 OG 메타, 채널, 태그 등 전체 옵션 지원
- **의존성 제거**: `http`, `shared_preferences`, `device_info_plus`, `app_links` 모두 제거

### 삭제된 클래스 (네이티브에 위임)
- `NetworkClient`, `DeepLinkHandler`, `DeferredMatcher`
- `EventTracker`, `DeviceInfoCollector`, `ViaLinkStorage`
- `DeviceInfoData`, `EventPayload`

## 1.0.5

- 딥링크 자동 수신 추가 (app_links) — 콜드 스타트 + 실행 중 수신 모두 자동 처리
- 개발자가 handleUri()를 수동 호출할 필요 없음
- URL 파싱을 /{slug}/{code} 형식으로 변경 (구형 /c/{code} 제거)
- app_links 의존성 추가

## 1.0.4

- Android 디퍼드 딥링킹 핑거프린트 불일치 수정 (Platform.operatingSystemVersion → device_info_plus)
- Android에서 빌드번호 대신 실제 OS 버전(Build.VERSION.RELEASE) 사용
- device_info_plus 의존성 추가
- 디바이스 모델명을 실제 기기 모델로 변경

## 1.0.3

- API 기본 도메인을 실제 프로덕션 URL로 변경 (your-domain.com -> vialink.memi.me)
- User-Agent 버전 업데이트 (1.0.0 -> 1.0.2)

## 1.0.2

- README.md Usage 섹션을 docs 페이지와 동기화
- .pubignore 추가 (빌드 캐시 제외)

## 1.0.1

- DeepLinkHandler: GET /api/links/by-code/ -> POST /v1/resolve 변경
- NetworkClient.createLink: 요청 필드명 deeplink_path/deeplink_data로 통일
- README.md 업데이트 (pub.dev 랜딩 페이지 반영)
- LICENSE MIT 라이선스 적용

## 1.0.0

- 초기 릴리스
- 딥링크 라우팅 (App Links / Universal Links)
- 디퍼드 딥링킹 (fingerprint 매칭)
- 이벤트 추적 (배치 전송)
- 링크 생성 API
- POST /v1/resolve 딥링크 조회 지원
