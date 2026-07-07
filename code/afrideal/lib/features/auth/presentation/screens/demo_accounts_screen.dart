import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/errors/error_view.dart';
import '../../../../domain/entities/utilisateur.dart';
import '../../../../domain/enums/user_role.dart';
import '../../../../shared/widgets/cards/app_avatar.dart';
import '../../../../shared/widgets/feedback/app_loading_indicator.dart';
import '../../../../shared/widgets/feedback/app_snackbar.dart';
import '../../providers/demo_accounts_provider.dart';
import '../../providers/session_provider.dart';

/// Écran de sélection d'un compte de démonstration.
///
/// Conforme au choix validé : en mode local, l'authentification se
/// fait par sélection directe d'un profil (Acheteur, Vendeur, Agent,
/// Admin, Super Admin) plutôt que par saisie d'identifiants ou OTP.
/// Le routeur redirige ensuite automatiquement vers le bon espace
/// applicatif selon le rôle choisi (voir app_router.dart).
class DemoAccountsScreen extends ConsumerWidget {
  const DemoAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comptesAsync = ref.watch(demoAccountsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Choisir un profil')),
      body: comptesAsync.when(
        loading: () => const AppLoadingIndicator(),
        error: (error, _) => ErrorView(
          message: 'Impossible de charger les comptes de démonstration.',
          onRetry: () => ref.invalidate(demoAccountsProvider),
        ),
        data: (comptes) => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              'Mode démonstration',
              style: AppTypography.headline,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Sélectionnez un profil pour explorer AfriDeal. '
              'Chaque profil donne accès à un espace différent de la plateforme.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xl),
            ...comptes.map((compte) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _DemoAccountTile(
                    utilisateur: compte,
                    onTap: () async {
                      await ref.read(sessionProvider.notifier).loginAsDemo(compte);
                      if (!context.mounted) return;
                      final session = ref.read(sessionProvider);
                      if (session.hasError) {
                        AppSnackbar.showError(context, 'Connexion impossible. Réessayez.');
                      }
                    },
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _DemoAccountTile extends StatelessWidget {
  final Utilisateur utilisateur;
  final VoidCallback onTap;

  const _DemoAccountTile({required this.utilisateur, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.lgRadius,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lgRadius,
          border: Border.all(color: AppColors.gray200),
        ),
        child: Row(
          children: [
            AppAvatar(initiales: utilisateur.initiales, size: 48),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(utilisateur.nomComplet, style: AppTypography.titleMedium),
                  const SizedBox(height: 2),
                  Text(_descriptionRole(utilisateur.role), style: AppTypography.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.gray400),
          ],
        ),
      ),
    );
  }

  String _descriptionRole(UserRole role) {
    switch (role) {
      case UserRole.acheteur:
        return 'Parcourir et acheter des produits';
      case UserRole.vendeur:
        return 'Vendre des produits d\'occasion';
      case UserRole.agentTerrain:
        return 'Vérifier et collecter les produits';
      case UserRole.admin:
        return 'Gérer la plateforme';
      case UserRole.superAdmin:
        return 'Administration générale';
    }
  }
}
