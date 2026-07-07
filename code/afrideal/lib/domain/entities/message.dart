import 'package:equatable/equatable.dart';

/// Message individuel au sein d'une [Conversation].
class Message extends Equatable {
  final String id;
  final String conversationId;
  final String expediteurId;
  final String contenu;
  final DateTime dateEnvoi;
  final bool estLu;

  const Message({
    required this.id,
    required this.conversationId,
    required this.expediteurId,
    required this.contenu,
    required this.dateEnvoi,
    this.estLu = false,
  });

  Message copyWith({
    String? id,
    String? conversationId,
    String? expediteurId,
    String? contenu,
    DateTime? dateEnvoi,
    bool? estLu,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      expediteurId: expediteurId ?? this.expediteurId,
      contenu: contenu ?? this.contenu,
      dateEnvoi: dateEnvoi ?? this.dateEnvoi,
      estLu: estLu ?? this.estLu,
    );
  }

  @override
  List<Object?> get props =>
      [id, conversationId, expediteurId, contenu, dateEnvoi, estLu];
}
