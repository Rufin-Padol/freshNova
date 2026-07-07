import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/errors/error_view.dart';
import '../../../../domain/entities/categorie.dart';
import '../../../../domain/entities/produit.dart';
import '../../../../domain/enums/product_status.dart';
import '../../../../shared/widgets/cards/status_badge.dart';
import '../../../../shared/widgets/feedback/app_loading_indicator.dart';
import '../../../../shared/widgets/feedback/app_snackbar.dart';
import '../../../shop/providers/category_provider.dart';
import '../../providers/admin_provider.dart';

const _uuid = Uuid();

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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Catalogue produits', style: AppTypography.displayMedium),
                TextButton.icon(
                  onPressed: () => _creerProduit(context, ref),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Créer un produit'),
                ),
              ],
            ),
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
                      trailing: p.statut == ProductStatus.enTraitement
                          ? TextButton(
                              onPressed: () => context.push(
                                AppRoutes.adminProductEdit.replaceFirst(':productId', p.id),
                                extra: p,
                              ),
                              child: const Text('Rédiger la fiche'),
                            )
                          : p.statut == ProductStatus.soumis
                              ? PopupMenuButton<String>(
                                  onSelected: (action) async {
                                    final notifier = ref.read(adminProductNotifierProvider.notifier);
                                    if (action == 'refuser') {
                                      await notifier.changerStatut(p.id, ProductStatus.refuse);
                                      if (context.mounted) {
                                        AppSnackbar.showInfo(context, 'Produit refusé.');
                                      }
                                    }
                                  },
                                  itemBuilder: (_) => [
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

  Future<void> _creerProduit(BuildContext context, WidgetRef ref) async {
    final categories = await ref.read(categoriesProvider.future);
    if (categories.isEmpty) {
      if (context.mounted) {
        AppSnackbar.showError(context, 'Aucune catégorie disponible pour créer un produit.');
      }
      return;
    }

    final categorieChoisie = await showDialog<Categorie>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Choisir une catégorie'),
        children: categories
            .map(
              (c) => SimpleDialogOption(
                onPressed: () => Navigator.of(dialogContext).pop(c),
                child: Text(c.nom),
              ),
            )
            .toList(),
      ),
    );
    if (categorieChoisie == null || !context.mounted) return;

    final produit = Produit(
      id: _uuid.v4(),
      titre: '',
      description: '',
      prix: 0,
      etat: ProductCondition.bonEtat,
      statut: ProductStatus.enTraitement,
      categorieId: categorieChoisie.id,
      dateCreation: DateTime.now(),
      vendeurId: '',
      localisation: '',
      tauxCommission: categorieChoisie.tauxCommission,
    );

    context.push(
      AppRoutes.adminProductEdit.replaceFirst(':productId', produit.id),
      extra: produit,
    );
  }
}
