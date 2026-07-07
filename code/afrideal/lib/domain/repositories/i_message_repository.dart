import '../entities/conversation.dart';
import '../entities/message.dart';

abstract class IMessageRepository {
  Future<List<Conversation>> getConversations(String userId);
  Future<List<Message>> getMessages(String conversationId);
  Future<void> envoyerMessage(Message message);
  Future<void> saveConversation(Conversation conversation);
}
