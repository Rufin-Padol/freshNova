import 'package:equatable/equatable.dart';
import '../enums/order_status.dart';

/// Entité métier Commande, conforme au diagramme UML.
class Commande extends Equatable {
  final String id;
  final String reference;
  final double montantTotal;
  final OrderStatus statut;
  final DateTime dateCommande;
  final DeliveryMode modeLivraison;
  final String adresseLivraison;

  final String acheteurId;
  final String produitId;

  /// Identifiant de la mission de livraison associée, renseigné une
  /// fois qu'un agent a été assigné pour livrer la commande.
  final String? missionLivraisonId;

  const Commande({
    required this.id,
    required this.reference,
    required this.montantTotal,
    required this.statut,
    required this.dateCommande,
    required this.modeLivraison,
    required this.adresseLivraison,
    required this.acheteurId,
    required this.produitId,
    this.missionLivraisonId,
  });

  Commande copyWith({
    String? id,
    String? reference,
    double? montantTotal,
    OrderStatus? statut,
    DateTime? dateCommande,
    DeliveryMode? modeLivraison,
    String? adresseLivraison,
    String? acheteurId,
    String? produitId,
    String? missionLivraisonId,
  }) {
    return Commande(
      id: id ?? this.id,
      reference: reference ?? this.reference,
      montantTotal: montantTotal ?? this.montantTotal,
      statut: statut ?? this.statut,
      dateCommande: dateCommande ?? this.dateCommande,
      modeLivraison: modeLivraison ?? this.modeLivraison,
      adresseLivraison: adresseLivraison ?? this.adresseLivraison,
      acheteurId: acheteurId ?? this.acheteurId,
      produitId: produitId ?? this.produitId,
      missionLivraisonId: missionLivraisonId ?? this.missionLivraisonId,
    );
  }

  /// Génère une référence de commande lisible, conforme au format
  /// observé dans le scénario d'achat (#CM-2024-XXXX).
  static String genererReference(int sequence, {int? annee}) {
    final year = annee ?? DateTime.now().year;
    return 'CM-$year-${sequence.toString().padLeft(4, '0')}';
  }

  @override
  List<Object?> get props => [
        id,
        reference,
        montantTotal,
        statut,
        dateCommande,
        modeLivraison,
        adresseLivraison,
        acheteurId,
        produitId,
        missionLivraisonId,
      ];
}
