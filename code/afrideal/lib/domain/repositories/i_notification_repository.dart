import '../entities/notification_entity.dart';

abstract class INotificationRepository {
  Future<List<NotificationEntity>> getByDestinataire(String userId);
  Future<void> save(NotificationEntity notification);
  Future<void> marquerCommeLue(String notificationId);
  Future<int> compterNonLues(String userId);
}
