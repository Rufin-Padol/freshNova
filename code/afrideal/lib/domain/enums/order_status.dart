import 'package:flutter/material.dart';

/// Statuts de commande conformes au diagramme UML :
/// PENDANTE | PAYEE | EN_LIVRAISON | LIVREE | ANNULEE.
enum OrderStatus {
  pendante,
  payee,
  enLivraison,
  livree,
  annulee;

  String get label {
    switch (this) {
      case OrderStatus.pendante:
        return 'En attente de paiement';
      case OrderStatus.payee:
        return 'Payée';
      case OrderStatus.enLivraison:
        return 'En livraison';
      case OrderStatus.livree:
        return 'Livrée';
      case OrderStatus.annulee:
        return 'Annulée';
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.pendante:
        return const Color(0xFFF59E0B);
      case OrderStatus.payee:
        return const Color(0xFF2563EB);
      case OrderStatus.enLivraison:
        return const Color(0xFF7C3AED);
      case OrderStatus.livree:
        return const Color(0xFF059669);
      case OrderStatus.annulee:
        return const Color(0xFFDC2626);
    }
  }
}

enum DeliveryMode {
  livraison,
  retrait;

  String get label =>
      this == DeliveryMode.livraison ? 'Livraison à domicile' : 'Retrait en point relais';
}
