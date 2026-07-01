import 'package:beltei_app/data/models/profile_activity.dart';

class ProfileStats {
  const ProfileStats({
    required this.myLost,
    required this.myFound,
    required this.myClaims,
    required this.myResolved,
  });

  final int myLost;
  final int myFound;
  final int myClaims;
  final int myResolved;

  factory ProfileStats.fromJson(Map<String, dynamic> json) {
    return ProfileStats(
      myLost: json['myLost'] as int? ?? 0,
      myFound: json['myFound'] as int? ?? 0,
      myClaims: json['myClaims'] as int? ?? 0,
      myResolved: json['myResolved'] as int? ?? 0,
    );
  }
}

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    this.name,
    this.phoneNumber,
    this.role,
    this.image,
    this.studentId,
    this.stats,
    this.createdAt,
    this.lastSignInAt,
    this.emailVerified = false,
    this.hasPassword = false,
    this.recentActivity = const [],
  });

  final String id;
  final String? email;
  final String? name;
  final String? phoneNumber;
  final String? role;
  final String? image;
  final String? studentId;
  final ProfileStats? stats;
  final DateTime? createdAt;
  final DateTime? lastSignInAt;
  final bool emailVerified;
  final bool hasPassword;
  final List<ProfileActivity> recentActivity;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final statsJson = json['stats'];
    final activityJson = json['recentActivity'];
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String?,
      name: json['name'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      role: json['role'] as String?,
      image: json['image'] as String?,
      studentId: json['studentId'] as String?,
      stats: statsJson is Map<String, dynamic>
          ? ProfileStats.fromJson(statsJson)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      lastSignInAt: json['lastSignInAt'] != null
          ? DateTime.parse(json['lastSignInAt'] as String)
          : null,
      emailVerified: json['emailVerified'] as bool? ?? false,
      hasPassword: json['hasPassword'] as bool? ?? false,
      recentActivity: activityJson is List
          ? activityJson
              .map((e) => ProfileActivity.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'phoneNumber': phoneNumber,
        'role': role,
        'image': image,
        'studentId': studentId,
        'emailVerified': emailVerified,
        'hasPassword': hasPassword,
        if (stats != null)
          'stats': {
            'myLost': stats!.myLost,
            'myFound': stats!.myFound,
            'myClaims': stats!.myClaims,
            'myResolved': stats!.myResolved,
          },
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (lastSignInAt != null) 'lastSignInAt': lastSignInAt!.toIso8601String(),
      };

  String get displayName {
    final display = name?.trim();
    if (display != null && display.isNotEmpty) return display;

    final phone = phoneNumber?.trim();
    if (phone != null && phone.isNotEmpty) return phone;

    final mail = email?.trim();
    if (mail != null && mail.isNotEmpty) return mail;

    return 'Student';
  }

  String get roleLabel {
    switch (role) {
      case 'ADMIN':
        return 'Administrator';
      case 'STAFF':
        return 'Staff';
      default:
        return 'Student';
    }
  }
}