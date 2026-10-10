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

class NotificationCategoryNotifier extends Notifier<NotificationCategory> {
  @override
  NotificationCategory build() => NotificationCategory.all;

  void setCategory(NotificationCategory category) => state = category;
}

final selectedNotificationCategoryProvider =
    NotifierProvider<NotificationCategoryNotifier, NotificationCategory>(
  NotificationCategoryNotifier.new,
);

final notificationPreferencesProvider =
    AsyncNotifierProvider<NotificationPreferencesNotifier, NotificationPreferencesModel>(
  NotificationPreferencesNotifier.new,
);

class NotificationPreferencesNotifier
    extends AsyncNotifier<NotificationPreferencesModel> {
  @override
  Future<NotificationPreferencesModel> build() async {
    final repo = ref.watch(notificationRepositoryProvider);
    return repo.getPreferences();
  }

  Future<void> updatePreferences(NotificationPreferencesModel updated) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(notificationRepositoryProvider);
      return repo.updatePreferences(updated);
    });
  }
}
