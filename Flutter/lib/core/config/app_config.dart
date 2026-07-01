/// Central configuration for API and branding.
abstract final class AppConfig {
  static const String appName = 'BIU Lost & Found';
  static const String universityLabel = 'Beltei International University';

  /// Production API (see biu-lost-found README).
  static const String apiBaseUrl = 'https://belteiloseandfound.vercel.app';

  static const String registerWebPath = '/register';
  static String get registerUrl => '$apiBaseUrl$registerWebPath';

  static const String khmerFontFamily = 'KantumruyPro';
  static const int defaultPageSize = 12;
}
