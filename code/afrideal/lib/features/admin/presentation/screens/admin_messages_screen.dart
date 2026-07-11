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
import '../../../messages/presentation/widgets/conversation_thread.dart';
import '../../../shop/providers/product_list_provider.dart';
import '../../providers/admin_provider.dart';

/// Messagerie admin : contrairement à MessagesScreen (réservée aux
/// conversations où l'utilisateur connecté est participant), cette vue
/// montre TOUTES les questions envoyées par les clients à propos d'un
/// produit — l'admin agit ici comme support central de la plateforme.
///
/// Sur grand écran, vue scindée façon WhatsApp Web : liste des
/// conversations à gauche, fil ouvert à droite, sans navigation entre
/// les deux. Sur petit écran, la liste occupe tout l'écran et ouvrir
/// une conversation pousse un écran plein écran (ConversationScreen).
class AdminMessagesScreen extends ConsumerStatefulWidget {
  const AdminMessagesScreen({super.key});

  @override
  ConsumerState<AdminMessagesScreen> createState() => _AdminMessagesScreenState();
}

class _AdminMessagesScreenState extends ConsumerState<AdminMessagesScreen> {
  String _requete = '';
  String? _selectionId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final estScinde = constraints.maxWidth > 900;

            final liste = _ListePanel(
              requete: _requete,
              onRechercheChange: (v) => setState(() => _requete = v),
              selectionId: estScinde ? _selectionId : null,
              onSelect: (id) {
                if (estScinde) {
                  setState(() => _selectionId = id);
                } else {
                  context.push(AppRoutes.conversation.replaceFirst(':conversationId', id));
                }
              },
            );

            if (!estScinde) return liste;

            return Row(
              children: [
                SizedBox(width: 380, child: liste),
                const VerticalDivider(width: 1, color: AppColors.gray200),
                Expanded(
                  child: _selectionId == null
                      ? const _EtatVideFil()
                      : _FilPanel(conversationId: _selectionId!),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ListePanel extends ConsumerWidget {
  final String requete;
  final ValueChanged<String> onRechercheChange;
  final String? selectionId;
  final ValueChanged<String> onSelect;

  const _ListePanel({
    required this.requete,
    required this.onRechercheChange,
    required this.selectionId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(allConversationsAdminProvider);
    final usersAsync = ref.watch(allUsersAdminProvider);

    return Padding(
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
            onChanged: onRechercheChange,
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

                final req = requete.trim().toLowerCase();
                final filtrees = conversations.where((c) {
                  if (req.isEmpty) return true;
                  final client = c.participantIds
                      .map((id) => utilisateurParId[id]?.nomComplet ?? '')
                      .join(' ')
                      .toLowerCase();
                  return client.contains(req) || c.dernierMessage.toLowerCase().contains(req);
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
                    return _ConversationTile(
                      conversation: conv,
                      client: client,
                      selectionnee: conv.id == selectionId,
                      onTap: () => onSelect(conv.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends ConsumerWidget {
  final Conversation conversation;
  final Utilisateur? client;
  final bool selectionnee;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.client,
    required this.selectionnee,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nonLu = conversation.nombreNonLus > 0;
    final produitId = conversation.produitId;

    return Container(
      color: selectionnee ? AppColors.violetSurface : null,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
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
            Text(
              Formatters.relativeDate(conversation.dateDernierMessage),
              style: AppTypography.caption,
            ),
            if (nonLu) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(color: AppColors.violet, shape: BoxShape.circle),
                child: Text(
                  '${conversation.nombreNonLus}',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class _EtatVideFil extends StatelessWidget {
  const _EtatVideFil();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.forum_outlined, size: 56, color: AppColors.gray300),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Sélectionnez une conversation',
            style: AppTypography.bodyLarge.copyWith(color: AppColors.gray500),
          ),
        ],
      ),
    );
  }
}

class _FilPanel extends ConsumerWidget {
  final String conversationId;
  const _FilPanel({required this.conversationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(allConversationsAdminProvider);
    final usersAsync = ref.watch(allUsersAdminProvider);

    final conversation = conversationsAsync.valueOrNull
        ?.where((c) => c.id == conversationId)
        .firstOrNull;
    final utilisateurs = usersAsync.valueOrNull ?? const <Utilisateur>[];
    final client = conversation?.participantIds
        .map((id) => utilisateurs.where((u) => u.id == id).firstOrNull)
        .whereType<Utilisateur>()
        .firstOrNull;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.gray200)),
          ),
          child: Row(
            children: [
              AppAvatar(initiales: client?.initiales ?? '?', size: 36),
              const SizedBox(width: AppSpacing.sm),
              Text(client?.nomComplet ?? 'Client', style: AppTypography.titleMedium),
            ],
          ),
        ),
        Expanded(
          // conversationId change de valeur au clic sur une autre
          // conversation : la clé force la recréation du widget (et
          // donc du provider family sous-jacent) plutôt que de laisser
          // l'ancien état affiché pendant le rechargement.
          child: ConversationThread(key: ValueKey(conversationId), conversationId: conversationId),
        ),
      ],
    );
  }
}
