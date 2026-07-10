import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/errors/error_view.dart';
import '../../../../domain/enums/order_status.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../domain/entities/produit.dart';
import '../../../../shared/widgets/cards/info_row.dart';
import '../../../../shared/widgets/feedback/app_loading_indicator.dart';
import '../../../../shared/widgets/layout/progress_steps.dart';
import '../../providers/order_list_provider.dart';

/// Suivi détaillé d'une commande, avec barre de progression visuelle
/// de l'avancement (Confirmée → En livraison → Livrée). Le paiement
/// (espèces ou Mobile Money) n'a lieu qu'à la livraison — jamais
/// avant, d'où le libellé "à régler à la livraison" tant que la
/// commande n'est pas encore livrée.
class OrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commandeAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Suivi de commande')),
      body: commandeAsync.when(
        loading: () => const AppLoadingIndicator(),
        error: (_, __) => ErrorView(
          message: 'Impossible de charger cette commande.',
          onRetry: () => ref.invalidate(orderDetailProvider(orderId)),
        ),
        data: (commande) {
          if (commande == null) {
            return const ErrorView(message: 'Commande introuvable.');
          }
          final productRepo = ref.watch(productRepositoryProvider);
          final etapeIndex = _etapeIndexPourStatut(commande.statut);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('#${commande.reference}', style: AppTypography.displayMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  Formatters.dateWithTime(commande.dateCommande),
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xxl),
                if (commande.statut != OrderStatus.annulee)
                  ProgressSteps(
                    steps: const ['Confirmée', 'Livraison', 'Livrée'],
                    currentIndex: etapeIndex,
                  ),
                const SizedBox(height: AppSpacing.xxl),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.lgRadius,
                    border: Border.all(color: AppColors.gray200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<List<Produit>>(
                        future: Future.wait(
                          commande.lignes.keys.map((id) => productRepo.getById(id)),
                        ).then((liste) => liste.whereType<Produit>().toList()),
                        builder: (context, snapshot) {
                          final produits = snapshot.data;
                          if (produits == null) return const SizedBox(height: 24);
                          if (produits.isEmpty) {
                            return Text('Produit', style: AppTypography.titleLarge);
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final produit in produits)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          (commande.lignes[produit.id] ?? 1) > 1
                                              ? '${produit.titre} × ${commande.lignes[produit.id]}'
                                              : produit.titre,
                                          style: AppTypography.titleLarge,
                                        ),
                                      ),
                                      Text(
                                        Formatters.currency(
                                          produit.prix * (commande.lignes[produit.id] ?? 1),
                                        ),
                                        style: AppTypography.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      InfoRow(
                        icon: Icons.payments_outlined,
                        label: commande.statut == OrderStatus.livree
                            ? 'Montant payé'
                            : 'Montant à régler à la livraison',
                        value: Formatters.currency(commande.montantTotal),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      InfoRow(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'Mode de paiement',
                        value: commande.methodePaiement.label,
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
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  int _etapeIndexPourStatut(OrderStatus statut) {
    switch (statut) {
      case OrderStatus.pendante:
        return 0;
      case OrderStatus.payee:
        return 0;
      case OrderStatus.enLivraison:
        return 1;
      case OrderStatus.livree:
        return 2;
      case OrderStatus.annulee:
        return 0;
    }
  }
}
