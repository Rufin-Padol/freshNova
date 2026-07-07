import 'package:flutter/material.dart';

/// Type de mission confiée à un agent terrain, conforme au diagramme
/// UML : COLLECTE ou LIVRAISON.
enum MissionType {
  collecte,
  livraison;

  String get label => this == MissionType.collecte ? 'Collecte' : 'Livraison';
}

/// Statut d'avancement d'une mission, conforme au diagramme UML :
/// COLLECTE | LIVRAISON | COMPLETE | ECHEC (réinterprété ici comme un
/// statut de progression distinct du type, pour éviter toute ambiguïté
/// entre "type de mission" et "où en est la mission").
enum MissionStatus {
  assignee,
  enRoute,
  surSite,
  complete,
  echec;

  String get label {
    switch (this) {
      case MissionStatus.assignee:
        return 'Assignée';
      case MissionStatus.enRoute:
        return 'En route';
      case MissionStatus.surSite:
        return 'Sur site';
      case MissionStatus.complete:
        return 'Complétée';
      case MissionStatus.echec:
        return 'Échec';
    }
  }

  Color get color {
    switch (this) {
      case MissionStatus.assignee:
        return const Color(0xFFF59E0B);
      case MissionStatus.enRoute:
        return const Color(0xFF2563EB);
      case MissionStatus.surSite:
        return const Color(0xFF7C3AED);
      case MissionStatus.complete:
        return const Color(0xFF059669);
      case MissionStatus.echec:
        return const Color(0xFFDC2626);
    }
  }
}
