class ClaimItem {
  const ClaimItem({
    required this.id,
    required this.status,
    required this.type,
    required this.message,
    required this.createdAt,
    required this.itemId,
    required this.itemTitle,
    required this.itemType,
    required this.itemStatus,
    this.itemImageUrl,
    this.adminNote,
    this.proofImageUrls = const [],
    this.reviewedAt,
  });

  final String id;
  final String status;
  final String type;
  final String message;
  final DateTime createdAt;
  final String itemId;
  final String itemTitle;
  final String itemType;
  final String itemStatus;
  final String? itemImageUrl;
  final String? adminNote;
  final List<String> proofImageUrls;
  final DateTime? reviewedAt;

  factory ClaimItem.fromJson(Map<String, dynamic> json) {
    final item = json['item'] as Map<String, dynamic>? ?? {};
    final proof = json['proofImageUrls'];
    return ClaimItem(
      id: json['id'] as String,
      status: json['status'] as String,
      type: json['type'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      itemId: item['id'] as String,
      itemTitle: item['title'] as String,
      itemType: item['type'] as String,
      itemStatus: item['status'] as String,
      itemImageUrl: item['imageUrl'] as String?,
      adminNote: json['adminNote'] as String?,
      proofImageUrls: proof is List
          ? proof.map((e) => e.toString()).toList()
          : const [],
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.parse(json['reviewedAt'] as String)
          : null,
    );
  }
}

class ClaimsPage {
  const ClaimsPage({
    required this.claims,
    required this.total,
    required this.page,
    required this.totalPages,
  });

  final List<ClaimItem> claims;
  final int total;
  final int page;
  final int totalPages;

  factory ClaimsPage.fromJson(Map<String, dynamic> json) {
    final list = json['claims'] as List<dynamic>? ?? [];
    return ClaimsPage(
      claims: list
          .map((e) => ClaimItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      totalPages: json['totalPages'] as int? ?? 1,
    );
  }
}
