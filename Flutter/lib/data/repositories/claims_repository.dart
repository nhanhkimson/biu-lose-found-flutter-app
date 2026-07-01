import 'package:beltei_app/core/network/api_client.dart';
import 'package:beltei_app/data/models/claim_item.dart';

class ClaimsRepository {
  ClaimsRepository(this._api);

  final ApiClient _api;

  Future<ClaimsPage> fetchMyClaims({
    int page = 1,
    String? status,
  }) async {
    final query = <String, String>{
      'page': '$page',
      if (status != null && status.isNotEmpty) 'status': status,
    };
    final json = await _api.get('/api/claims', query: query, auth: true);
    return ClaimsPage.fromJson(json);
  }

  Future<String> submitClaim({
    required String itemId,
    required String message,
    List<String> proofImageUrls = const [],
  }) async {
    final json = await _api.post(
      '/api/claims',
      auth: true,
      body: {
        'itemId': itemId,
        'message': message.trim(),
        'proofImageUrls': proofImageUrls,
      },
    );
    return json['id'] as String;
  }
}
