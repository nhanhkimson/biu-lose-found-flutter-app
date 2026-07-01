class LostFoundItem {
  const LostFoundItem({
    required this.id,
    required this.type,
    required this.title,
    required this.category,
    required this.building,
    this.roomHint,
    required this.eventDate,
    this.imageUrl,
    required this.createdAt,
    this.status,
    this.description,
    this.imageUrls = const [],
    this.color,
    this.brand,
    this.timeApprox,
    this.foundDisposition,
    this.reward,
    this.viewCount,
  });

  final String id;
  final String type;
  final String? status;
  final String title;
  final String? description;
  final String category;
  final String building;
  final String? roomHint;
  final DateTime eventDate;
  final String? imageUrl;
  final List<String> imageUrls;
  final String? color;
  final String? brand;
  final String? timeApprox;
  final String? foundDisposition;
  final String? reward;
  final int? viewCount;
  final DateTime createdAt;

  bool get isLost => type == 'LOST';
  bool get isFound => type == 'FOUND';

  List<String> get gallery {
    final urls = <String>[];
    if (imageUrl != null && imageUrl!.isNotEmpty) urls.add(imageUrl!);
    for (final u in imageUrls) {
      if (u.isNotEmpty && !urls.contains(u)) urls.add(u);
    }
    return urls;
  }

  factory LostFoundItem.fromListJson(Map<String, dynamic> json) {
    return LostFoundItem(
      id: json['id'] as String,
      type: json['type'] as String,
      status: json['status'] as String?,
      title: json['title'] as String,
      category: json['category'] as String,
      building: json['building'] as String,
      roomHint: json['roomHint'] as String?,
      eventDate: DateTime.parse(json['eventDate'] as String),
      imageUrl: json['imageUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  factory LostFoundItem.fromDetailJson(Map<String, dynamic> json) {
    final extra = json['imageUrls'];
    return LostFoundItem(
      id: json['id'] as String,
      type: json['type'] as String,
      status: json['status'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      building: json['building'] as String,
      roomHint: json['roomHint'] as String?,
      eventDate: DateTime.parse(json['eventDate'] as String),
      imageUrl: json['imageUrl'] as String?,
      imageUrls: extra is List
          ? extra.map((e) => e.toString()).toList()
          : const [],
      color: json['color'] as String?,
      brand: json['brand'] as String?,
      timeApprox: json['timeApprox'] as String?,
      foundDisposition: json['foundDisposition'] as String?,
      reward: json['reward'] as String?,
      viewCount: json['viewCount'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toListJson() => {
        'id': id,
        'type': type,
        'status': status,
        'title': title,
        'category': category,
        'building': building,
        'roomHint': roomHint,
        'eventDate': eventDate.toIso8601String(),
        'imageUrl': imageUrl,
        'createdAt': createdAt.toIso8601String(),
      };
}

class ItemsPage {
  const ItemsPage({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  final List<LostFoundItem> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  factory ItemsPage.fromJson(Map<String, dynamic> json) {
    final list = json['items'] as List<dynamic>;
    return ItemsPage(
      items: list
          .map((e) => LostFoundItem.fromListJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
      totalPages: json['totalPages'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'items': items.map((e) => e.toListJson()).toList(),
        'total': total,
        'page': page,
        'pageSize': pageSize,
        'totalPages': totalPages,
      };
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.message,
    required this.read,
    required this.createdAt,
    this.link,
  });

  final String id;
  final String kind;
  final String? link;
  final String title;
  final String message;
  final bool read;
  final DateTime createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      kind: json['kind'] as String,
      link: json['link'] as String?,
      title: json['title'] as String,
      message: json['message'] as String,
      read: json['read'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
