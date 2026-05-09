import 'user_notification_item.dart';

class NotificationListMeta {
  const NotificationListMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  factory NotificationListMeta.fromJson(Map<String, dynamic> json) {
    return NotificationListMeta(
      currentPage: (json['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (json['last_page'] as num?)?.toInt() ?? 1,
      perPage: (json['per_page'] as num?)?.toInt() ?? 15,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}

class PaginatedNotificationsResult {
  const PaginatedNotificationsResult({
    required this.items,
    required this.meta,
  });

  final List<UserNotificationItem> items;
  final NotificationListMeta meta;
}
