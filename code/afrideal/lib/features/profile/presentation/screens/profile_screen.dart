import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/local/datasources/hive_service.dart';
import '../../../../data/local/seed/datasources_box_check.dart';
import '../../../../domain/entities/demande_vendeur.dart';
import '../../../../domain/entities/utilisateur.dart';
import '../../../../domain/enums/user_role.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/cards/app_avatar.dart';
import '../../../../shared/widgets/cards/status_badge.dart';
import '../../../../shared/widgets/feedback/app_loading_indicator.dart';
import '../../../../shared/widgets/feedback/app_snackbar.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../auth/providers/session_provider.dart';
import '../../../sell/providers/sell_provider.dart';

Uint8List _decodeDataUrl(String dataUrl) => base64Decode(dataUrl.split(',').last);

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
          _SectionHeader(
            titre: 'Informations personnelles',
            actionIcon: Icons.edit_outlined,
            onAction: () => _ouvrirEditionProfil(context, ref, utilisateur),
          ),
          _InfoTile(Icons.phone_outlined, 'Téléphone', utilisateur.telephone),
          _InfoTile(Icons.location_city_outlined, 'Ville', utilisateur.ville ?? 'Non renseignée'),
          if (utilisateur.noteVendeur != null)
            _InfoTile(Icons.star_outline_rounded, 'Note vendeur',
                '${utilisateur.noteVendeur!.toStringAsFixed(1)} / 5.0'),
          const SizedBox(height: AppSpacing.xl),
          if (utilisateur.role == UserRole.acheteur) ...[
            _SectionHeader(
              titre: 'Mes annonces',
              actionIcon: Icons.add_rounded,
              onAction: () => context.push(AppRoutes.sellStep1),
            ),
            _MesAnnonces(),
            const SizedBox(height: AppSpacing.xl),
          ],
          if (AppConfig.isLocal) ...[
            const _SectionHeader(titre: 'Développement'),
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

  void _ouvrirEditionProfil(BuildContext context, WidgetRef ref, Utilisateur utilisateur) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: AppRadius.xlRadius.topLeft),
      ),
      builder: (sheetContext) => _EditionProfilSheet(utilisateur: utilisateur),
    );
  }
}

/// Formulaire de modification des informations personnelles.
///
/// Modifie le compte via IUserRepository.save, puis rafraîchit la
/// session : sauvegarder dans le dépôt ne met pas automatiquement à
/// jour currentUserProvider, qui ne reflète que l'état de session.
class _EditionProfilSheet extends ConsumerStatefulWidget {
  final Utilisateur utilisateur;

  const _EditionProfilSheet({required this.utilisateur});

  @override
  ConsumerState<_EditionProfilSheet> createState() => _EditionProfilSheetState();
}

class _EditionProfilSheetState extends ConsumerState<_EditionProfilSheet> {
  late final TextEditingController _prenomCtrl;
  late final TextEditingController _nomCtrl;
  late final TextEditingController _telephoneCtrl;
  late final TextEditingController _villeCtrl;
  bool _enCours = false;

  @override
  void initState() {
    super.initState();
    final u = widget.utilisateur;
    _prenomCtrl = TextEditingController(text: u.prenom);
    _nomCtrl = TextEditingController(text: u.nom);
    _telephoneCtrl = TextEditingController(text: u.telephone);
    _villeCtrl = TextEditingController(text: u.ville ?? '');
  }

  @override
  void dispose() {
    _prenomCtrl.dispose();
    _nomCtrl.dispose();
    _telephoneCtrl.dispose();
    _villeCtrl.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    if (_prenomCtrl.text.trim().isEmpty ||
        _nomCtrl.text.trim().isEmpty ||
        _telephoneCtrl.text.trim().isEmpty) {
      AppSnackbar.showError(context, 'Prénom, nom et téléphone sont obligatoires.');
      return;
    }

    setState(() => _enCours = true);
    final utilisateurMisAJour = widget.utilisateur.copyWith(
      prenom: _prenomCtrl.text.trim(),
      nom: _nomCtrl.text.trim(),
      telephone: _telephoneCtrl.text.trim(),
      ville: _villeCtrl.text.trim().isEmpty ? null : _villeCtrl.text.trim(),
    );
    await ref.read(userRepositoryProvider).save(utilisateurMisAJour);
    await ref.read(sessionProvider.notifier).refresh();

    if (mounted) {
      Navigator.of(context).pop();
      AppSnackbar.showSuccess(context, 'Profil mis à jour.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Modifier mes informations', style: AppTypography.titleLarge),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: AppTextField(label: 'Prénom', controller: _prenomCtrl),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppTextField(label: 'Nom', controller: _nomCtrl),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Numéro de téléphone',
            controller: _telephoneCtrl,
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_outlined,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Ville',
            controller: _villeCtrl,
            prefixIcon: Icons.location_city_outlined,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppPrimaryButton(
            label: 'Enregistrer',
            isLoading: _enCours,
            onPressed: _enCours ? null : _enregistrer,
          ),
        ],
      ),
    );
  }
}

/// Annonces déjà soumises par l'utilisateur, affichées directement sur
/// son profil (pas seulement un résumé qui renvoie ailleurs) — on y
/// voit tout de suite ce qui a été soumis, et un bouton "+" permet
/// d'en ajouter une nouvelle sans quitter son propre profil.
class _MesAnnonces extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demandesAsync = ref.watch(mySellerRequestsProvider);

    return demandesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: AppLoadingIndicator(),
      ),
      error: (_, __) => Text(
        'Impossible de charger vos annonces.',
        style: AppTypography.bodySmall.copyWith(color: AppColors.danger),
      ),
      data: (demandes) {
        if (demandes.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.lgRadius,
              border: Border.all(color: AppColors.gray200),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Aucune annonce pour l\'instant', style: AppTypography.bodyLarge),
                SizedBox(height: 4),
                Text(
                  'Appuyez sur "+" pour soumettre un bien — un agent viendra le vérifier chez vous.',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          );
        }
        return Column(
          children: [
            for (final demande in demandes)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _AnnonceTile(demande: demande),
              ),
          ],
        );
      },
    );
  }
}

class _AnnonceTile extends StatelessWidget {
  final DemandeVendeur demande;

  const _AnnonceTile({required this.demande});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppRadius.lgRadius,
      onTap: () => context.push(
        AppRoutes.sellRequestDetail.replaceFirst(':requestId', demande.id),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lgRadius,
          border: Border.all(color: AppColors.gray200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (demande.photos.isNotEmpty) ...[
              ClipRRect(
                borderRadius: AppRadius.smRadius,
                child: Image.memory(
                  _decodeDataUrl(demande.photos.first),
                  height: 64,
                  width: 64,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(child: _AnnonceDetails(demande: demande)),
          ],
        ),
      ),
    );
  }
}

class _AnnonceDetails extends StatelessWidget {
  final DemandeVendeur demande;

  const _AnnonceDetails({required this.demande});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                demande.typeProduitSouhaite,
                style: AppTypography.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            StatusBadge(label: demande.statut.label, color: demande.statut.color),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${Formatters.currency(demande.prixSouhaite)} souhaité · '
          '${Formatters.shortDate(demande.dateCreation)}',
          style: AppTypography.bodySmall,
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String titre;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  const _SectionHeader({required this.titre, this.actionIcon, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            titre,
            style: AppTypography.label.copyWith(letterSpacing: 0.8),
          ),
          if (actionIcon != null)
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.violetSurface,
                  shape: BoxShape.circle,
                ),
                child: Icon(actionIcon, size: 16, color: AppColors.violet),
              ),
            ),
        ],
      ),
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
