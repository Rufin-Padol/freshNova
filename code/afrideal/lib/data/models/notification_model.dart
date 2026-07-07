import '../../domain/entities/notification_entity.dart';
import '../../domain/enums/notification_type.dart';

class NotificationModel {
  final String id;
  final String message;
  final String type;
  final bool estLue;
  final String dateEnvoi;
  final String canal;
  final String destinataireId;
  final String? referenceId;

  const NotificationModel({
    required this.id,
    required this.message,
    required this.type,
    required this.dateEnvoi,
    required this.destinataireId,
    this.estLue = false,
    this.canal = 'push',
    this.referenceId,
  });

  factory NotificationModel.fromEntity(NotificationEntity e) {
    return NotificationModel(
      id: e.id,
      message: e.message,
      type: e.type.name,
      estLue: e.estLue,
      dateEnvoi: e.dateEnvoi.toIso8601String(),
      canal: e.canal.name,
      destinataireId: e.destinataireId,
      referenceId: e.referenceId,
    );
  }

  NotificationEntity toEntity() {
    return NotificationEntity(
      id: id,
      message: message,
      type: NotificationType.values.firstWhere((t) => t.name == type),
      estLue: estLue,
      dateEnvoi: DateTime.parse(dateEnvoi),
      canal: NotificationChannel.values.firstWhere((c) => c.name == canal),
      destinataireId: destinataireId,
      referenceId: referenceId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'message': message,
        'type': type,
        'estLue': estLue,
        'dateEnvoi': dateEnvoi,
        'canal': canal,
        'destinataireId': destinataireId,
        'referenceId': referenceId,
      };

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      message: json['message'] as String,
      type: json['type'] as String,
      estLue: json['estLue'] as bool? ?? false,
      dateEnvoi: json['dateEnvoi'] as String,
      canal: json['canal'] as String? ?? 'push',
      destinataireId: json['destinataireId'] as String,
      referenceId: json['referenceId'] as String?,
    );
  }
}
