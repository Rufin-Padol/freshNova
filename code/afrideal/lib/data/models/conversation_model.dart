import '../../domain/entities/conversation.dart';

class ConversationModel {
  final String id;
  final List<String> participantIds;
  final String? produitId;
  final String dernierMessage;
  final String dateDernierMessage;
  final int nombreNonLus;
  final bool estSupport;

  const ConversationModel({
    required this.id,
    required this.participantIds,
    required this.dernierMessage,
    required this.dateDernierMessage,
    this.produitId,
    this.nombreNonLus = 0,
    this.estSupport = false,
  });

  factory ConversationModel.fromEntity(Conversation e) {
    return ConversationModel(
      id: e.id,
      participantIds: e.participantIds,
      produitId: e.produitId,
      dernierMessage: e.dernierMessage,
      dateDernierMessage: e.dateDernierMessage.toIso8601String(),
      nombreNonLus: e.nombreNonLus,
      estSupport: e.estSupport,
    );
  }

  Conversation toEntity() {
    return Conversation(
      id: id,
      participantIds: participantIds,
      produitId: produitId,
      dernierMessage: dernierMessage,
      dateDernierMessage: DateTime.parse(dateDernierMessage),
      nombreNonLus: nombreNonLus,
      estSupport: estSupport,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'participantIds': participantIds,
        'produitId': produitId,
        'dernierMessage': dernierMessage,
        'dateDernierMessage': dateDernierMessage,
        'nombreNonLus': nombreNonLus,
        'estSupport': estSupport,
      };

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String,
      participantIds: List<String>.from(json['participantIds'] as List),
      produitId: json['produitId'] as String?,
      dernierMessage: json['dernierMessage'] as String,
      dateDernierMessage: json['dateDernierMessage'] as String,
      nombreNonLus: json['nombreNonLus'] as int? ?? 0,
      estSupport: json['estSupport'] as bool? ?? false,
    );
  }
}
