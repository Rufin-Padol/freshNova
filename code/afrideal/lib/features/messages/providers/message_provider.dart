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

/// Détail d'une conversation (utilisé pour afficher le bandeau de
/// contexte produit dans le fil de discussion).
final conversationByIdProvider =
    FutureProvider.family<Conversation?, String>((ref, id) async {
  final repo = ref.watch(messageRepositoryProvider);
  return repo.getConversationById(id);
});

/// Ouvre la conversation liée à un produit pour l'utilisateur connecté
/// — la réutilise si elle existe déjà, sinon en crée une nouvelle.
/// La plupart des échanges doivent porter sur un bien précis plutôt
/// que d'être génériques (le support reste une conversation séparée,
/// voir `estSupport`).
Future<String> ouvrirConversationProduit(WidgetRef ref, String produitId) async {
  final utilisateur = ref.read(currentUserProvider);
  if (utilisateur == null) {
    throw StateError('Connexion requise pour contacter à propos d\'un produit.');
  }

  final repo = ref.read(messageRepositoryProvider);
  final existantes = await repo.getConversations(utilisateur.id);
  for (final c in existantes) {
    if (c.produitId == produitId && !c.estSupport) return c.id;
  }

  final nouvelle = Conversation(
    id: _uuid.v4(),
    participantIds: [utilisateur.id],
    produitId: produitId,
    dernierMessage: '',
    dateDernierMessage: DateTime.now(),
  );
  await repo.saveConversation(nouvelle);
  ref.invalidate(myConversationsProvider);
  return nouvelle.id;
}

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
