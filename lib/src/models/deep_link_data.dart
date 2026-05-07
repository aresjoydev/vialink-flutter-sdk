/// 딥링크 데이터 모델
class DeepLinkData {
  final String path;
  final Map<String, dynamic> params;
  final String? shortCode;

  /// 어트리뷰션용 numeric link id (네이티브 SDK가 디퍼드/딥링크 매칭 후 전달).
  /// 네이티브 SDK가 결제 시도에 자동 첨부하므로, Dart 측 결제 호출 시 별도 지정 불필요.
  final int? linkId;

  const DeepLinkData({
    required this.path,
    this.params = const {},
    this.shortCode,
    this.linkId,
  });

  factory DeepLinkData.fromMap(Map<String, dynamic> map) {
    final raw = map['linkId'] ?? map['link_id'];
    final int? linkId = raw is int
        ? (raw > 0 ? raw : null)
        : (raw is num ? (raw.toInt() > 0 ? raw.toInt() : null) : null);
    return DeepLinkData(
      path: (map['path'] as String?) ?? '/',
      params: map['params'] != null
          ? Map<String, dynamic>.from(map['params'] as Map)
          : const {},
      shortCode: map['shortCode'] as String?,
      linkId: linkId,
    );
  }
}
