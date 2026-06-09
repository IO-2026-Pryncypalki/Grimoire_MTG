class SyncStatus {
  const SyncStatus({
    required this.collectionUpdatedAt,
    required this.decksUpdatedAt,
    required this.syncToken,
  });

  final String collectionUpdatedAt;
  final String decksUpdatedAt;
  final String syncToken;

  factory SyncStatus.fromJson(Map<String, dynamic> json) {
    return SyncStatus(
      collectionUpdatedAt: json['collectionUpdatedAt'] as String,
      decksUpdatedAt: json['decksUpdatedAt'] as String,
      syncToken: json['syncToken'] as String,
    );
  }
}
