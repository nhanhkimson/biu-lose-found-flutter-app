class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// User dismissed the sign-in flow (e.g. closed Facebook login).
class AuthCancelledException implements Exception {}
