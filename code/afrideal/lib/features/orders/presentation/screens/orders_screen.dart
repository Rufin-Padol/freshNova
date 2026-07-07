import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/errors/error_view.dart';
import '../../../../shared/widgets/cards/status_badge.dart';
import '../../../../shared/widgets/feedback/app_loading_indicator.dart';
import '../../providers/order_list_provider.dart';

/// Liste des commandes de l'acheteur, avec statut coloré cohérent
/// avec le système de statut utilisé partout ailleurs dans l'app.
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commandesAsync = ref.watch(myOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mes commandes')),
      body: commandesAsync.when(
        loading: () => const AppLoadingIndicator(),
        error: (_, __) => ErrorView(
          message: 'Impossible de charger vos commandes.',
          onRetry: () => ref.invalidate(myOrdersProvider),
        ),
        data: (commandes) {
          if (commandes.isEmpty) {
            return const EmptyView(
              message: 'Aucune commande pour le moment',
              subtitle: 'Vos achats apparaîtront ici.',
              icon: Icons.receipt_long_outlined,
            );
          }
          return RefreshIndicator(
            color: AppColors.violet,
            onRefresh: () async => ref.invalidate(myOrdersProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: commandes.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final commande = commandes[index];
                return InkWell(
                  onTap: () => context.push(
                    AppRoutes.orderDetail.replaceFirst(':orderId', commande.id),
                  ),
                  borderRadius: AppRadius.lgRadius,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.lgRadius,
                      border: Border.all(color: AppColors.gray200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('#${commande.reference}', style: AppTypography.titleMedium),
                            StatusBadge(
                              label: commande.statut.label,
                              color: commande.statut.color,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          Formatters.shortDate(commande.dateCommande),
                          style: AppTypography.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          Formatters.currency(commande.montantTotal),
                          style: AppTypography.titleMedium.copyWith(color: AppColors.violet),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
