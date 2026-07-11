import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/errors/error_view.dart';
import '../../../../domain/entities/categorie.dart';
import '../../../../domain/entities/produit.dart';
import '../../../../domain/enums/product_status.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/cards/status_badge.dart';
import '../../../../shared/widgets/feedback/app_loading_indicator.dart';
import '../../../../shared/widgets/feedback/app_snackbar.dart';
import '../../../../shared/widgets/inputs/app_search_field.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../shop/providers/category_provider.dart';
import '../../providers/admin_provider.dart';

const _uuid = Uuid();

class AdminCatalogScreen extends ConsumerStatefulWidget {
  const AdminCatalogScreen({super.key});

  @override
  ConsumerState<AdminCatalogScreen> createState() => _AdminCatalogScreenState();
}

class _AdminCatalogScreenState extends ConsumerState<AdminCatalogScreen> {
  String _requete = '';

  @override
  Widget build(BuildContext context) {
    final produitsAsync = ref.watch(allProductsAdminProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Catalogue produits', style: AppTypography.displayMedium),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _creerCategorie(context, ref),
                        icon: const Icon(Icons.category_outlined, size: 18),
                        label: const Text('Nouvelle catégorie'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      FilledButton.icon(
                        onPressed: () => _creerProduit(context, ref),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Créer un produit'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.lgRadius,
                  border: Border.all(color: AppColors.gray200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSearchField(
                      hint: 'Rechercher un produit...',
                      onChanged: (v) => setState(() => _requete = v),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    produitsAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: Center(child: AppLoadingIndicator()),
                      ),
                      error: (_, __) => ErrorView(
                        message: 'Impossible de charger le catalogue.',
                        onRetry: () => ref.invalidate(allProductsAdminProvider),
                      ),
                      data: (produits) {
                        final req = _requete.trim().toLowerCase();
                        final filtres = produits.where((p) {
                          if (req.isEmpty) return true;
                          return p.titre.toLowerCase().contains(req) ||
                              p.localisation.toLowerCase().contains(req);
                        }).toList();

                        if (filtres.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                            child: EmptyView(message: 'Aucun produit', icon: Icons.inventory_2_outlined),
                          );
                        }

                        return LayoutBuilder(
                          builder: (context, constraints) => SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minWidth: constraints.maxWidth),
                              child: DataTable(
                                headingRowHeight: 40,
                                dataRowMinHeight: 52,
                                dataRowMaxHeight: 60,
                                columns: const [
                                  DataColumn(label: Text('Produit')),
                                  DataColumn(label: Text('Prix')),
                                  DataColumn(label: Text('Localisation')),
                                  DataColumn(label: Text('Date')),
                                  DataColumn(label: Text('Statut')),
                                  DataColumn(label: Text('Action')),
                                ],
                                rows: [
                                  for (final p in filtres)
                                    DataRow(cells: [
                                      DataCell(SizedBox(
                                        width: 220,
                                        child: Text(
                                          p.titre,
                                          style: AppTypography.bodyMedium
                                              .copyWith(fontWeight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      )),
                                      DataCell(Text(Formatters.currency(p.prix))),
                                      DataCell(Text(p.localisation)),
                                      DataCell(Text(Formatters.shortDate(p.dateCreation))),
                                      DataCell(StatusBadge(label: p.statut.label, color: p.statut.color)),
                                      DataCell(_ActionCell(produit: p)),
                                    ]),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _creerCategorie(BuildContext context, WidgetRef ref) async {
    final nomCtrl = TextEditingController();
    final commissionCtrl = TextEditingController(text: '10');

    final confirme = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nouvelle catégorie'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(label: 'Nom de la catégorie', controller: nomCtrl),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Taux de commission (%)',
              controller: commissionCtrl,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          AppPrimaryButton(
            label: 'Créer',
            fullWidth: false,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );

    if (confirme != true || !context.mounted) return;

    if (nomCtrl.text.trim().isEmpty) {
      AppSnackbar.showError(context, 'Le nom de la catégorie est obligatoire.');
      return;
    }
    final taux = double.tryParse(commissionCtrl.text.replaceAll(',', '.'));
    if (taux == null || taux < 0 || taux > 100) {
      AppSnackbar.showError(context, 'Taux de commission invalide (0 à 100).');
      return;
    }

    await ref.read(categoryRepositoryProvider).save(Categorie(
          id: _uuid.v4(),
          nom: nomCtrl.text.trim(),
          tauxCommission: taux,
        ));
    ref.invalidate(categoriesProvider);

    if (context.mounted) {
      AppSnackbar.showSuccess(context, 'Catégorie créée.');
    }
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

class _ActionCell extends ConsumerWidget {
  final Produit produit;
  const _ActionCell({required this.produit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (produit.statut == ProductStatus.enTraitement) {
      return TextButton(
        onPressed: () => context.push(
          AppRoutes.adminProductEdit.replaceFirst(':productId', produit.id),
          extra: produit,
        ),
        child: const Text('Rédiger la fiche'),
      );
    }
    if (produit.statut == ProductStatus.soumis) {
      return PopupMenuButton<String>(
        onSelected: (action) async {
          final notifier = ref.read(adminProductNotifierProvider.notifier);
          if (action == 'refuser') {
            await notifier.changerStatut(produit.id, ProductStatus.refuse);
            if (context.mounted) {
              AppSnackbar.showInfo(context, 'Produit refusé.');
            }
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'refuser', child: Text('Refuser')),
        ],
      );
    }
    if (produit.statut == ProductStatus.enVente) {
      return PopupMenuButton<String>(
        onSelected: (action) async {
          final notifier = ref.read(adminProductNotifierProvider.notifier);
          if (action == 'retirer') {
            await notifier.changerStatut(produit.id, ProductStatus.indisponible);
            if (context.mounted) {
              AppSnackbar.showInfo(context, 'Produit retiré de la vente.');
            }
          } else if (action == 'modifier') {
            context.push(
              AppRoutes.adminProductEdit.replaceFirst(':productId', produit.id),
              extra: produit,
            );
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'modifier', child: Text('Modifier la fiche')),
          PopupMenuItem(value: 'retirer', child: Text('Retirer de la vente')),
        ],
      );
    }
    if (produit.statut == ProductStatus.indisponible) {
      return TextButton(
        onPressed: () async {
          await ref
              .read(adminProductNotifierProvider.notifier)
              .changerStatut(produit.id, ProductStatus.enVente);
          if (context.mounted) {
            AppSnackbar.showSuccess(context, 'Produit remis en vente.');
          }
        },
        child: const Text('Remettre en vente'),
      );
    }
    return const SizedBox.shrink();
  }
}
