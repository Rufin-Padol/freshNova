import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/conversation.dart';
import '../../../domain/entities/message.dart';
import '../../../domain/repositories/i_message_repository.dart';
import '../../local/datasources/local_json_store.dart';
import '../../models/conversation_model.dart';
import '../../models/message_model.dart';

class LocalMessageRepository implements IMessageRepository {
  final LocalJsonStore<ConversationModel> _conversationStore =
      LocalJsonStore<ConversationModel>(
    boxName: 'conversations_box',
    toJson: (m) => m.toJson(),
    fromJson: ConversationModel.fromJson,
    idOf: (m) => m.id,
  );

  final LocalJsonStore<MessageModel> _messageStore = LocalJsonStore<MessageModel>(
    boxName: StorageKeys.messagesBox,
    toJson: (m) => m.toJson(),
    fromJson: MessageModel.fromJson,
    idOf: (m) => m.id,
  );

  @override
  Future<List<Conversation>> getConversations(String userId) async {
    final all = await _conversationStore.getAll();
    final filtered = all.where((c) => c.participantIds.contains(userId)).toList();
    filtered.sort((a, b) => b.dateDernierMessage.compareTo(a.dateDernierMessage));
    return filtered.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<Conversation>> getAllConversations() async {
    final all = await _conversationStore.getAll();
    final sorted = [...all]
      ..sort((a, b) => b.dateDernierMessage.compareTo(a.dateDernierMessage));
    return sorted.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Conversation?> getConversationById(String id) async {
    final model = await _conversationStore.getById(id);
    return model?.toEntity();
  }

  @override
  Future<List<Message>> getMessages(String conversationId) async {
    final all = await _messageStore.getAll();
    final filtered = all.where((m) => m.conversationId == conversationId).toList();
    filtered.sort((a, b) => a.dateEnvoi.compareTo(b.dateEnvoi));
    return filtered.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> envoyerMessage(Message message) async {
    await _messageStore.save(MessageModel.fromEntity(message));

    // Tient l'aperçu de la conversation à jour (dernier message, date,
    // compteur de non-lus) — sans ça, la liste des messages affichait
    // toujours l'aperçu du tout premier message, même après des
    // échanges plus récents.
    final conversationModel = await _conversationStore.getById(message.conversationId);
    if (conversationModel == null) return;
    final conversation = conversationModel.toEntity();
    await _conversationStore.save(ConversationModel.fromEntity(conversation.copyWith(
      dernierMessage: message.contenu,
      dateDernierMessage: message.dateEnvoi,
      nombreNonLus: conversation.nombreNonLus + 1,
    )));
  }

  @override
  Future<void> saveConversation(Conversation conversation) async {
    await _conversationStore.save(ConversationModel.fromEntity(conversation));
  }

  @override
  Future<void> marquerLue(String conversationId) async {
    final model = await _conversationStore.getById(conversationId);
    if (model == null || model.nombreNonLus == 0) return;
    final conversation = model.toEntity();
    await _conversationStore.save(
      ConversationModel.fromEntity(conversation.copyWith(nombreNonLus: 0)),
    );
  }
}
