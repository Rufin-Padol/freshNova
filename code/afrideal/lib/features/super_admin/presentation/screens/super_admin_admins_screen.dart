import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/errors/error_view.dart';
import '../../../../domain/entities/utilisateur.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/cards/app_avatar.dart';
import '../../../../shared/widgets/cards/status_badge.dart';
import '../../../../shared/widgets/feedback/app_loading_indicator.dart';
import '../../../../shared/widgets/feedback/app_snackbar.dart';
import '../../../../shared/widgets/inputs/app_search_field.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../admin/providers/admin_provider.dart';
import '../../providers/super_admin_provider.dart';

class SuperAdminAdminsScreen extends ConsumerStatefulWidget {
  const SuperAdminAdminsScreen({super.key});

  @override
  ConsumerState<SuperAdminAdminsScreen> createState() => _SuperAdminAdminsScreenState();
}

class _SuperAdminAdminsScreenState extends ConsumerState<SuperAdminAdminsScreen> {
  String _requete = '';

  @override
  Widget build(BuildContext context) {
    final adminsAsync = ref.watch(adminAccountsProvider);

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
                  Text('Administrateurs', style: AppTypography.displayMedium),
                  FilledButton.icon(
                    onPressed: () => _ouvrirCreation(context, ref),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Nouvel admin'),
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
                      hint: 'Rechercher un administrateur...',
                      onChanged: (v) => setState(() => _requete = v),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    adminsAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: Center(child: AppLoadingIndicator()),
                      ),
                      error: (_, __) => ErrorView(
                        message: 'Impossible de charger les administrateurs.',
                        onRetry: () => ref.invalidate(adminAccountsProvider),
                      ),
                      data: (admins) {
                        final req = _requete.trim().toLowerCase();
                        final filtres = admins
                            .where((a) => req.isEmpty || a.nomComplet.toLowerCase().contains(req))
                            .toList();

                        if (filtres.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                            child: EmptyView(
                              message: 'Aucun administrateur',
                              icon: Icons.admin_panel_settings_outlined,
                            ),
                          );
                        }

                        return Column(
                          children: [
                            for (final a in filtres) ...[
                              _AdminTile(admin: a),
                              if (a != filtres.last) const Divider(height: 1),
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

class _AdminTile extends ConsumerWidget {
  final Utilisateur admin;
  const _AdminTile({required this.admin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          AppAvatar(initiales: admin.initiales, size: 44),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(admin.nomComplet, style: AppTypography.titleMedium),
                const SizedBox(height: 2),
                Text(admin.telephone, style: AppTypography.bodySmall),
              ],
            ),
          ),
          StatusBadge(
            label: admin.estActif ? 'Actif' : 'Suspendu',
            color: admin.estActif ? AppColors.success : AppColors.danger,
          ),
          const SizedBox(width: AppSpacing.md),
          Switch(
            value: admin.estActif,
            activeThumbColor: AppColors.violet,
            onChanged: (v) => ref.read(adminUserNotifierProvider.notifier).toggleActif(admin.id, v),
          ),
        ],
      ),
    );
  }
}
