import 'package:beltei_app/data/models/lost_found_item.dart';
import 'package:beltei_app/core/network/api_client.dart';

class NotificationsRepository {
  NotificationsRepository(this._api);

  final ApiClient _api;

  Future<({List<AppNotification> notifications, int unreadCount})> fetch({
    int limit = 50,
  }) async {
    final json = await _api.get(
      '/api/notifications',
      query: {'limit': '$limit'},
      auth: true,
    );
    final list = json['notifications'] as List<dynamic>? ?? [];
    return (
      notifications: list
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList(),
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }

  Future<void> markAllRead() async {
    await _api.post(
      '/api/notifications/mark-read',
      auth: true,
      body: {'all': true},
    );
  }

  Future<void> markRead(List<String> ids) async {
    await _api.post(
      '/api/notifications/mark-read',
      auth: true,
      body: {'ids': ids},
    );
  }
}
