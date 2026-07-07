import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/notification_entity.dart';
import '../../../domain/repositories/i_notification_repository.dart';
import '../../local/datasources/local_json_store.dart';
import '../../models/notification_model.dart';

class LocalNotificationRepository implements INotificationRepository {
  final LocalJsonStore<NotificationModel> _store =
      LocalJsonStore<NotificationModel>(
    boxName: StorageKeys.notificationsBox,
    toJson: (m) => m.toJson(),
    fromJson: NotificationModel.fromJson,
    idOf: (m) => m.id,
  );

  @override
  Future<List<NotificationEntity>> getByDestinataire(String userId) async {
    final all = await _store.getAll();
    final filtered = all.where((m) => m.destinataireId == userId).toList();
    filtered.sort((a, b) => b.dateEnvoi.compareTo(a.dateEnvoi));
    return filtered.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> save(NotificationEntity notification) async {
    await _store.save(NotificationModel.fromEntity(notification));
  }

  @override
  Future<void> marquerCommeLue(String notificationId) async {
    final model = await _store.getById(notificationId);
    if (model == null) return;
    final entity = model.toEntity().copyWith(estLue: true);
    await save(entity);
  }

  @override
  Future<int> compterNonLues(String userId) async {
    final notifications = await getByDestinataire(userId);
    return notifications.where((n) => !n.estLue).length;
  }
}
