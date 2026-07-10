import '../entities/conversation.dart';
import '../entities/message.dart';

abstract class IMessageRepository {
  Future<List<Conversation>> getConversations(String userId);

  /// Toutes les conversations, tous participants confondus — vue
  /// globale utilisée par l'admin (voir allConversationsAdminProvider).
  Future<List<Conversation>> getAllConversations();
  Future<Conversation?> getConversationById(String id);
  Future<List<Message>> getMessages(String conversationId);
  Future<void> envoyerMessage(Message message);
  Future<void> saveConversation(Conversation conversation);

  /// Remet à zéro le compteur de messages non lus d'une conversation,
  /// appelé quand son fil est ouvert.
  Future<void> marquerLue(String conversationId);
}
