import '../../domain/entities/commande.dart';
import '../../domain/enums/order_status.dart';
import '../../domain/enums/payment_status.dart';

class CommandeModel {
  final String id;
  final String reference;
  final double montantTotal;
  final String statut;
  final String dateCommande;
  final String modeLivraison;
  final String adresseLivraison;
  final String methodePaiement;
  final String? numeroPaieur;
  final String acheteurId;
  final String produitId;
  final String? missionLivraisonId;

  const CommandeModel({
    required this.id,
    required this.reference,
    required this.montantTotal,
    required this.statut,
    required this.dateCommande,
    required this.modeLivraison,
    required this.adresseLivraison,
    required this.methodePaiement,
    required this.acheteurId,
    required this.produitId,
    this.numeroPaieur,
    this.missionLivraisonId,
  });

  factory CommandeModel.fromEntity(Commande e) {
    return CommandeModel(
      id: e.id,
      reference: e.reference,
      montantTotal: e.montantTotal,
      statut: e.statut.name,
      dateCommande: e.dateCommande.toIso8601String(),
      modeLivraison: e.modeLivraison.name,
      adresseLivraison: e.adresseLivraison,
      methodePaiement: e.methodePaiement.name,
      numeroPaieur: e.numeroPaieur,
      acheteurId: e.acheteurId,
      produitId: e.produitId,
      missionLivraisonId: e.missionLivraisonId,
    );
  }

  Commande toEntity() {
    return Commande(
      id: id,
      reference: reference,
      montantTotal: montantTotal,
      statut: OrderStatus.values.firstWhere((s) => s.name == statut),
      dateCommande: DateTime.parse(dateCommande),
      modeLivraison: DeliveryMode.values.firstWhere((m) => m.name == modeLivraison),
      adresseLivraison: adresseLivraison,
      methodePaiement: PaymentMethod.values.firstWhere((m) => m.name == methodePaiement),
      numeroPaieur: numeroPaieur,
      acheteurId: acheteurId,
      produitId: produitId,
      missionLivraisonId: missionLivraisonId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'reference': reference,
        'montantTotal': montantTotal,
        'statut': statut,
        'dateCommande': dateCommande,
        'modeLivraison': modeLivraison,
        'adresseLivraison': adresseLivraison,
        'methodePaiement': methodePaiement,
        'numeroPaieur': numeroPaieur,
        'acheteurId': acheteurId,
        'produitId': produitId,
        'missionLivraisonId': missionLivraisonId,
      };

  factory CommandeModel.fromJson(Map<String, dynamic> json) {
    return CommandeModel(
      id: json['id'] as String,
      reference: json['reference'] as String,
      montantTotal: (json['montantTotal'] as num).toDouble(),
      statut: json['statut'] as String,
      dateCommande: json['dateCommande'] as String,
      modeLivraison: json['modeLivraison'] as String,
      adresseLivraison: json['adresseLivraison'] as String,
      // Repli sur "espèces" pour les commandes créées avant l'ajout du
      // paiement à la livraison, qui n'ont pas ce champ en local.
      methodePaiement: json['methodePaiement'] as String? ?? PaymentMethod.especes.name,
      numeroPaieur: json['numeroPaieur'] as String?,
      acheteurId: json['acheteurId'] as String,
      produitId: json['produitId'] as String,
      missionLivraisonId: json['missionLivraisonId'] as String?,
    );
  }
}
