import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/local/datasources/hive_service.dart';
import '../../../../data/local/seed/datasources_box_check.dart';
import '../../../../domain/enums/seller_request_status.dart';
import '../../../../domain/enums/user_role.dart';
import '../../../../shared/widgets/cards/app_avatar.dart';
import '../../../../shared/widgets/feedback/app_snackbar.dart';
import '../../../auth/providers/session_provider.dart';
import '../../../sell/providers/sell_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final utilisateur = ref.watch(currentUserProvider);
    if (utilisateur == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mon profil')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Center(
            child: Column(
              children: [
                AppAvatar(initiales: utilisateur.initiales, size: 80),
                const SizedBox(height: AppSpacing.md),
                Text(utilisateur.nomComplet, style: AppTypography.headline),
                const SizedBox(height: 4),
                Text(utilisateur.role.label, style: AppTypography.bodyMedium),
                if (utilisateur.ville != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: AppColors.gray400),
                      const SizedBox(width: 2),
                      Text(utilisateur.ville!, style: AppTypography.bodySmall),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          if (utilisateur.role == UserRole.acheteur) ...[
            _SectionTitre('Vendre'),
            _MesAnnoncesCard(),
            const SizedBox(height: AppSpacing.xl),
          ],
          _SectionTitre('Informations'),
          _InfoTile(Icons.phone_outlined, 'Téléphone', utilisateur.telephone),
          _InfoTile(Icons.badge_outlined, 'Rôle', utilisateur.role.label),
          if (utilisateur.noteVendeur != null)
            _InfoTile(Icons.star_outline_rounded, 'Note vendeur',
                '${utilisateur.noteVendeur!.toStringAsFixed(1)} / 5.0'),
          const SizedBox(height: AppSpacing.xl),
          _SectionTitre('Application'),
          _InfoTile(
            AppConfig.isLocal ? Icons.storage_outlined : Icons.cloud_outlined,
            'Mode de données',
            AppConfig.isLocal ? 'Données locales' : 'API connectée',
          ),
          const SizedBox(height: AppSpacing.xl),
          if (AppConfig.isLocal) ...[
            _SectionTitre('Développement'),
            ListTile(
              leading: const Icon(Icons.refresh_rounded, color: AppColors.warning),
              title: Text('Réinitialiser les données de démo',
                  style: AppTypography.bodyLarge.copyWith(color: AppColors.warning)),
              onTap: () async {
                await HiveService.clearAll();
                await DemoSeedCheck.resetSeedFlag();
                if (context.mounted) {
                  AppSnackbar.showInfo(context, 'Données réinitialisées. Relancez l\'app.');
                }
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.danger),
            title: Text('Se déconnecter',
                style: AppTypography.bodyLarge.copyWith(color: AppColors.danger)),
            onTap: () async {
              await ref.read(sessionProvider.notifier).logout();
            },
          ),
          const SizedBox(height: AppSpacing.huge),
        ],
      ),
    );
  }
}

/// Point d'entrée vers la vente, accessible depuis le profil de tout
/// utilisateur connecté — pas besoin d'un rôle "vendeur" distinct pour
/// soumettre un bien, à la manière d'un profil Facebook où chacun peut
/// aussi bien consulter que publier une annonce.
class _MesAnnoncesCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demandesAsync = ref.watch(mySellerRequestsProvider);
    final enCours = demandesAsync.valueOrNull
            ?.where((d) => d.statut != SellerRequestStatus.terminee)
            .length ??
        0;

    return InkWell(
      onTap: () => context.push(AppRoutes.sellHome),
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
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.violetSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_box_outlined, color: AppColors.violet),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Vendre un bien', style: AppTypography.titleMedium),
                  Text(
                    enCours > 0
                        ? '$enCours demande${enCours > 1 ? 's' : ''} en cours'
                        : 'Soumettez un produit, un agent le vérifiera chez vous',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.gray400),
          ],
        ),
      ),
    );
  }
}

class _SectionTitre extends StatelessWidget {
  final String titre;
  const _SectionTitre(this.titre);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
      child: Text(titre, style: AppTypography.label.copyWith(letterSpacing: 0.8)),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.gray500, size: 22),
      title: Text(label, style: AppTypography.bodySmall),
      subtitle: Text(value, style: AppTypography.bodyLarge.copyWith(color: AppColors.black)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
    );
  }
}
