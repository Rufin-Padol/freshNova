import 'package:equatable/equatable.dart';
import '../enums/mission_status.dart';
import '../enums/proof_type.dart';

/// Entité métier Mission, conforme au diagramme UML.
///
/// Une mission de type [MissionType.collecte] est liée à une
/// [DemandeVendeur] ; une mission de type [MissionType.livraison] est
/// liée à une [Commande]. Le champ [referenceId] pointe vers l'une ou
/// l'autre selon [type].
class Mission extends Equatable {
  final String id;
  final MissionType type;
  final MissionStatus statut;
  final DateTime dateHeure;
  final String? codeConfirmation;
  final int photosCount;

  final String agentId;
  final String referenceId;

  /// Notes prises par l'agent sur le terrain (état réel constaté,
  /// défauts observés...).
  final String? notesAgent;

  /// Raison du refus de la mission, si applicable.
  final String? raisonRefus;

  /// Coordonnées GPS de la mission, utilisées pour la navigation et
  /// l'horodatage géolocalisé des photos.
  final double? latitude;
  final double? longitude;

  /// Propriétaire identifié/confirmé sur place par l'agent (registre
  /// [Proprietaire], indépendant du compte vendeur de l'app).
  final String? proprietaireId;

  /// Preuve de propriété capturée par l'agent (pièce d'identité +
  /// justificatif), obligatoire avant de valider une collecte.
  final ProofType? preuveProprieteType;
  final String? preuveProprieteValeur;

  const Mission({
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

  Mission copyWith({
    String? id,
    MissionType? type,
    MissionStatus? statut,
    DateTime? dateHeure,
    String? codeConfirmation,
    int? photosCount,
    String? agentId,
    String? referenceId,
    String? notesAgent,
    String? raisonRefus,
    double? latitude,
    double? longitude,
    String? proprietaireId,
    ProofType? preuveProprieteType,
    String? preuveProprieteValeur,
  }) {
    return Mission(
      id: id ?? this.id,
      type: type ?? this.type,
      statut: statut ?? this.statut,
      dateHeure: dateHeure ?? this.dateHeure,
      agentId: agentId ?? this.agentId,
      referenceId: referenceId ?? this.referenceId,
      codeConfirmation: codeConfirmation ?? this.codeConfirmation,
      photosCount: photosCount ?? this.photosCount,
      notesAgent: notesAgent ?? this.notesAgent,
      raisonRefus: raisonRefus ?? this.raisonRefus,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      proprietaireId: proprietaireId ?? this.proprietaireId,
      preuveProprieteType: preuveProprieteType ?? this.preuveProprieteType,
      preuveProprieteValeur: preuveProprieteValeur ?? this.preuveProprieteValeur,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        statut,
        dateHeure,
        codeConfirmation,
        photosCount,
        agentId,
        referenceId,
        notesAgent,
        raisonRefus,
        latitude,
        longitude,
        proprietaireId,
        preuveProprieteType,
        preuveProprieteValeur,
      ];
}
