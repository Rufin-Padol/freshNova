import 'package:equatable/equatable.dart';
import '../enums/payment_status.dart';

/// Entité métier Paiement, conforme au diagramme UML.
class Paiement extends Equatable {
  final String id;
  final double montant;
  final PaymentMethod methode;
  final String reference;
  final PaymentStatus statut;
  final DateTime dateHeure;
  final String numeroPaieur;
  final String commandeId;

  const Paiement({
    required this.id,
    required this.montant,
    required this.methode,
    required this.reference,
    required this.statut,
    required this.dateHeure,
    required this.numeroPaieur,
    required this.commandeId,
  });

  Paiement copyWith({
    String? id,
    double? montant,
    PaymentMethod? methode,
    String? reference,
    PaymentStatus? statut,
    DateTime? dateHeure,
    String? numeroPaieur,
    String? commandeId,
  }) {
    return Paiement(
      id: id ?? this.id,
      montant: montant ?? this.montant,
      methode: methode ?? this.methode,
      reference: reference ?? this.reference,
      statut: statut ?? this.statut,
      dateHeure: dateHeure ?? this.dateHeure,
      numeroPaieur: numeroPaieur ?? this.numeroPaieur,
      commandeId: commandeId ?? this.commandeId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        montant,
        methode,
        reference,
        statut,
        dateHeure,
        numeroPaieur,
        commandeId,
      ];
}
