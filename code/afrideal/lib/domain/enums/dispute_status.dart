import 'package:flutter/material.dart';

enum DisputeStatus {
  ouvert,
  enExamen,
  resolu,
  rejete;

  String get label {
    switch (this) {
      case DisputeStatus.ouvert:
        return 'Ouvert';
      case DisputeStatus.enExamen:
        return 'En examen';
      case DisputeStatus.resolu:
        return 'Résolu';
      case DisputeStatus.rejete:
        return 'Rejeté';
    }
  }

  Color get color {
    switch (this) {
      case DisputeStatus.ouvert:
        return const Color(0xFFDC2626);
      case DisputeStatus.enExamen:
        return const Color(0xFFF59E0B);
      case DisputeStatus.resolu:
        return const Color(0xFF059669);
      case DisputeStatus.rejete:
        return const Color(0xFF6B7280);
    }
  }
}
