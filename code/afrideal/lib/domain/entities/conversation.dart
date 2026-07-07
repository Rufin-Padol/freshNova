import 'package:equatable/equatable.dart';

/// Conversation entre deux utilisateurs (ou un utilisateur et le
/// support AfriDeal). Entité ajoutée pour couvrir l'écran "Messages"
/// présent dans les scénarios UX, absent du diagramme de classes
/// d'origine qui se concentrait sur le processus d'achat/vente.
class Conversation extends Equatable {
  final String id;
  final List<String> participantIds;
  final String? produitId;
  final String dernierMessage;
  final DateTime dateDernierMessage;
  final int nombreNonLus;
  final bool estSupport;

  const Conversation({
    required this.id,
    required this.participantIds,
    required this.dernierMessage,
    required this.dateDernierMessage,
    this.produitId,
    this.nombreNonLus = 0,
    this.estSupport = false,
  });

  Conversation copyWith({
    String? id,
    List<String>? participantIds,
    String? produitId,
    String? dernierMessage,
    DateTime? dateDernierMessage,
    int? nombreNonLus,
    bool? estSupport,
  }) {
    return Conversation(
      id: id ?? this.id,
      participantIds: participantIds ?? this.participantIds,
      produitId: produitId ?? this.produitId,
      dernierMessage: dernierMessage ?? this.dernierMessage,
      dateDernierMessage: dateDernierMessage ?? this.dateDernierMessage,
      nombreNonLus: nombreNonLus ?? this.nombreNonLus,
      estSupport: estSupport ?? this.estSupport,
    );
  }

  @override
  List<Object?> get props => [
        id,
        participantIds,
        produitId,
        dernierMessage,
        dateDernierMessage,
        nombreNonLus,
        estSupport,
      ];
}
