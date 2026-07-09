import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/errors/error_view.dart';
import '../../../../domain/entities/commande.dart';
import '../../../../domain/enums/order_status.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/buttons/app_secondary_button.dart';
import '../../../../shared/widgets/cards/info_row.dart';
import '../../../../shared/widgets/cards/status_badge.dart';
import '../../../../shared/widgets/feedback/app_loading_indicator.dart';
import '../../../../shared/widgets/feedback/app_snackbar.dart';
import '../../../shop/providers/product_list_provider.dart';
import '../../providers/admin_provider.dart';

class AdminOrdersScreen extends ConsumerWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(allOrdersAdminProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text('Commandes', style: AppTypography.displayMedium),
          ),
          Expanded(
            child: async.when(
              loading: () => const AppLoadingIndicator(),
              error: (_, __) => const ErrorView(message: 'Impossible de charger les commandes.'),
              data: (commandes) {
                if (commandes.isEmpty) {
                  return const EmptyView(message: 'Aucune commande', icon: Icons.receipt_long_outlined);
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  itemCount: commandes.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final c = commandes[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      onTap: () => _ouvrirDetail(context, ref, c),
                      title: Row(
                        children: [
                          Expanded(child: Text('#${c.reference}', style: AppTypography.titleMedium)),
                          StatusBadge(label: c.statut.label, color: c.statut.color),
                        ],
                      ),
                      subtitle: Text(
                        '${Formatters.currency(c.montantTotal)} · ${Formatters.shortDate(c.dateCommande)}',
                        style: AppTypography.bodySmall,
                      ),
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

  void _ouvrirDetail(BuildContext context, WidgetRef ref, Commande commande) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _AdminOrderDetailSheet(commande: commande),
    );
  }
}

class _AdminOrderDetailSheet extends ConsumerWidget {
  final Commande commande;

  const _AdminOrderDetailSheet({required this.commande});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final produitAsync = ref.watch(productDetailProvider(commande.produitId));

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('#${commande.reference}', style: AppTypography.titleLarge),
              ),
              StatusBadge(label: commande.statut.label, color: commande.statut.color),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          produitAsync.when(
            loading: () => const SizedBox(height: 24),
            error: (_, __) => const SizedBox.shrink(),
            data: (produit) => Text(produit?.titre ?? 'Produit', style: AppTypography.titleMedium),
          ),
          const SizedBox(height: AppSpacing.md),
          InfoRow(
            icon: Icons.payments_outlined,
            label: 'Montant à collecter à la livraison',
            value: Formatters.currency(commande.montantTotal),
          ),
          const SizedBox(height: AppSpacing.md),
          InfoRow(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Paiement',
            value: commande.numeroPaieur != null && commande.numeroPaieur!.isNotEmpty
                ? '${commande.methodePaiement.label} (${commande.numeroPaieur})'
                : commande.methodePaiement.label,
          ),
          const SizedBox(height: AppSpacing.md),
          InfoRow(
            icon: Icons.local_shipping_outlined,
            label: 'Mode de livraison',
            value: commande.modeLivraison.label,
          ),
          const SizedBox(height: AppSpacing.md),
          InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Adresse',
            value: commande.adresseLivraison,
          ),
          const SizedBox(height: AppSpacing.xl),
          if (commande.statut == OrderStatus.pendante)
            AppPrimaryButton(
              label: 'Marquer en livraison',
              onPressed: () => _changerStatut(context, ref, OrderStatus.enLivraison),
            )
          else if (commande.statut == OrderStatus.enLivraison)
            AppPrimaryButton(
              label: 'Marquer livrée et encaissée',
              onPressed: () => _changerStatut(context, ref, OrderStatus.livree),
            ),
          if (commande.statut == OrderStatus.pendante ||
              commande.statut == OrderStatus.enLivraison) ...[
            const SizedBox(height: AppSpacing.sm),
            AppSecondaryButton(
              label: 'Annuler la commande',
              onPressed: () => _changerStatut(context, ref, OrderStatus.annulee),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _changerStatut(BuildContext context, WidgetRef ref, OrderStatus statut) async {
    await ref.read(adminOrderNotifierProvider.notifier).changerStatut(commande.id, statut);
    if (context.mounted) {
      Navigator.of(context).pop();
      AppSnackbar.showSuccess(context, 'Commande mise à jour.');
    }
  }
}
