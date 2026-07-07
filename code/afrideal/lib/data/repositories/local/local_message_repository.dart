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
  Future<List<Message>> getMessages(String conversationId) async {
    final all = await _messageStore.getAll();
    final filtered = all.where((m) => m.conversationId == conversationId).toList();
    filtered.sort((a, b) => a.dateEnvoi.compareTo(b.dateEnvoi));
    return filtered.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> envoyerMessage(Message message) async {
    await _messageStore.save(MessageModel.fromEntity(message));
  }

  @override
  Future<void> saveConversation(Conversation conversation) async {
    await _conversationStore.save(ConversationModel.fromEntity(conversation));
  }
}
