import 'package:beltei_app/data/models/dashboard_data.dart';
import 'package:beltei_app/data/repositories/claims_repository.dart';
import 'package:beltei_app/data/repositories/items_repository.dart';

class DashboardRepository {
  DashboardRepository(this._items, this._claims);

  final ItemsRepository _items;
  final ClaimsRepository _claims;

  Future<DashboardPayload> fetch() async {
    final stats = await _fetchStats();
    final activity = await _fetchActivity();
    final matches = await _fetchMatches();
    return DashboardPayload(
      stats: stats,
      matches: matches,
      activity: activity,
    );
  }

  Future<DashboardStats> _fetchStats() async {
    try {
      final lostPage = await _items.fetchMyItems(type: 'LOST');
      final foundPage = await _items.fetchMyItems(type: 'FOUND');
      final claimsPage = await _claims.fetchMyClaims();
      final resolvedLost =
          await _items.fetchMyItems(type: 'LOST', status: 'RESOLVED');
      final resolvedFound =
          await _items.fetchMyItems(type: 'FOUND', status: 'RESOLVED');

      return DashboardStats(
        myLost: lostPage.total,
        myFound: foundPage.total,
        myClaims: claimsPage.total,
        myResolved: resolvedLost.total + resolvedFound.total,
      );
    } catch (_) {
      return const DashboardStats(
        myLost: 0,
        myFound: 0,
        myClaims: 0,
        myResolved: 0,
      );
    }
  }

  Future<List<Map<String, dynamic>>> _fetchActivity() async {
    try {
      final itemsPage = await _items.fetchMyItems();
      final claimsPage = await _claims.fetchMyClaims();

      final rows = <Map<String, dynamic>>[
        for (final item in itemsPage.items)
          {
            'id': item.id,
            'kind': 'item',
            'itemId': item.id,
            'title': item.title,
            'type': item.type,
            'status': item.status,
            'at': item.createdAt.toIso8601String(),
          },
        for (final claim in claimsPage.claims)
          {
            'id': claim.id,
            'kind': 'claim',
            'itemId': claim.itemId,
            'itemTitle': claim.itemTitle,
            'claimStatus': claim.status,
            'at': claim.createdAt.toIso8601String(),
          },
      ];
      rows.sort((a, b) {
        final aAt = DateTime.tryParse(a['at'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bAt = DateTime.tryParse(b['at'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bAt.compareTo(aAt);
      });
      return rows.take(10).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<MatchSuggestion>> _fetchMatches() async {
    try {
      final myItems = await _items.fetchMyItems(status: 'OPEN');
      final browse = await _items.fetchItems(status: 'OPEN', preferCache: false);
      final suggestions = <MatchSuggestion>[];

      for (final mine in myItems.items) {
        final opposite = mine.type == 'LOST' ? 'FOUND' : 'LOST';
        for (final other in browse.items) {
          if (other.id == mine.id) continue;
          if (other.type != opposite) continue;
          if (other.category != mine.category) continue;
          if (other.building != mine.building) continue;

          var confidence = 60;
          if (mine.color != null &&
              mine.color!.isNotEmpty &&
              mine.color == other.color) {
            confidence += 15;
          }
          if (mine.brand != null &&
              mine.brand!.isNotEmpty &&
              mine.brand == other.brand) {
            confidence += 15;
          }
          if (confidence > 100) confidence = 100;

          suggestions.add(
            MatchSuggestion(
              id: '${mine.id}_${other.id}',
              myItemId: mine.id,
              myItemTitle: mine.title,
              mySide: mine.type,
              otherItemId: other.id,
              otherTitle: other.title,
              otherSide: other.type,
              confidence: confidence,
              building: mine.building,
            ),
          );
        }
      }

      suggestions.sort((a, b) => b.confidence.compareTo(a.confidence));
      return suggestions.take(10).toList();
    } catch (_) {
      return const [];
    }
  }
}
