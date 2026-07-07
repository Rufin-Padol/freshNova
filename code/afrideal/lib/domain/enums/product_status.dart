import 'package:flutter/material.dart';

/// Cycle de vie complet d'un produit, conforme à la section "États du
/// produit" du cahier des charges. 8 états normaux séquentiels, plus
/// 4 états d'exception qui peuvent survenir à différents moments.
///
/// IMPORTANT : ces statuts sont la référence UNIQUE utilisée par tous
/// les rôles (Vendeur, Agent, Admin) pour savoir où en est un produit.
/// Zéro ambiguïté, comme exigé par le cahier des charges.
enum ProductStatus {
  // ── Cycle normal ──
  soumis,
  missionAssignee,
  enVerification,
  collecte,
  enTraitement,
  enVente,
  reserve,
  enLivraison,
  livre,

  // ── États d'exception ──
  refuse,
  annule,
  indisponible,
  expire;

  String get label {
    switch (this) {
      case ProductStatus.soumis:
        return 'Soumis';
      case ProductStatus.missionAssignee:
        return 'Mission assignée';
      case ProductStatus.enVerification:
        return 'En vérification';
      case ProductStatus.collecte:
        return 'Collecté';
      case ProductStatus.enTraitement:
        return 'En traitement';
      case ProductStatus.enVente:
        return 'En vente';
      case ProductStatus.reserve:
        return 'Réservé';
      case ProductStatus.enLivraison:
        return 'En livraison';
      case ProductStatus.livre:
        return 'Livré';
      case ProductStatus.refuse:
        return 'Refusé';
      case ProductStatus.annule:
        return 'Annulé';
      case ProductStatus.indisponible:
        return 'Indisponible';
      case ProductStatus.expire:
        return 'Expiré';
    }
  }

  /// Courte explication affichée à l'utilisateur, reprise du cahier
  /// des charges, pour qu'il comprenne exactement où en est son produit
  /// sans avoir besoin d'aide extérieure.
  String get description {
    switch (this) {
      case ProductStatus.soumis:
        return 'Demande reçue, en attente d\'assignation.';
      case ProductStatus.missionAssignee:
        return 'Un agent a été désigné pour la collecte.';
      case ProductStatus.enVerification:
        return 'L\'agent est chez le vendeur pour vérification.';
      case ProductStatus.collecte:
        return 'Le produit a été récupéré par l\'agent.';
      case ProductStatus.enTraitement:
        return 'Photos et fiche produit en préparation.';
      case ProductStatus.enVente:
        return 'Publié et visible sur la boutique.';
      case ProductStatus.reserve:
        return 'Paiement en attente de confirmation.';
      case ProductStatus.enLivraison:
        return 'En cours de remise à l\'acheteur.';
      case ProductStatus.livre:
        return 'Transaction terminée avec succès.';
      case ProductStatus.refuse:
        return 'Propriété non prouvée lors de la visite.';
      case ProductStatus.annule:
        return 'Le vendeur a annulé avant la collecte.';
      case ProductStatus.indisponible:
        return 'Produit endommagé ou perdu après collecte.';
      case ProductStatus.expire:
        return 'En vente depuis trop longtemps, retourné au vendeur.';
    }
  }

  bool get isException =>
      this == ProductStatus.refuse ||
      this == ProductStatus.annule ||
      this == ProductStatus.indisponible ||
      this == ProductStatus.expire;

  /// Indique si le produit peut être affiché et acheté dans la boutique.
  bool get isPurchasable => this == ProductStatus.enVente;

  Color get color {
    switch (this) {
      case ProductStatus.soumis:
        return const Color(0xFFF59E0B);
      case ProductStatus.missionAssignee:
        return const Color(0xFF2563EB);
      case ProductStatus.enVerification:
        return const Color(0xFF7C3AED);
      case ProductStatus.collecte:
      case ProductStatus.enTraitement:
        return const Color(0xFF0D9488);
      case ProductStatus.enVente:
        return const Color(0xFF059669);
      case ProductStatus.reserve:
        return const Color(0xFF5B21B6);
      case ProductStatus.enLivraison:
        return const Color(0xFF2563EB);
      case ProductStatus.livre:
        return const Color(0xFF166534);
      case ProductStatus.refuse:
      case ProductStatus.indisponible:
        return const Color(0xFFDC2626);
      case ProductStatus.annule:
        return const Color(0xFF6B7280);
      case ProductStatus.expire:
        return const Color(0xFF9CA3AF);
    }
  }

  /// Ordre d'avancement dans le cycle normal, utilisé pour dessiner une
  /// barre de progression. Les états d'exception renvoient -1 (ils
  /// sortent du flux normal et sont affichés différemment).
  int get progressIndex {
    const order = [
      ProductStatus.soumis,
      ProductStatus.missionAssignee,
      ProductStatus.enVerification,
      ProductStatus.collecte,
      ProductStatus.enTraitement,
      ProductStatus.enVente,
      ProductStatus.reserve,
      ProductStatus.enLivraison,
      ProductStatus.livre,
    ];
    final idx = order.indexOf(this);
    return idx;
  }
}

/// État physique du produit (différent du statut de cycle de vie).
/// Renseigné par l'agent terrain lors de la vérification.
enum ProductCondition {
  neuf,
  commeNeuf,
  bonEtat,
  etatCorrect,
  defautConnu;

  String get label {
    switch (this) {
      case ProductCondition.neuf:
        return 'Neuf';
      case ProductCondition.commeNeuf:
        return 'Comme neuf';
      case ProductCondition.bonEtat:
        return 'Bon état';
      case ProductCondition.etatCorrect:
        return 'État correct';
      case ProductCondition.defautConnu:
        return 'Défaut connu';
    }
  }
}
