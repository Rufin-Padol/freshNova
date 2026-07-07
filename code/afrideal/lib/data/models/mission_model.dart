import '../../domain/entities/mission.dart';
import '../../domain/enums/mission_status.dart';
import '../../domain/enums/proof_type.dart';

class MissionModel {
  final String id;
  final String type;
  final String statut;
  final String dateHeure;
  final String? codeConfirmation;
  final int photosCount;
  final String agentId;
  final String referenceId;
  final String? notesAgent;
  final String? raisonRefus;
  final double? latitude;
  final double? longitude;
  final String? proprietaireId;
  final String? preuveProprieteType;
  final String? preuveProprieteValeur;

  const MissionModel({
    required this.id,
    required this.type,
    required this.statut,
    required this.dateHeure,
    required this.agentId,
    required this.referenceId,
    this.codeConfirmation,
    this.photosCount = 0,
    this.notesAgent,
    this.raisonRefus,
    this.latitude,
    this.longitude,
    this.proprietaireId,
    this.preuveProprieteType,
    this.preuveProprieteValeur,
  });

  factory MissionModel.fromEntity(Mission e) {
    return MissionModel(
      id: e.id,
      type: e.type.name,
      statut: e.statut.name,
      dateHeure: e.dateHeure.toIso8601String(),
      agentId: e.agentId,
      referenceId: e.referenceId,
      codeConfirmation: e.codeConfirmation,
      photosCount: e.photosCount,
      notesAgent: e.notesAgent,
      raisonRefus: e.raisonRefus,
      latitude: e.latitude,
      longitude: e.longitude,
      proprietaireId: e.proprietaireId,
      preuveProprieteType: e.preuveProprieteType?.name,
      preuveProprieteValeur: e.preuveProprieteValeur,
    );
  }

  Mission toEntity() {
    return Mission(
      id: id,
      type: MissionType.values.firstWhere((t) => t.name == type),
      statut: MissionStatus.values.firstWhere((s) => s.name == statut),
      dateHeure: DateTime.parse(dateHeure),
      agentId: agentId,
      referenceId: referenceId,
      codeConfirmation: codeConfirmation,
      photosCount: photosCount,
      notesAgent: notesAgent,
      raisonRefus: raisonRefus,
      latitude: latitude,
      longitude: longitude,
      proprietaireId: proprietaireId,
      preuveProprieteType: preuveProprieteType == null
          ? null
          : ProofType.values.firstWhere((t) => t.name == preuveProprieteType),
      preuveProprieteValeur: preuveProprieteValeur,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'statut': statut,
        'dateHeure': dateHeure,
        'codeConfirmation': codeConfirmation,
        'photosCount': photosCount,
        'agentId': agentId,
        'referenceId': referenceId,
        'notesAgent': notesAgent,
        'raisonRefus': raisonRefus,
        'latitude': latitude,
        'longitude': longitude,
        'proprietaireId': proprietaireId,
        'preuveProprieteType': preuveProprieteType,
        'preuveProprieteValeur': preuveProprieteValeur,
      };

  factory MissionModel.fromJson(Map<String, dynamic> json) {
    return MissionModel(
      id: json['id'] as String,
      type: json['type'] as String,
      statut: json['statut'] as String,
      dateHeure: json['dateHeure'] as String,
      agentId: json['agentId'] as String,
      referenceId: json['referenceId'] as String,
      codeConfirmation: json['codeConfirmation'] as String?,
      photosCount: json['photosCount'] as int? ?? 0,
      notesAgent: json['notesAgent'] as String?,
      raisonRefus: json['raisonRefus'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      proprietaireId: json['proprietaireId'] as String?,
      preuveProprieteType: json['preuveProprieteType'] as String?,
      preuveProprieteValeur: json['preuveProprieteValeur'] as String?,
    );
  }
}
