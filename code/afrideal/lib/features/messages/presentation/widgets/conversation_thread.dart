import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/errors/error_view.dart';
import '../../../../shared/widgets/feedback/app_loading_indicator.dart';
import '../../../../shared/widgets/illustrations/empty_image_illustration.dart';
import '../../../auth/providers/session_provider.dart';
import '../../../shop/providers/product_list_provider.dart';
import '../../providers/message_provider.dart';

/// Fil de discussion (bandeau produit + messages + zone de saisie),
/// extrait de ConversationScreen pour être réutilisable tel quel dans
/// un contexte plein écran (mobile) comme dans un panneau intégré à
/// une vue scindée façon WhatsApp (voir AdminMessagesScreen).
class ConversationThread extends ConsumerStatefulWidget {
  final String conversationId;
  const ConversationThread({super.key, required this.conversationId});

  @override
  ConsumerState<ConversationThread> createState() => _ConversationThreadState();
}

class _ConversationThreadState extends ConsumerState<ConversationThread> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _envoyer() {
    final texte = _controller.text.trim();
    if (texte.isEmpty) return;
    _controller.clear();
    ref.read(conversationNotifierProvider(widget.conversationId).notifier).envoyer(texte);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final msgsState = ref.watch(conversationNotifierProvider(widget.conversationId));
    final moi = ref.watch(currentUserProvider);
    final conversationAsync = ref.watch(conversationByIdProvider(widget.conversationId));

    return Column(
      children: [
        conversationAsync.maybeWhen(
          data: (conv) {
            final produitId = conv?.produitId;
            if (produitId == null) return const SizedBox.shrink();
            return _BandeauProduit(produitId: produitId);
          },
          orElse: () => const SizedBox.shrink(),
        ),
        Expanded(
          child: msgsState.when(
            loading: () => const AppLoadingIndicator(),
            error: (_, __) => const ErrorView(message: 'Impossible de charger la conversation.'),
            data: (msgs) => ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: msgs.length,
              itemBuilder: (context, i) {
                final msg = msgs[i];
                final estMoi = msg.expediteurId == moi?.id;
                return Align(
                  alignment: estMoi ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.72,
                    ),
                    decoration: BoxDecoration(
                      // Fond gris plein (pas juste blanc avec un fin
                      // contour) pour que les messages de l'AUTRE
                      // participant restent nettement visibles même
                      // sur le fond très clair de l'écran — un simple
                      // contour se distinguait mal à l'œil.
                      color: estMoi ? AppColors.violet : AppColors.gray100,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(AppRadius.md),
                        topRight: const Radius.circular(AppRadius.md),
                        bottomLeft: Radius.circular(estMoi ? AppRadius.md : AppRadius.sm),
                        bottomRight: Radius.circular(estMoi ? AppRadius.sm : AppRadius.md),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          msg.contenu,
                          style: AppTypography.bodyLarge.copyWith(
                            color: estMoi ? AppColors.white : AppColors.black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          Formatters.dateWithTime(msg.dateEnvoi),
                          style: AppTypography.caption.copyWith(
                            color: estMoi
                                ? AppColors.white.withValues(alpha: 0.7)
                                : AppColors.gray500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.gray200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Votre message...',
                      border: InputBorder.none,
                      filled: false,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _envoyer(),
                  ),
                ),
                IconButton(
                  onPressed: _envoyer,
                  icon: const Icon(Icons.send_rounded, color: AppColors.violet),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Bandeau de contexte affiché en haut du fil quand la conversation
/// porte sur un produit précis — rappelle de quoi il est question
/// sans jamais exposer d'information sur le propriétaire du bien.
class _BandeauProduit extends ConsumerWidget {
  final String produitId;
  const _BandeauProduit({required this.produitId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final produitAsync = ref.watch(productDetailProvider(produitId));

    return produitAsync.maybeWhen(
      data: (produit) {
        if (produit == null) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          color: AppColors.violetSurface,
          child: Row(
            children: [
              ClipRRect(
                borderRadius: AppRadius.smRadius,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: produit.photoPrincipale != null
                      ? Image.network(produit.photoPrincipale!.url, fit: BoxFit.cover)
                      : const EmptyImageIllustration(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  produit.titre,
                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
