class ProfileActivity {
  const ProfileActivity({
    required this.id,
    required this.kind,
    required this.itemId,
    required this.title,
    required this.at,
    this.type,
    this.status,
    this.claimStatus,
  });

  final String id;
  final String kind;
  final String itemId;
  final String title;
  final DateTime at;
  final String? type;
  final String? status;
  final String? claimStatus;

  bool get isItem => kind == 'item';
  bool get isClaim => kind == 'claim';

  factory ProfileActivity.fromJson(Map<String, dynamic> json) {
    if (json['kind'] == 'claim') {
      return ProfileActivity(
        id: json['id'] as String,
        kind: 'claim',
        itemId: json['itemId'] as String,
        title: json['itemTitle'] as String,
        claimStatus: json['claimStatus'] as String?,
        at: DateTime.parse(json['at'] as String),
      );
    }
    return ProfileActivity(
      id: json['id'] as String,
      kind: 'item',
      itemId: json['itemId'] as String,
      title: json['title'] as String,
      type: json['type'] as String?,
      status: json['status'] as String?,
      at: DateTime.parse(json['at'] as String),
    );
  }
}
