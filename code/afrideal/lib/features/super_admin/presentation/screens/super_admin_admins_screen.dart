import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/errors/error_view.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/cards/app_avatar.dart';
import '../../../../shared/widgets/cards/status_badge.dart';
import '../../../../shared/widgets/feedback/app_loading_indicator.dart';
import '../../../../shared/widgets/feedback/app_snackbar.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../admin/providers/admin_provider.dart';
import '../../providers/super_admin_provider.dart';

class SuperAdminAdminsScreen extends ConsumerWidget {
  const SuperAdminAdminsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminsAsync = ref.watch(adminAccountsProvider);

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
                Text('Administrateurs', style: AppTypography.displayMedium),
                TextButton.icon(
                  onPressed: () => _ouvrirCreation(context, ref),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nouvel admin'),
                ),
              ],
            ),
          ),
          Expanded(
            child: adminsAsync.when(
              loading: () => const AppLoadingIndicator(),
              error: (_, __) => ErrorView(
                message: 'Impossible de charger les administrateurs.',
                onRetry: () => ref.invalidate(adminAccountsProvider),
              ),
              data: (admins) {
                if (admins.isEmpty) {
                  return const EmptyView(
                    message: 'Aucun administrateur',
                    icon: Icons.admin_panel_settings_outlined,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  itemCount: admins.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final a = admins[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      leading: AppAvatar(initiales: a.initiales, size: 44),
                      title: Row(
                        children: [
                          Expanded(child: Text(a.nomComplet, style: AppTypography.titleMedium)),
                          StatusBadge(
                            label: a.estActif ? 'Actif' : 'Suspendu',
                            color: a.estActif ? AppColors.success : AppColors.danger,
                          ),
                        ],
                      ),
                      subtitle: Text(a.telephone, style: AppTypography.bodySmall),
                      trailing: Switch(
                        value: a.estActif,
                        onChanged: (v) =>
                            ref.read(adminUserNotifierProvider.notifier).toggleActif(a.id, v),
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

  Future<void> _ouvrirCreation(BuildContext context, WidgetRef ref) async {
    final nomCtrl = TextEditingController();
    final prenomCtrl = TextEditingController();
    final telCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    final confirme = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nouveau compte admin'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(label: 'Prénom', controller: prenomCtrl),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(label: 'Nom', controller: nomCtrl),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                label: 'Téléphone',
                controller: telCtrl,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(label: 'Mot de passe', controller: passCtrl, obscureText: true),
            ],
          ),
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

    if (nomCtrl.text.trim().isEmpty ||
        prenomCtrl.text.trim().isEmpty ||
        telCtrl.text.trim().isEmpty ||
        passCtrl.text.trim().isEmpty) {
      AppSnackbar.showError(context, 'Tous les champs sont obligatoires.');
      return;
    }

    try {
      await ref.read(superAdminNotifierProvider.notifier).creerAdmin(
            nom: nomCtrl.text.trim(),
            prenom: prenomCtrl.text.trim(),
            telephone: telCtrl.text.trim(),
            motDePasse: passCtrl.text.trim(),
          );
      if (context.mounted) AppSnackbar.showSuccess(context, 'Compte admin créé.');
    } catch (e) {
      if (context.mounted) AppSnackbar.showError(context, 'Création impossible : $e');
    }
  }
}
