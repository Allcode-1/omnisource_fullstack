class ApiConstants {
  static const String baseUrl = "http://localhost:8000";

  // Auth
  static const String login = "/auth/token";
  static const String register = "/auth/register";

  // Discovery
  static const String search = "/discovery/search";

  // Actions (users library)
  static const String favorites = "/actions/favorites";
  static const String like = "/actions/like";
  static const String playlists = "/actions/playlists";
}
