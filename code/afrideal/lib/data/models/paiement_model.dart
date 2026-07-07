import '../../domain/entities/paiement.dart';
import '../../domain/enums/payment_status.dart';

class PaiementModel {
  final String id;
  final double montant;
  final String methode;
  final String reference;
  final String statut;
  final String dateHeure;
  final String numeroPaieur;
  final String commandeId;

  const PaiementModel({
    required this.id,
    required this.montant,
    required this.methode,
    required this.reference,
    required this.statut,
    required this.dateHeure,
    required this.numeroPaieur,
    required this.commandeId,
  });

  factory PaiementModel.fromEntity(Paiement e) {
    return PaiementModel(
      id: e.id,
      montant: e.montant,
      methode: e.methode.name,
      reference: e.reference,
      statut: e.statut.name,
      dateHeure: e.dateHeure.toIso8601String(),
      numeroPaieur: e.numeroPaieur,
      commandeId: e.commandeId,
    );
  }

  Paiement toEntity() {
    return Paiement(
      id: id,
      montant: montant,
      methode: PaymentMethod.values.firstWhere((m) => m.name == methode),
      reference: reference,
      statut: PaymentStatus.values.firstWhere((s) => s.name == statut),
      dateHeure: DateTime.parse(dateHeure),
      numeroPaieur: numeroPaieur,
      commandeId: commandeId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'montant': montant,
        'methode': methode,
        'reference': reference,
        'statut': statut,
        'dateHeure': dateHeure,
        'numeroPaieur': numeroPaieur,
        'commandeId': commandeId,
      };

  factory PaiementModel.fromJson(Map<String, dynamic> json) {
    return PaiementModel(
      id: json['id'] as String,
      montant: (json['montant'] as num).toDouble(),
      methode: json['methode'] as String,
      reference: json['reference'] as String,
      statut: json['statut'] as String,
      dateHeure: json['dateHeure'] as String,
      numeroPaieur: json['numeroPaieur'] as String,
      commandeId: json['commandeId'] as String,
    );
  }
}
