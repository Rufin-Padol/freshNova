import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../domain/entities/conversation.dart';
import '../../../domain/entities/message.dart';
import '../../auth/providers/session_provider.dart';

const _uuid = Uuid();

final myConversationsProvider = FutureProvider<List<Conversation>>((ref) async {
  final utilisateur = ref.watch(currentUserProvider);
  if (utilisateur == null) return [];
  final repo = ref.watch(messageRepositoryProvider);
  return repo.getConversations(utilisateur.id);
});

final conversationMessagesProvider =
    FutureProvider.family<List<Message>, String>((ref, conversationId) async {
  final repo = ref.watch(messageRepositoryProvider);
  return repo.getMessages(conversationId);
});

class ConversationNotifier extends FamilyNotifier<AsyncValue<List<Message>>, String> {
  @override
  AsyncValue<List<Message>> build(String conversationId) {
    _charger();
    return const AsyncLoading();
  }

  Future<void> _charger() async {
    try {
      final repo = ref.read(messageRepositoryProvider);
      final msgs = await repo.getMessages(arg);
      state = AsyncData(msgs);
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }

  Future<void> envoyer(String contenu) async {
    final utilisateur = ref.read(currentUserProvider);
    if (utilisateur == null || contenu.trim().isEmpty) return;
    final repo = ref.read(messageRepositoryProvider);
    final msg = Message(
      id: _uuid.v4(),
      conversationId: arg,
      expediteurId: utilisateur.id,
      contenu: contenu.trim(),
      dateEnvoi: DateTime.now(),
    );
    await repo.envoyerMessage(msg);
    await _charger();
    ref.invalidate(myConversationsProvider);
  }
}

final conversationNotifierProvider = NotifierProviderFamily<ConversationNotifier,
    AsyncValue<List<Message>>, String>(ConversationNotifier.new);
