import 'package:equatable/equatable.dart';
import '../enums/notification_type.dart';

/// Entité métier Notification, conforme au diagramme UML.
///
/// Nommée [NotificationEntity] (et non simplement Notification) pour
/// éviter tout conflit de nom avec les classes du SDK Flutter/système
/// qui utilisent parfois aussi ce mot.
class NotificationEntity extends Equatable {
  final String id;
  final String message;
  final NotificationType type;
  final bool estLue;
  final DateTime dateEnvoi;
  final NotificationChannel canal;

  final String destinataireId;

  /// Identifiant de l'entité concernée (commande, produit, mission...),
  /// utilisé pour naviguer directement vers l'écran pertinent au clic.
  final String? referenceId;

  const NotificationEntity({
    required this.id,
    required this.message,
    required this.type,
    required this.dateEnvoi,
    required this.destinataireId,
    this.estLue = false,
    this.canal = NotificationChannel.push,
    this.referenceId,
  });

  NotificationEntity copyWith({
    String? id,
    String? message,
    NotificationType? type,
    bool? estLue,
    DateTime? dateEnvoi,
    NotificationChannel? canal,
    String? destinataireId,
    String? referenceId,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      message: message ?? this.message,
      type: type ?? this.type,
      estLue: estLue ?? this.estLue,
      dateEnvoi: dateEnvoi ?? this.dateEnvoi,
      canal: canal ?? this.canal,
      destinataireId: destinataireId ?? this.destinataireId,
      referenceId: referenceId ?? this.referenceId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        message,
        type,
        estLue,
        dateEnvoi,
        canal,
        destinataireId,
        referenceId,
      ];
}
