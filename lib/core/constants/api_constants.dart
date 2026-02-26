class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
  static const bool useImageProxy = bool.fromEnvironment(
    'USE_IMAGE_PROXY',
    defaultValue: true,
  );

  // Auth
  static const String login = "/auth/login";
  static const String register = "/auth/register";

  static const String userMe = '/user/me';
  static const String userUpdate = '/user/update';
  static const String userDelete = '/user/me';

  // Discovery
  static const String search = "/content/search";

  // Actions (users library)
  static const String favorites = "/actions/favorites";
  static const String like = "/actions/like";
  static const String playlists = "/actions/playlists";

  // Content
  static const String trending = "/content/trending";
  static const String home = "/content/home";
  static const String recommendations = "/content/recommendations";

  // Research
  static const String deepResearch = "/research/deep";

  static String resolveImageUrl(String? rawUrl) {
    if (rawUrl == null) return '';
    final value = rawUrl.trim();
    if (value.isEmpty) return '';
    if (!useImageProxy || !value.startsWith('http')) return value;
    if (value.contains('/content/image-proxy?url=')) return value;
    return '$baseUrl/content/image-proxy?url=${Uri.encodeQueryComponent(value)}';
  }
}
