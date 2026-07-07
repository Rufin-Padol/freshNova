import '../../domain/entities/message.dart';

class MessageModel {
  final String id;
  final String conversationId;
  final String expediteurId;
  final String contenu;
  final String dateEnvoi;
  final bool estLu;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.expediteurId,
    required this.contenu,
    required this.dateEnvoi,
    this.estLu = false,
  });

  factory MessageModel.fromEntity(Message e) {
    return MessageModel(
      id: e.id,
      conversationId: e.conversationId,
      expediteurId: e.expediteurId,
      contenu: e.contenu,
      dateEnvoi: e.dateEnvoi.toIso8601String(),
      estLu: e.estLu,
    );
  }

  Message toEntity() {
    return Message(
      id: id,
      conversationId: conversationId,
      expediteurId: expediteurId,
      contenu: contenu,
      dateEnvoi: DateTime.parse(dateEnvoi),
      estLu: estLu,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversationId': conversationId,
        'expediteurId': expediteurId,
        'contenu': contenu,
        'dateEnvoi': dateEnvoi,
        'estLu': estLu,
      };

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      expediteurId: json['expediteurId'] as String,
      contenu: json['contenu'] as String,
      dateEnvoi: json['dateEnvoi'] as String,
      estLu: json['estLu'] as bool? ?? false,
    );
  }
}
