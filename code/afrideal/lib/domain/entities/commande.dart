import 'package:equatable/equatable.dart';
import '../enums/order_status.dart';
import '../enums/payment_status.dart';

/// Entité métier Commande, conforme au diagramme UML.
///
/// Une commande regroupe tous les articles achetés en une fois depuis
/// le panier — pas une commande par article : le paiement (unique,
/// à la livraison) et la livraison portent sur l'ensemble du panier.
///
/// Le paiement se fait à la livraison (espèces ou Mobile Money) : la
/// commande retient donc la méthode choisie par l'acheteur pour que
/// la personne qui livre sache quoi collecter, mais aucun [Paiement]
/// n'est créé avant la livraison effective (voir AdminOrderNotifier).
class Commande extends Equatable {
  final String id;
  final String reference;
  final double montantTotal;
  final OrderStatus statut;
  final DateTime dateCommande;
  final DeliveryMode modeLivraison;
  final String adresseLivraison;
  final PaymentMethod methodePaiement;
  final String? numeroPaieur;

  final String acheteurId;
  final List<String> produitIds;

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
    required this.methodePaiement,
    required this.acheteurId,
    required this.produitIds,
    this.numeroPaieur,
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
    PaymentMethod? methodePaiement,
    String? numeroPaieur,
    String? acheteurId,
    List<String>? produitIds,
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
      methodePaiement: methodePaiement ?? this.methodePaiement,
      numeroPaieur: numeroPaieur ?? this.numeroPaieur,
      acheteurId: acheteurId ?? this.acheteurId,
      produitIds: produitIds ?? this.produitIds,
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
        methodePaiement,
        numeroPaieur,
        acheteurId,
        produitIds,
        missionLivraisonId,
      ];
}
