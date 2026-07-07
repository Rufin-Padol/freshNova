import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/errors/error_view.dart';
import '../../../../domain/entities/categorie.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/feedback/app_loading_indicator.dart';
import '../../../../shared/widgets/feedback/app_snackbar.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../providers/super_admin_provider.dart';

class SuperAdminCommissionsScreen extends ConsumerWidget {
  const SuperAdminCommissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(allCategoriesAdminProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
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
          Expanded(
            child: categoriesAsync.when(
              loading: () => const AppLoadingIndicator(),
              error: (_, __) => ErrorView(
                message: 'Impossible de charger les catégories.',
                onRetry: () => ref.invalidate(allCategoriesAdminProvider),
              ),
              data: (categories) {
                if (categories.isEmpty) {
                  return const EmptyView(
                    message: 'Aucune catégorie',
                    icon: Icons.category_outlined,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final c = categories[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      title: Text(c.nom, style: AppTypography.titleMedium),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${c.tauxCommission.toStringAsFixed(0)}%',
                            style: AppTypography.titleLarge.copyWith(color: AppColors.violet),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          TextButton(
                            onPressed: () => _ouvrirEdition(context, ref, c),
                            child: const Text('Modifier'),
                          ),
                        ],
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
