import 'package:beltei_app/screens/item_detail_screen.dart';
import 'package:get/get.dart';

/// Opens in-app routes from notification `link` values (e.g. /items/abc).
void openNotificationLink(String? link) {
  if (link == null || link.isEmpty) return;
  final uri = Uri.tryParse(link);
  final path = uri?.path ?? link;
  final match = RegExp(r'^/items/([^/]+)$').firstMatch(path);
  if (match != null) {
    final id = match.group(1)!;
    Get.to(() => ItemDetailScreen(itemId: id));
  }
}
