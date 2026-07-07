import '../../domain/entities/litige.dart';
import '../../domain/enums/dispute_status.dart';

class LitigeModel {
  final String id;
  final String motif;
  final String statut;
  final String? decision;
  final double? montantRembourse;
  final String dateOuverture;
  final String commandeId;
  final String ouvertParUserId;
  final String? traiteParAdminId;

  const LitigeModel({
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

  factory LitigeModel.fromEntity(Litige e) {
    return LitigeModel(
      id: e.id,
      motif: e.motif,
      statut: e.statut.name,
      decision: e.decision,
      montantRembourse: e.montantRembourse,
      dateOuverture: e.dateOuverture.toIso8601String(),
      commandeId: e.commandeId,
      ouvertParUserId: e.ouvertParUserId,
      traiteParAdminId: e.traiteParAdminId,
    );
  }

  Litige toEntity() {
    return Litige(
      id: id,
      motif: motif,
      statut: DisputeStatus.values.firstWhere((s) => s.name == statut),
      decision: decision,
      montantRembourse: montantRembourse,
      dateOuverture: DateTime.parse(dateOuverture),
      commandeId: commandeId,
      ouvertParUserId: ouvertParUserId,
      traiteParAdminId: traiteParAdminId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'motif': motif,
        'statut': statut,
        'decision': decision,
        'montantRembourse': montantRembourse,
        'dateOuverture': dateOuverture,
        'commandeId': commandeId,
        'ouvertParUserId': ouvertParUserId,
        'traiteParAdminId': traiteParAdminId,
      };

  factory LitigeModel.fromJson(Map<String, dynamic> json) {
    return LitigeModel(
      id: json['id'] as String,
      motif: json['motif'] as String,
      statut: json['statut'] as String,
      decision: json['decision'] as String?,
      montantRembourse: (json['montantRembourse'] as num?)?.toDouble(),
      dateOuverture: json['dateOuverture'] as String,
      commandeId: json['commandeId'] as String,
      ouvertParUserId: json['ouvertParUserId'] as String,
      traiteParAdminId: json['traiteParAdminId'] as String?,
    );
  }
}
