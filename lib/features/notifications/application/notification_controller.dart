import 'package:capeonn_app/features/notifications/data/notification_models.dart';
import 'package:capeonn_app/features/notifications/data/notification_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


final notificationUnreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.getUnreadCount();
});

final notificationsListProvider =
    FutureProvider.autoDispose.family<PaginatedNotifications, bool?>((ref, unreadOnly) async {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.getNotifications(unreadOnly: unreadOnly);
});
