import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/errors/error_view.dart';
import '../../../../domain/entities/conversation.dart';
import '../../../../domain/entities/utilisateur.dart';
import '../../../../shared/widgets/cards/app_avatar.dart';
import '../../../../shared/widgets/feedback/app_loading_indicator.dart';
import '../../../../shared/widgets/inputs/app_search_field.dart';
import '../../../shop/providers/product_list_provider.dart';
import '../../providers/admin_provider.dart';

/// Messagerie admin : contrairement à MessagesScreen (réservée aux
/// conversations où l'utilisateur connecté est participant), cette vue
/// montre TOUTES les questions envoyées par les clients à propos d'un
/// produit — l'admin agit ici comme support central de la plateforme,
/// pas comme un simple participant parmi d'autres.
class AdminMessagesScreen extends ConsumerStatefulWidget {
  const AdminMessagesScreen({super.key});

  @override
  ConsumerState<AdminMessagesScreen> createState() => _AdminMessagesScreenState();
}

class _AdminMessagesScreenState extends ConsumerState<AdminMessagesScreen> {
  String _requete = '';

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(allConversationsAdminProvider);
    final usersAsync = ref.watch(allUsersAdminProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Messages', style: AppTypography.displayMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Questions envoyées par les clients à propos d\'un produit.',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppSearchField(
                hint: 'Rechercher un client ou un message...',
                onChanged: (v) => setState(() => _requete = v.trim().toLowerCase()),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: conversationsAsync.when(
                  loading: () => const AppLoadingIndicator(),
                  error: (_, __) => ErrorView(
                    message: 'Impossible de charger les messages.',
                    onRetry: () => ref.invalidate(allConversationsAdminProvider),
                  ),
                  data: (conversations) {
                    final utilisateurs = usersAsync.valueOrNull ?? const <Utilisateur>[];
                    final utilisateurParId = {for (final u in utilisateurs) u.id: u};

                    final filtrees = conversations.where((c) {
                      if (_requete.isEmpty) return true;
                      final client = c.participantIds
                          .map((id) => utilisateurParId[id]?.nomComplet ?? '')
                          .join(' ')
                          .toLowerCase();
                      return client.contains(_requete) ||
                          c.dernierMessage.toLowerCase().contains(_requete);
                    }).toList();

                    if (filtrees.isEmpty) {
                      return const EmptyView(
                        message: 'Aucun message',
                        subtitle: 'Les questions des clients sur un produit apparaîtront ici.',
                        icon: Icons.chat_bubble_outline_rounded,
                      );
                    }

                    return ListView.separated(
                      itemCount: filtrees.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final conv = filtrees[i];
                        final client = conv.participantIds
                            .map((id) => utilisateurParId[id])
                            .whereType<Utilisateur>()
                            .firstOrNull;
                        return _ConversationTile(conversation: conv, client: client);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationTile extends ConsumerWidget {
  final Conversation conversation;
  final Utilisateur? client;

  const _ConversationTile({required this.conversation, required this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nonLu = conversation.nombreNonLus > 0;
    final produitId = conversation.produitId;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      leading: AppAvatar(initiales: client?.initiales ?? '?', size: 44),
      title: Text(
        client?.nomComplet ?? 'Client',
        style: AppTypography.titleMedium.copyWith(
          fontWeight: nonLu ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (produitId != null)
            Consumer(
              builder: (context, ref, _) {
                final produitAsync = ref.watch(productDetailProvider(produitId));
                return produitAsync.maybeWhen(
                  data: (p) => p == null
                      ? const SizedBox.shrink()
                      : Text(
                          'À propos de : ${p.titre}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.violet,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                  orElse: () => const SizedBox.shrink(),
                );
              },
            ),
          Text(
            conversation.dernierMessage.isEmpty
                ? 'Aucun message pour l\'instant'
                : conversation.dernierMessage,
            style: AppTypography.bodySmall.copyWith(
              color: nonLu ? AppColors.black : AppColors.gray500,
              fontWeight: nonLu ? FontWeight.w600 : FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      isThreeLine: produitId != null,
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(Formatters.relativeDate(conversation.dateDernierMessage), style: AppTypography.caption),
          if (nonLu) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(color: AppColors.violet, shape: BoxShape.circle),
              child: Text(
                '${conversation.nombreNonLus}',
                style: const TextStyle(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
      onTap: () => context.push(
        AppRoutes.conversation.replaceFirst(':conversationId', conversation.id),
      ),
    );
  }
}
