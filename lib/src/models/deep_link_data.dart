/// 딥링크 데이터 모델
///
/// 네이티브 SDK에서 전달받은 딥링크 정보를 담습니다.
/// [linkId]는 서버 어트리뷰션을 위한 numeric link id입니다.
class DeepLinkData {
  final String path;
  final Map<String, String> params;
  final String? shortCode;
  final int? linkId;

  const DeepLinkData({
    required this.path,
    this.params = const {},
    this.shortCode,
    this.linkId,
  });

  @override
  String toString() =>
      'DeepLinkData(path: $path, params: $params, shortCode: $shortCode, linkId: $linkId)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeepLinkData &&
          path == other.path &&
          shortCode == other.shortCode &&
          linkId == other.linkId &&
          _mapsEqual(params, other.params);

  @override
  int get hashCode => Object.hash(path, shortCode, linkId);

  static bool _mapsEqual(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }
}
