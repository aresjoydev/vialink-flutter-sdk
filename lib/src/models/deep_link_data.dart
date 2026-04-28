/// 딥링크 데이터 모델
class DeepLinkData {
  final String path;
  final Map<String, dynamic> params;
  final String? shortCode;

  const DeepLinkData({
    required this.path,
    this.params = const {},
    this.shortCode,
  });

  factory DeepLinkData.fromMap(Map<String, dynamic> map) {
    return DeepLinkData(
      path: (map['path'] as String?) ?? '/',
      params: map['params'] != null
          ? Map<String, dynamic>.from(map['params'] as Map)
          : const {},
      shortCode: map['shortCode'] as String?,
    );
  }
}
