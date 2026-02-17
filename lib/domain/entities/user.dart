class User {
  final String id;
  final String email;
  final String username;
  final bool isOnboardingCompleted;
  final List<String> interests;

  User({
    required this.id,
    required this.email,
    required this.username,
    required this.isOnboardingCompleted,
    this.interests = const [],
  });
}
