import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? firestoreDate(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

String firestoreIso(dynamic value) {
  return firestoreDate(value)?.toIso8601String() ?? DateTime.now().toIso8601String();
}

bool _matchesQuery(String? haystack, String? needle) {
  if (needle == null || needle.isEmpty) return true;
  return (haystack ?? '').toLowerCase().contains(needle.toLowerCase());
}

bool matchesItemFilters(
  Map<String, dynamic> data, {
  String? q,
  String? type,
  String? category,
  String? building,
  String? status,
  String? dateFrom,
  String? dateTo,
}) {
  if (type != null && type.isNotEmpty && data['type'] != type) return false;
  if (category != null && category.isNotEmpty && data['category'] != category) {
    return false;
  }
  if (building != null && building.isNotEmpty && data['building'] != building) {
    return false;
  }
  if (status != null && status.isNotEmpty && data['status'] != status) return false;

  if (q != null && q.isNotEmpty) {
    final title = data['title'] as String? ?? '';
    final description = data['description'] as String? ?? '';
    if (!_matchesQuery(title, q) && !_matchesQuery(description, q)) return false;
  }

  final eventDate = firestoreDate(data['eventDate']);
  if (eventDate != null) {
    if (dateFrom != null && dateFrom.isNotEmpty) {
      final from = DateTime.tryParse(dateFrom);
      if (from != null && eventDate.isBefore(from)) return false;
    }
    if (dateTo != null && dateTo.isNotEmpty) {
      final to = DateTime.tryParse(dateTo);
      if (to != null && eventDate.isAfter(to.add(const Duration(days: 1)))) {
        return false;
      }
    }
  }

  return true;
}

List<T> paginateList<T>(List<T> items, {required int page, required int pageSize}) {
  final start = (page - 1) * pageSize;
  if (start >= items.length) return const [];
  final end = start + pageSize;
  return items.sublist(start, end > items.length ? items.length : end);
}
