import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/errors/error_view.dart';
import '../../../../domain/entities/categorie.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/feedback/app_loading_indicator.dart';
import '../../../../shared/widgets/feedback/app_snackbar.dart';
import '../../../../shared/widgets/inputs/app_search_field.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../shop/providers/category_provider.dart';
import '../../providers/super_admin_provider.dart';

const _uuid = Uuid();

class SuperAdminCommissionsScreen extends ConsumerStatefulWidget {
  const SuperAdminCommissionsScreen({super.key});

  @override
  ConsumerState<SuperAdminCommissionsScreen> createState() => _SuperAdminCommissionsScreenState();
}

class _SuperAdminCommissionsScreenState extends ConsumerState<SuperAdminCommissionsScreen> {
  String _requete = '';

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(allCategoriesAdminProvider);

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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Commissions par catégorie', style: AppTypography.displayMedium),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Modification à effet immédiat sur les nouveaux produits assignés.',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _creerCategorie(context, ref),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Nouvelle catégorie'),
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
                      hint: 'Rechercher une catégorie...',
                      onChanged: (v) => setState(() => _requete = v),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    categoriesAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: Center(child: AppLoadingIndicator()),
                      ),
                      error: (_, __) => ErrorView(
                        message: 'Impossible de charger les catégories.',
                        onRetry: () => ref.invalidate(allCategoriesAdminProvider),
                      ),
                      data: (categories) {
                        final req = _requete.trim().toLowerCase();
                        final filtres = categories
                            .where((c) => req.isEmpty || c.nom.toLowerCase().contains(req))
                            .toList();

                        if (filtres.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                            child: EmptyView(message: 'Aucune catégorie', icon: Icons.category_outlined),
                          );
                        }

                        return Column(
                          children: [
                            for (final c in filtres) ...[
                              _CategorieTile(categorie: c),
                              if (c != filtres.last) const Divider(height: 1),
                            ],
                          ],
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
    ref.invalidate(allCategoriesAdminProvider);
    ref.invalidate(categoriesProvider);

    if (context.mounted) {
      AppSnackbar.showSuccess(context, 'Catégorie créée.');
    }
  }
}

class _CategorieTile extends ConsumerWidget {
  final Categorie categorie;
  const _CategorieTile({required this.categorie});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(child: Text(categorie.nom, style: AppTypography.titleMedium)),
          Text(
            '${categorie.tauxCommission.toStringAsFixed(0)}%',
            style: AppTypography.titleLarge.copyWith(color: AppColors.violet),
          ),
          const SizedBox(width: AppSpacing.sm),
          TextButton(
            onPressed: () => _ouvrirEdition(context, ref, categorie),
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  Future<void> _ouvrirEdition(BuildContext context, WidgetRef ref, Categorie categorie) async {
    final ctrl = TextEditingController(text: categorie.tauxCommission.toStringAsFixed(0));

    final confirme = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Commission — ${categorie.nom}'),
        content: AppTextField(
          label: 'Taux (%)',
          controller: ctrl,
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          AppPrimaryButton(
            label: 'Enregistrer',
            fullWidth: false,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );

    if (confirme != true || !context.mounted) return;

    final taux = double.tryParse(ctrl.text.replaceAll(',', '.'));
    if (taux == null || taux < 0 || taux > 100) {
      AppSnackbar.showError(context, 'Taux invalide (0 à 100).');
      return;
    }

    await ref.read(superAdminNotifierProvider.notifier).modifierCommission(categorie, taux);
    if (context.mounted) AppSnackbar.showSuccess(context, 'Commission mise à jour.');
  }
}
