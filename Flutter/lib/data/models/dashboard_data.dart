class DashboardStats {
  const DashboardStats({
    required this.myLost,
    required this.myFound,
    required this.myClaims,
    required this.myResolved,
  });

  final int myLost;
  final int myFound;
  final int myClaims;
  final int myResolved;

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      myLost: json['myLost'] as int? ?? 0,
      myFound: json['myFound'] as int? ?? 0,
      myClaims: json['myClaims'] as int? ?? 0,
      myResolved: json['myResolved'] as int? ?? 0,
    );
  }
}

class MatchSuggestion {
  const MatchSuggestion({
    required this.id,
    required this.myItemId,
    required this.myItemTitle,
    required this.mySide,
    required this.otherItemId,
    required this.otherTitle,
    required this.otherSide,
    required this.confidence,
    required this.building,
  });

  final String id;
  final String myItemId;
  final String myItemTitle;
  final String mySide;
  final String otherItemId;
  final String otherTitle;
  final String otherSide;
  final int confidence;
  final String building;

  factory MatchSuggestion.fromJson(Map<String, dynamic> json) {
    return MatchSuggestion(
      id: json['id'] as String,
      myItemId: json['myItemId'] as String,
      myItemTitle: json['myItemTitle'] as String,
      mySide: json['mySide'] as String,
      otherItemId: json['otherItemId'] as String,
      otherTitle: json['otherTitle'] as String,
      otherSide: json['otherSide'] as String,
      confidence: json['confidence'] as int? ?? 0,
      building: json['building'] as String? ?? '',
    );
  }
}

class DashboardPayload {
  const DashboardPayload({
    required this.stats,
    required this.matches,
    required this.activity,
  });

  final DashboardStats stats;
  final List<MatchSuggestion> matches;
  final List<Map<String, dynamic>> activity;

  factory DashboardPayload.fromJson(Map<String, dynamic> json) {
    final matches = json['matches'] as List<dynamic>? ?? [];
    final activity = json['activity'] as List<dynamic>? ?? [];
    return DashboardPayload(
      stats: DashboardStats.fromJson(
        json['stats'] as Map<String, dynamic>? ?? {},
      ),
      matches: matches
          .map((e) => MatchSuggestion.fromJson(e as Map<String, dynamic>))
          .toList(),
      activity: activity.map((e) => e as Map<String, dynamic>).toList(),
    );
  }
}
