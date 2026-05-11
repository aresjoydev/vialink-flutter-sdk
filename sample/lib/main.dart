import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vialink_flutter_plugin/vialink_flutter_plugin.dart';

/// ViaLink Flutter SDK 샘플 앱 (요구사항정의서 §3 4섹션 구조)
///
/// ⚠️ 테스트 시 주의:
/// - App Links 테스트: URL 끝에 `?mode=developer`를 붙여야 합니다.
///   예: https://vialink.app/flutter/{code}?mode=developer
/// - 디퍼드 딥링크 테스트: 앱을 삭제 후 재설치해야 첫 실행으로 인식됩니다.
const String _kSampleApiKey =
    '30e62e08db556b1ed8dbc15c6a847b310d62d0115f36793ac04ee20c8d9315a1';

/// AlertDialog로 표시할 결과 상태 (spec §4.2 / §4.3)
class ViaLinkResult {
  final String title;
  final String message;
  final String? copyableText;

  const ViaLinkResult({
    required this.title,
    required this.message,
    this.copyableText,
  });
}

/// 진입점 콜백 → UI로 결과를 전달하는 공유 상태 객체 (StreamController, spec §4.3)
class DeepLinkBus {
  DeepLinkBus._();

  static final StreamController<ViaLinkResult> _controller =
      StreamController<ViaLinkResult>.broadcast();

  static Stream<ViaLinkResult> get stream => _controller.stream;

  static void post(ViaLinkResult result) {
    if (!_controller.isClosed) {
      _controller.add(result);
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // SDK 초기화 (spec §2.1)
  await ViaLinkSDK.instance.configure(apiKey: _kSampleApiKey);
  debugPrint('[ViaLink] SDK 초기화 완료');

  // 진입점에서 콜백 등록 → UI는 Stream으로 구독 (spec §2.2 / §2.3 / §4.3)
  ViaLinkSDK.instance.onDeepLink((data) {
    debugPrint('[ViaLink] DeepLink: path=${data.path} params=${data.params}');
    DeepLinkBus.post(ViaLinkResult(
      title: '딥링크 진입',
      message: _formatDeepLinkData(data),
      copyableText: data.shortCode,
    ));
  });

  ViaLinkSDK.instance.onDeferredDeepLink((data, error) {
    if (error != null) {
      debugPrint('[ViaLink] Deferred error: $error');
      DeepLinkBus.post(ViaLinkResult(
        title: '디퍼드 매칭 실패',
        message: error,
      ));
    } else if (data != null) {
      debugPrint('[ViaLink] Deferred matched: path=${data.path} linkId=${data.linkId}');
      DeepLinkBus.post(ViaLinkResult(
        title: '디퍼드 딥링크 매칭',
        message: _formatDeepLinkData(data),
        copyableText: data.shortCode,
      ));
    } else {
      debugPrint('[ViaLink] Organic install (no match)');
      DeepLinkBus.post(const ViaLinkResult(
        title: '디퍼드 딥링크',
        message: '매칭 결과 없음 (organic install)',
      ));
    }
  });

  runApp(const ViaLinkSampleApp());
}

String _formatDeepLinkData(DeepLinkData data) {
  final lines = <String>['path: ${data.path}'];
  if (data.shortCode != null) lines.add('shortCode: ${data.shortCode}');
  if (data.linkId != null) lines.add('linkId: ${data.linkId}');
  if (data.params.isNotEmpty) {
    lines.add('params:');
    final sorted = data.params.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    for (final e in sorted) {
      lines.add('  ${e.key}: ${e.value}');
    }
  }
  return lines.join('\n');
}

class ViaLinkSampleApp extends StatelessWidget {
  const ViaLinkSampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ViaLink SDK Sample',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1976D2),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  StreamSubscription<ViaLinkResult>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = DeepLinkBus.stream.listen((result) {
      if (!mounted) return;
      _showResultDialog(result);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  // ──────────────────────────────────────────────
  // UI helpers
  // ──────────────────────────────────────────────

  void _toast(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.removeCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(milliseconds: 1500)),
    );
  }

  Future<void> _showResultDialog(ViaLinkResult result) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(result.title),
        content: SingleChildScrollView(
          child: Text(
            result.message,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          ),
        ),
        actions: [
          if (result.copyableText != null)
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: result.copyableText!));
                Navigator.of(ctx).pop();
                _toast('📋 링크가 복사되었습니다');
              },
              child: const Text('복사하기'),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Section 1: 이벤트 추적 (spec §3.3 표 1)
  // ──────────────────────────────────────────────

  void _trackSignup() {
    ViaLinkSDK.instance.track('signup');
    debugPrint('[ViaLink] track signup');
    _toast('✅ 회원가입 이벤트 전송 완료');
  }

  void _trackPurchase() {
    ViaLinkSDK.instance.track('purchase', data: const {
      'product_id': 'PROD-001',
      'revenue': '29900',
      'currency': 'KRW',
    });
    debugPrint('[ViaLink] track purchase');
    _toast('✅ 구매 이벤트 전송 완료');
  }

  void _trackAddToCart() {
    ViaLinkSDK.instance.track('add_to_cart', data: const {
      'product_id': 'PROD-001',
    });
    debugPrint('[ViaLink] track add_to_cart');
    _toast('✅ 장바구니 추가 이벤트 전송 완료');
  }

  // ──────────────────────────────────────────────
  // Section 2: 링크 생성
  // ──────────────────────────────────────────────

  Future<void> _createLink({
    required String linkType,
    required String path,
    String? campaign,
  }) async {
    _toast('🔗 $linkType 링크 생성 요청 중…');
    try {
      final url = await ViaLinkSDK.instance.createLink(
        path: path,
        data: const {'source': 'flutter_sample'},
        campaign: campaign,
        linkType: linkType,
      );
      debugPrint('[ViaLink] createLink $linkType → $url');
      DeepLinkBus.post(ViaLinkResult(
        title: '링크 생성 성공',
        message: 'type: $linkType\npath: $path\nurl: $url',
        copyableText: url,
      ));
    } catch (e) {
      debugPrint('[ViaLink] createLink failed: $e');
      DeepLinkBus.post(ViaLinkResult(
        title: '링크 생성 실패',
        message: e.toString(),
      ));
    }
  }

  // ──────────────────────────────────────────────
  // Section 3: Pull API (spec §3.3 표 3)
  // ──────────────────────────────────────────────

  Future<void> _pullDeepLinkSync() async {
    final data = await ViaLinkSDK.instance.getDeepLinkData();
    _showPullResult('딥링크 (Sync)', data);
  }

  Future<void> _pullDeferredSync() async {
    final data = await ViaLinkSDK.instance.getDeferredLinkData();
    _showPullResult('디퍼드 (Sync)', data);
  }

  Future<void> _awaitDeepLink() async {
    _toast('⏳ 딥링크 대기 중…');
    final data = await ViaLinkSDK.instance.awaitDeepLinkData();
    _showPullResult('딥링크 (Await)', data);
  }

  Future<void> _awaitDeferred() async {
    _toast('⏳ 디퍼드 매칭 대기 중…');
    final data = await ViaLinkSDK.instance.awaitDeferredLinkData();
    _showPullResult('디퍼드 (Await)', data);
  }

  void _showPullResult(String title, DeepLinkData? data) {
    if (data != null) {
      DeepLinkBus.post(ViaLinkResult(
        title: title,
        message: _formatDeepLinkData(data),
        copyableText: data.shortCode,
      ));
    } else {
      DeepLinkBus.post(ViaLinkResult(
        title: title,
        message: '수신/캐시된 데이터가 없습니다 (null)',
      ));
    }
  }

  // ──────────────────────────────────────────────
  // Section 4: 결제 추적
  // ──────────────────────────────────────────────

  Future<void> _initiatePayment() async {
    _toast('💳 결제 시도 요청 중…');
    final orderId = 'ORDER-${DateTime.now().millisecondsSinceEpoch}';
    try {
      final result = await ViaLinkSDK.instance.trackPayment(
        orderId: orderId,
        amount: 29900,
        currency: 'KRW',
        paymentMethod: 'card',
        metadata: const {'user_tier': 'gold', 'channel': 'flutter_sample'},
      );
      debugPrint(
          '[ViaLink] trackPayment success=${result.success} eventId=${result.paymentEventId}');
      DeepLinkBus.post(ViaLinkResult(
        title: '결제 시도 결과',
        message: 'success: ${result.success}\n'
            'paymentEventId: ${result.paymentEventId}\n'
            'orderId: $orderId',
      ));
    } catch (e) {
      debugPrint('[ViaLink] trackPayment failed: $e');
      DeepLinkBus.post(ViaLinkResult(
        title: '결제 시도 실패',
        message: e.toString(),
      ));
    }
  }

  // ──────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('ViaLink SDK Sample'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _statusCard(cs),
          const SizedBox(height: 16),
          _section('1. 이벤트 추적', [
            _button('회원가입 이벤트 전송', _trackSignup),
            _button('구매 이벤트 전송', _trackPurchase),
            _button('장바구니 추가 이벤트 전송', _trackAddToCart),
          ]),
          const Divider(height: 32),
          _section('2. 링크 생성', [
            _button('딥링크 생성 (referral, dynamic)',
                () => _createLink(linkType: 'dynamic', path: '/product/12345', campaign: 'referral')),
            _button('정적 링크 생성 (notice, static)',
                () => _createLink(linkType: 'static', path: '/static/notice/123')),
          ]),
          const Divider(height: 32),
          _section('3. 데이터 가져오기 (Pull API)', [
            _button('딥링크 가져오기 (Sync)', _pullDeepLinkSync),
            _button('딥링크 대기 (Async)', _awaitDeepLink),
            _button('디퍼드 딥링크 (Sync)', _pullDeferredSync),
            _button('디퍼드 딥링크 대기 (Async)', _awaitDeferred),
          ]),
          const Divider(height: 32),
          _section('4. 결제 추적', [
            _button('결제 시도 (initiated)', _initiatePayment),
          ]),
          const Divider(height: 32),
          _bottomInfoCard(cs),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _statusCard(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('SDK 상태', style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text('Initialized', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          Row(children: [
            Text('API Key', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
            const Spacer(),
            Text('${_kSampleApiKey.substring(0, 8)}…',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
          ]),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        ...children.map((c) => Padding(padding: const EdgeInsets.only(bottom: 8), child: c)),
      ],
    );
  }

  Widget _button(String label, VoidCallback onPressed) {
    return FilledButton.tonal(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      child: Text(label),
    );
  }

  Widget _bottomInfoCard(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('정보', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('• 딥링크/디퍼드 결과는 AlertDialog로 표시됩니다.',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          Text('• 콘솔 로그 태그: [ViaLink]',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          Text('• 이벤트는 30초마다 배치 전송됩니다.',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}
