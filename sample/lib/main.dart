import 'package:flutter/material.dart';
import 'package:vialink_flutter_plugin/vialink_flutter_plugin.dart';

/// ViaLink Flutter SDK 샘플 앱
///
/// ⚠️ 테스트 시 주의:
/// - App Links 테스트: URL 끝에 `?mode=developer`를 붙여야 합니다.
///   예: https://vialink.app/flutter/{code}?mode=developer
/// - 디퍼드 딥링크 테스트: 앱을 삭제 후 재설치해야 첫 실행으로 인식됩니다.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // SDK 초기화
  await ViaLinkSDK.instance.configure(
    apiKey: '30e62e08db556b1ed8dbc15c6a847b310d62d0115f36793ac04ee20c8d9315a1',
  );

  runApp(const ViaLinkSampleApp());
}

class ViaLinkSampleApp extends StatelessWidget {
  const ViaLinkSampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ViaLink Sample',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
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
  final List<_LogEntry> _logs = [];
  DeepLinkData? _lastDeepLink;
  DeepLinkData? _lastDeferred;

  @override
  void initState() {
    super.initState();
    _registerCallbacks();
  }

  void _registerCallbacks() {
    // 딥링크 콜백 등록
    ViaLinkSDK.instance.onDeepLink((data) {
      setState(() {
        _lastDeepLink = data;
        _addLog('🔗 딥링크 수신', _formatDeepLinkData(data));
      });
    });

    // 디퍼드 딥링크 콜백 등록
    ViaLinkSDK.instance.onDeferredDeepLink((data, error) {
      setState(() {
        if (error != null) {
          _addLog('⚠️ 디퍼드 매칭 실패', error);
        } else if (data != null) {
          _lastDeferred = data;
          _addLog('🎯 디퍼드 매칭 성공', _formatDeepLinkData(data));
        } else {
          _addLog('📱 Organic Install', '디퍼드 매칭 결과 없음 (일반 설치)');
        }
      });
    });

    _addLog('✅ SDK 초기화 완료', '콜백 등록됨');
  }

  void _addLog(String title, String detail) {
    _logs.insert(0, _LogEntry(
      title: title,
      detail: detail,
      time: DateTime.now(),
    ));
  }

  String _formatDeepLinkData(DeepLinkData data) {
    final buf = StringBuffer();
    buf.writeln('path: ${data.path}');
    if (data.shortCode != null) buf.writeln('shortCode: ${data.shortCode}');
    if (data.linkId != null) buf.writeln('linkId: ${data.linkId}');
    if (data.params.isNotEmpty) buf.writeln('params: ${data.params}');
    return buf.toString().trimRight();
  }

  // ──────────────────────────────────────────────
  // Pull API 테스트
  // ──────────────────────────────────────────────

  Future<void> _testGetDeepLinkData() async {
    final data = await ViaLinkSDK.instance.getDeepLinkData();
    setState(() {
      if (data != null) {
        _addLog('📋 getDeepLinkData()', _formatDeepLinkData(data));
      } else {
        _addLog('📋 getDeepLinkData()', '캐시된 딥링크 없음 (null)');
      }
    });
  }

  Future<void> _testGetDeferredLinkData() async {
    final data = await ViaLinkSDK.instance.getDeferredLinkData();
    setState(() {
      if (data != null) {
        _addLog('📋 getDeferredLinkData()', _formatDeepLinkData(data));
      } else {
        _addLog('📋 getDeferredLinkData()', '디퍼드 결과 없음 (null)');
      }
    });
  }

  Future<void> _testAwaitDeepLinkData() async {
    _addLog('⏳ awaitDeepLinkData()', '대기 중... (3초 타임아웃)');
    setState(() {});
    final data = await ViaLinkSDK.instance.awaitDeepLinkData();
    setState(() {
      if (data != null) {
        _addLog('✅ awaitDeepLinkData()', _formatDeepLinkData(data));
      } else {
        _addLog('⏰ awaitDeepLinkData()', '타임아웃 (null)');
      }
    });
  }

  Future<void> _testAwaitDeferredLinkData() async {
    _addLog('⏳ awaitDeferredLinkData()', '대기 중...');
    setState(() {});
    final data = await ViaLinkSDK.instance.awaitDeferredLinkData();
    setState(() {
      if (data != null) {
        _addLog('✅ awaitDeferredLinkData()', _formatDeepLinkData(data));
      } else {
        _addLog('📱 awaitDeferredLinkData()', 'null (organic 또는 미매칭)');
      }
    });
  }

  // ──────────────────────────────────────────────
  // 이벤트 추적 테스트
  // ──────────────────────────────────────────────

  void _testTrack() {
    ViaLinkSDK.instance.track('test_event', data: {
      'screen': 'dashboard',
      'timestamp': DateTime.now().toIso8601String(),
    });
    setState(() {
      _addLog('📊 이벤트 전송', 'test_event (screen: dashboard)');
    });
  }

  void _testTrackPurchase() {
    ViaLinkSDK.instance.track('purchase', data: {
      'product_id': 'PROD-001',
      'revenue': '29900',
      'currency': 'KRW',
    });
    setState(() {
      _addLog('💰 구매 이벤트', 'purchase (revenue: 29900 KRW)');
    });
  }

  // ──────────────────────────────────────────────
  // 링크 생성 테스트
  // ──────────────────────────────────────────────

  Future<void> _testCreateLink() async {
    try {
      final url = await ViaLinkSDK.instance.createLink(
        path: '/product/flutter-test',
        data: {'source': 'flutter_sample'},
        campaign: 'flutter_test',
      );
      setState(() {
        _addLog('🔗 링크 생성 성공', url);
      });
    } catch (e) {
      setState(() {
        _addLog('❌ 링크 생성 실패', e.toString());
      });
    }
  }

  Future<void> _testCreateDynamicLink() async {
    try {
      final url = await ViaLinkSDK.instance.createLink(
        path: '/promo/flutter-dynamic',
        data: {'promo_code': 'FLUTTER2025'},
        campaign: 'flutter_dynamic_test',
        linkType: 'dynamic',
        ogTitle: 'Flutter 프로모션',
        ogDescription: 'Flutter SDK 테스트 링크입니다',
      );
      setState(() {
        _addLog('🔗 다이나믹 링크 생성', url);
      });
    } catch (e) {
      setState(() {
        _addLog('❌ 다이나믹 링크 실패', e.toString());
      });
    }
  }

  // ──────────────────────────────────────────────
  // 결제 추적 테스트
  // ──────────────────────────────────────────────

  Future<void> _testTrackPayment() async {
    try {
      final result = await ViaLinkSDK.instance.trackPayment(
        orderId: 'ORD-FLUTTER-${DateTime.now().millisecondsSinceEpoch}',
        amount: 19900,
        currency: 'KRW',
        paymentMethod: 'card',
      );
      setState(() {
        _addLog(
          '💳 결제 기록',
          'success: ${result.success}\npaymentEventId: ${result.paymentEventId}',
        );
      });
    } catch (e) {
      setState(() {
        _addLog('❌ 결제 기록 실패', e.toString());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ViaLink Sample'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => setState(() => _logs.clear()),
            tooltip: '로그 지우기',
          ),
        ],
      ),
      body: Column(
        children: [
          // 상태 카드
          _buildStatusCard(cs),
          const Divider(height: 1),
          // 액션 버튼 그리드
          _buildActionGrid(cs),
          const Divider(height: 1),
          // 로그 리스트
          Expanded(child: _buildLogList(cs)),
        ],
      ),
    );
  }

  Widget _buildStatusCard(ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: cs.surfaceContainerHigh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SDK 상태', style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: cs.onSurfaceVariant,
          )),
          const SizedBox(height: 8),
          Row(
            children: [
              _statusChip('DeepLink', _lastDeepLink != null, cs),
              const SizedBox(width: 8),
              _statusChip('Deferred', _lastDeferred != null, cs),
            ],
          ),
          if (_lastDeepLink != null) ...[
            const SizedBox(height: 4),
            Text(
              '마지막 딥링크: ${_lastDeepLink!.path}',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusChip(String label, bool active, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? cs.primaryContainer : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14,
            color: active ? cs.primary : cs.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(
            fontSize: 12,
            color: active ? cs.onPrimaryContainer : cs.onSurfaceVariant,
          )),
        ],
      ),
    );
  }

  Widget _buildActionGrid(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _actionButton('Pull: DeepLink', Icons.download, _testGetDeepLinkData),
          _actionButton('Pull: Deferred', Icons.download_outlined, _testGetDeferredLinkData),
          _actionButton('Await: DeepLink', Icons.hourglass_top, _testAwaitDeepLinkData),
          _actionButton('Await: Deferred', Icons.hourglass_bottom, _testAwaitDeferredLinkData),
          _actionButton('Track Event', Icons.analytics, _testTrack),
          _actionButton('Track Purchase', Icons.shopping_cart, _testTrackPurchase),
          _actionButton('Create Link', Icons.link, _testCreateLink),
          _actionButton('Dynamic Link', Icons.dynamic_feed, _testCreateDynamicLink),
          _actionButton('Payment', Icons.payment, _testTrackPayment),
        ],
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, VoidCallback onTap) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: cs.primary),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, color: cs.onSurface)),
          ],
        ),
      ),
    );
  }

  Widget _buildLogList(ColorScheme cs) {
    if (_logs.isEmpty) {
      return Center(
        child: Text(
          '로그가 없습니다\n딥링크를 수신하거나 버튼을 눌러 테스트하세요',
          textAlign: TextAlign.center,
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _logs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final log = _logs[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(log.title, style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: cs.onSurface,
                    )),
                  ),
                  Text(
                    '${log.time.hour.toString().padLeft(2, '0')}:'
                    '${log.time.minute.toString().padLeft(2, '0')}:'
                    '${log.time.second.toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(log.detail, style: TextStyle(
                fontSize: 12,
                color: cs.onSurfaceVariant,
                fontFamily: 'monospace',
              )),
            ],
          ),
        );
      },
    );
  }
}

class _LogEntry {
  final String title;
  final String detail;
  final DateTime time;

  _LogEntry({required this.title, required this.detail, required this.time});
}
