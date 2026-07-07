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

/// Méthodes de paiement disponibles, conformes au cahier des charges
/// (Mobile Money uniquement pour le marché camerounais).
enum PaymentMethod {
  orangeMoney,
  mtnMomo;

  String get label =>
      this == PaymentMethod.orangeMoney ? 'Orange Money' : 'MTN Mobile Money';
}
