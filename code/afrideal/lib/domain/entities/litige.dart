import 'package:equatable/equatable.dart';
import '../enums/dispute_status.dart';

/// Entité métier Litige, conforme au diagramme UML.
class Litige extends Equatable {
  final String id;
  final String motif;
  final DisputeStatus statut;
  final String? decision;
  final double? montantRembourse;
  final DateTime dateOuverture;

  final String commandeId;
  final String ouvertParUserId;

  /// Identifiant de l'admin ayant traité le litige, renseigné une fois
  /// la décision prise.
  final String? traiteParAdminId;

  const Litige({
    required this.id,
    required this.motif,
    required this.statut,
    required this.dateOuverture,
    required this.commandeId,
    required this.ouvertParUserId,
    this.decision,
    this.montantRembourse,
    this.traiteParAdminId,
  });

  Litige copyWith({
    String? id,
    String? motif,
    DisputeStatus? statut,
    String? decision,
    double? montantRembourse,
    DateTime? dateOuverture,
    String? commandeId,
    String? ouvertParUserId,
    String? traiteParAdminId,
  }) {
    return Litige(
      id: id ?? this.id,
      motif: motif ?? this.motif,
      statut: statut ?? this.statut,
      decision: decision ?? this.decision,
      montantRembourse: montantRembourse ?? this.montantRembourse,
      dateOuverture: dateOuverture ?? this.dateOuverture,
      commandeId: commandeId ?? this.commandeId,
      ouvertParUserId: ouvertParUserId ?? this.ouvertParUserId,
      traiteParAdminId: traiteParAdminId ?? this.traiteParAdminId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        motif,
        statut,
        decision,
        montantRembourse,
        dateOuverture,
        commandeId,
        ouvertParUserId,
        traiteParAdminId,
      ];
}
