import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/errors/error_view.dart';
import '../../../../shared/widgets/cards/app_avatar.dart';
import '../../../../shared/widgets/feedback/app_loading_indicator.dart';
import '../../../../domain/entities/conversation.dart';
import '../../../auth/providers/session_provider.dart';
import '../../../shop/providers/product_list_provider.dart';
import '../../providers/message_provider.dart';

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final convsAsync = ref.watch(myConversationsProvider);
    final moi = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Messages')),
      body: convsAsync.when(
        loading: () => const AppLoadingIndicator(),
        error: (_, __) => ErrorView(
          message: 'Impossible de charger vos messages.',
          onRetry: () => ref.invalidate(myConversationsProvider),
        ),
        data: (convs) {
          if (convs.isEmpty) {
            return const EmptyView(
              message: 'Aucun message',
              subtitle: 'Contactez notre équipe depuis une fiche produit.',
              icon: Icons.chat_bubble_outline_rounded,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            itemCount: convs.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, i) {
              final conv = convs[i];
              final nonLu = conv.nombreNonLus > 0;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                leading: conv.estSupport
                    ? Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shield_rounded, color: AppColors.white, size: 24),
                      )
                    : AppAvatar(
                        initiales: conv.participantIds
                            .where((id) => id != moi?.id)
                            .firstOrNull
                            ?.substring(0, 2)
                            .toUpperCase() ??
                            'AF',
                        size: 48,
                      ),
                title: conv.estSupport
                    ? Text(
                        'Support TrustNova',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: nonLu ? FontWeight.w700 : FontWeight.w600,
                        ),
                      )
                    : _TitreConversation(conv: conv, nonLu: nonLu),
                subtitle: Text(
                  conv.dernierMessage,
                  style: AppTypography.bodySmall.copyWith(
                    color: nonLu ? AppColors.black : AppColors.gray500,
                    fontWeight: nonLu ? FontWeight.w600 : FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.relativeDate(conv.dateDernierMessage),
                      style: AppTypography.caption,
                    ),
                    if (nonLu) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: AppColors.violet,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${conv.nombreNonLus}',
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
                onTap: () => context.push(
                  AppRoutes.conversation.replaceFirst(':conversationId', conv.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _TitreConversation extends ConsumerWidget {
  final Conversation conv;
  final bool nonLu;
  const _TitreConversation({required this.conv, required this.nonLu});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = AppTypography.titleMedium.copyWith(
      fontWeight: nonLu ? FontWeight.w700 : FontWeight.w600,
    );
    final produitId = conv.produitId;
    if (produitId == null) return Text('Conversation', style: style);

    final produitAsync = ref.watch(productDetailProvider(produitId));
    return produitAsync.maybeWhen(
      data: (p) => Text(p?.titre ?? 'Conversation', style: style, maxLines: 1,
          overflow: TextOverflow.ellipsis),
      orElse: () => Text('Conversation', style: style),
    );
  }
}
