import 'package:flutter/material.dart';

/// Statut d'une demande de soumission de produit par un vendeur,
/// avant qu'un agent ne soit assigné (voir Mission pour la suite
/// du processus terrain).
enum SellerRequestStatus {
  enAttente,
  validee,
  refusee,
  agentAssigne,
  terminee;

  String get label {
    switch (this) {
      case SellerRequestStatus.enAttente:
        return 'En attente d\'examen';
      case SellerRequestStatus.validee:
        return 'Validée';
      case SellerRequestStatus.refusee:
        return 'Refusée';
      case SellerRequestStatus.agentAssigne:
        return 'Agent assigné';
      case SellerRequestStatus.terminee:
        return 'Terminée';
    }
  }

  Color get color {
    switch (this) {
      case SellerRequestStatus.enAttente:
        return const Color(0xFFF59E0B);
      case SellerRequestStatus.validee:
        return const Color(0xFF2563EB);
      case SellerRequestStatus.refusee:
        return const Color(0xFFDC2626);
      case SellerRequestStatus.agentAssigne:
        return const Color(0xFF7C3AED);
      case SellerRequestStatus.terminee:
        return const Color(0xFF059669);
    }
  }
}
