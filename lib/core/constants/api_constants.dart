class ApiConstants {
  static const String baseUrl = "http://localhost:8000/";

  // Auth
  static const String login = "/auth/token";
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
}
