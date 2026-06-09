class UserStats {
  UserStats({
    required this.deckCount,
    required this.uniqueCardsCount,
    required this.totalPhysicalCards,
    required this.joinedAt,
  });

  final int deckCount;
  final int uniqueCardsCount;
  final int totalPhysicalCards;
  final String joinedAt;

  factory UserStats.fromJson(Map<String, dynamic> json) => UserStats(
        deckCount: json['deckCount'] as int? ?? 0,
        uniqueCardsCount: json['uniqueCardsCount'] as int? ?? 0,
        totalPhysicalCards: json['totalPhysicalCards'] as int? ?? 0,
        joinedAt: json['joinedAt'] as String? ?? '',
      );
}

class UserProfile {
  UserProfile({
    required this.username,
    required this.email,
    required this.stats,
  });

  final String username;
  final String email;
  final UserStats stats;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        username: json['username'] as String? ?? '',
        email: json['email'] as String? ?? '',
        stats: UserStats.fromJson(json['stats'] as Map<String, dynamic>? ?? {}),
      );
}
