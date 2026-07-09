import 'package:flutter/material.dart';

/// Statuts de paiement conformes au diagramme UML :
/// EN_ATTENTE | VALIDE | ECHEC | REMBOURSE.
enum PaymentStatus {
  enAttente,
  valide,
  echec,
  rembourse;

  String get label {
    switch (this) {
      case PaymentStatus.enAttente:
        return 'En attente';
      case PaymentStatus.valide:
        return 'Validé';
      case PaymentStatus.echec:
        return 'Échoué';
      case PaymentStatus.rembourse:
        return 'Remboursé';
    }
  }

  Color get color {
    switch (this) {
      case PaymentStatus.enAttente:
        return const Color(0xFFF59E0B);
      case PaymentStatus.valide:
        return const Color(0xFF059669);
      case PaymentStatus.echec:
        return const Color(0xFFDC2626);
      case PaymentStatus.rembourse:
        return const Color(0xFF6B7280);
    }
  }
}

/// Méthodes de paiement disponibles. Le paiement se fait toujours à
/// la livraison — espèces ou Mobile Money remis à la personne qui
/// livre, jamais en ligne au moment de la commande.
enum PaymentMethod {
  especes,
  orangeMoney,
  mtnMomo;

  String get label {
    switch (this) {
      case PaymentMethod.especes:
        return 'Espèces';
      case PaymentMethod.orangeMoney:
        return 'Orange Money';
      case PaymentMethod.mtnMomo:
        return 'MTN Mobile Money';
    }
  }
}
