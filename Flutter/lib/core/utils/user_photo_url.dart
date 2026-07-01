import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:http/http.dart' as http;

class FacebookProfile {
  const FacebookProfile({
    this.id,
    this.name,
    this.email,
    this.pictureUrl,
  });

  final String? id;
  final String? name;
  final String? email;
  final String? pictureUrl;

  factory FacebookProfile.fromMap(Map<String, dynamic> data) {
    return FacebookProfile(
      id: data['id'] as String?,
      name: data['name'] as String?,
      email: data['email'] as String?,
      pictureUrl: _parsePictureUrl(data['picture']),
    );
  }
}

/// Best available profile photo from Firebase Auth (top-level or provider data).
String? resolveUserPhotoUrl(User user) {
  final top = user.photoURL?.trim();
  if (top != null && top.isNotEmpty) return top;

  for (final provider in user.providerData) {
    final url = provider.photoURL?.trim();
    if (url != null && url.isNotEmpty) return url;
  }
  return null;
}

String? readStoredPhotoUrl(Map<String, dynamic>? data) {
  final value = data?['photoUrl'] as String?;
  if (value != null && value.trim().isNotEmpty) return value.trim();
  return null;
}

bool userHasFacebookProvider(User user) {
  return user.providerData.any((p) => p.providerId == 'facebook.com');
}

String? _parsePictureUrl(dynamic picture) {
  if (picture is! Map) return null;
  final pictureData = picture['data'];
  if (pictureData is! Map) return null;
  final url = pictureData['url'] as String?;
  if (url == null || url.trim().isEmpty) return null;
  return url.trim();
}

/// Fetch Facebook profile while the login access token is still active.
Future<FacebookProfile?> fetchFacebookProfile(AccessToken accessToken) async {
  try {
    final data = await FacebookAuth.instance.getUserData(
      fields: 'id,name,email,picture.width(400).height(400)',
    );
    final profile = FacebookProfile.fromMap(data);
    if (profile.pictureUrl != null) return profile;
    if (profile.id != null) {
      return FacebookProfile(
        id: profile.id,
        name: profile.name,
        email: profile.email,
        pictureUrl: _publicPictureUrl(profile.id!),
      );
    }
    if (profile.name != null || profile.email != null) return profile;
  } catch (_) {}

  if (accessToken is! LimitedToken) {
    try {
      final uri = Uri.https(
        'graph.facebook.com',
        '/v22.0/me',
        {
          'fields': 'id,name,email,picture.type(large)',
          'access_token': accessToken.tokenString,
        },
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final profile = FacebookProfile.fromMap(data);
        if (profile.pictureUrl != null) return profile;
        if (profile.id != null) {
          return FacebookProfile(
            id: profile.id,
            name: profile.name,
            email: profile.email,
            pictureUrl: _publicPictureUrl(profile.id!),
          );
        }
        return profile;
      }
    } catch (_) {}
  }

  return null;
}

String _publicPictureUrl(String facebookUserId) {
  return 'https://graph.facebook.com/$facebookUserId/picture?type=large';
}

Future<String?> fetchFacebookPictureUrl() async {
  final profile = await fetchFacebookProfileFromSession();
  return profile?.pictureUrl;
}

Future<FacebookProfile?> fetchFacebookProfileFromSession() async {
  final token = await FacebookAuth.instance.accessToken;
  if (token == null) return null;
  return fetchFacebookProfile(token);
}

/// Copies Facebook profile photo into Firebase Auth when missing.
Future<User> ensureFacebookPhotoSynced(User user) async {
  if (!userHasFacebookProvider(user)) return user;
  if (resolveUserPhotoUrl(user) != null) return user;

  final profile = await fetchFacebookProfileFromSession();
  final url = profile?.pictureUrl;
  if (url == null) return user;

  await user.updatePhotoURL(url);
  await user.reload();
  return FirebaseAuth.instance.currentUser ?? user;
}
