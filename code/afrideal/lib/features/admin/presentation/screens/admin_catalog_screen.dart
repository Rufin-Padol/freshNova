import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/errors/error_view.dart';
import '../../../../domain/enums/product_status.dart';
import '../../../../shared/widgets/cards/status_badge.dart';
import '../../../../shared/widgets/feedback/app_loading_indicator.dart';
import '../../../../shared/widgets/feedback/app_snackbar.dart';
import '../../providers/admin_provider.dart';

class AdminCatalogScreen extends ConsumerWidget {
  const AdminCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final produitsAsync = ref.watch(allProductsAdminProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text('Catalogue produits', style: AppTypography.displayMedium),
          ),
          Expanded(
            child: produitsAsync.when(
              loading: () => const AppLoadingIndicator(),
              error: (_, __) => ErrorView(
                message: 'Impossible de charger le catalogue.',
                onRetry: () => ref.invalidate(allProductsAdminProvider),
              ),
              data: (produits) {
                if (produits.isEmpty) {
                  return const EmptyView(message: 'Aucun produit', icon: Icons.inventory_2_outlined);
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  itemCount: produits.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final p = produits[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      title: Row(
                        children: [
                          Expanded(child: Text(p.titre, style: AppTypography.titleMedium)),
                          StatusBadge(label: p.statut.label, color: p.statut.color),
                        ],
                      ),
                      subtitle: Text(
                        '${Formatters.currency(p.prix)} · ${p.localisation} · ${Formatters.shortDate(p.dateCreation)}',
                        style: AppTypography.bodySmall,
                      ),
                      trailing: p.statut == ProductStatus.soumis || p.statut == ProductStatus.enTraitement
                          ? PopupMenuButton<String>(
                              onSelected: (action) async {
                                final notifier = ref.read(adminProductNotifierProvider.notifier);
                                if (action == 'publier') {
                                  await notifier.changerStatut(p.id, ProductStatus.enVente);
                                  if (context.mounted) AppSnackbar.showSuccess(context, 'Produit publié.');
                                } else if (action == 'refuser') {
                                  await notifier.changerStatut(p.id, ProductStatus.refuse);
                                  if (context.mounted) AppSnackbar.showInfo(context, 'Produit refusé.');
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(value: 'publier', child: Text('Publier en boutique')),
                                const PopupMenuItem(value: 'refuser', child: Text('Refuser')),
                              ],
                            )
                          : null,
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
