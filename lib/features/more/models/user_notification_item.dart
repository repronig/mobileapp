class UserNotificationItem {
  const UserNotificationItem({
    required this.id,
    required this.title,
    this.message,
    this.category,
    this.severity,
    this.readAt,
    this.createdAt,
    this.actionUrl,
  });

  final String id;
  final String title;
  final String? message;
  final String? category;
  final String? severity;
  final String? readAt;
  final String? createdAt;
  final String? actionUrl;

  bool get isUnread => readAt == null || readAt!.isEmpty;

  factory UserNotificationItem.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    return UserNotificationItem(
      id: rawId == null ? '' : '$rawId',
      title: json['title'] as String? ?? 'Notification',
      message: json['message'] as String?,
      category: json['category'] as String?,
      severity: json['severity'] as String?,
      readAt: json['read_at'] as String?,
      createdAt: json['created_at'] as String?,
      actionUrl: json['action_url'] as String?,
    );
  }
}
