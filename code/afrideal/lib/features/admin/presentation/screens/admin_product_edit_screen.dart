import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../domain/entities/produit.dart';
import '../../../../domain/enums/product_status.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/feedback/app_snackbar.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../providers/admin_provider.dart';

/// Modes de déclaration des défauts, tous trois exigés explicitement
/// par le cahier des charges (transparence totale envers l'acheteur) :
/// une fiche ne peut être publiée sans qu'un choix ait été fait.
enum _ModeDefauts { liste, aucun, nonGaranti }

/// Formulaire de rédaction de la fiche produit avant publication —
/// étape 5 du cycle métier ("L'admin rédige la fiche produit
/// complète"), absente jusqu'ici : la boutique ne recevait qu'un
/// changement de statut sans contenu réel.
class AdminProductEditScreen extends ConsumerStatefulWidget {
  final Produit produit;

  const AdminProductEditScreen({super.key, required this.produit});

  @override
  ConsumerState<AdminProductEditScreen> createState() => _AdminProductEditScreenState();
}

class _AdminProductEditScreenState extends ConsumerState<AdminProductEditScreen> {
  late final TextEditingController _titreCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _defautsCtrl;
  _ModeDefauts? _mode;
  bool _enCours = false;

  @override
  void initState() {
    super.initState();
    final p = widget.produit;
    _titreCtrl = TextEditingController(text: p.titre);
    _descriptionCtrl = TextEditingController(text: p.description);
    _defautsCtrl = TextEditingController(text: p.defautsConnus ?? '');
  }

  @override
  void dispose() {
    _titreCtrl.dispose();
    _descriptionCtrl.dispose();
    _defautsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final produit = widget.produit;
    final montantNet = produit.prix - (produit.prix * produit.tauxCommission / 100);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Publier le produit')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(label: 'Titre', controller: _titreCtrl),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Description',
              controller: _descriptionCtrl,
              maxLines: 4,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Défauts', style: AppTypography.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Un choix est obligatoire avant publication — transparence totale envers l\'acheteur.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            RadioListTile<_ModeDefauts>(
              contentPadding: EdgeInsets.zero,
              value: _ModeDefauts.liste,
              groupValue: _mode,
              onChanged: (v) => setState(() => _mode = v),
              title: const Text('Défauts constatés (préciser ci-dessous)'),
            ),
            if (_mode == _ModeDefauts.liste)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppTextField(
                  hint: 'Ex : petite rayure sur le côté gauche',
                  controller: _defautsCtrl,
                  maxLines: 2,
                ),
              ),
            RadioListTile<_ModeDefauts>(
              contentPadding: EdgeInsets.zero,
              value: _ModeDefauts.aucun,
              groupValue: _mode,
              onChanged: (v) => setState(() => _mode = v),
              title: const Text('Aucun défaut visible constaté'),
            ),
            RadioListTile<_ModeDefauts>(
              contentPadding: EdgeInsets.zero,
              value: _ModeDefauts.nonGaranti,
              groupValue: _mode,
              onChanged: (v) => setState(() => _mode = v),
              title: const Text('Défauts internes non garantis'),
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.violetSurface,
                borderRadius: AppRadius.mdRadius,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LigneMontant('Prix vendeur', Formatters.currency(produit.prix)),
                  _LigneMontant(
                    'Commission (${produit.tauxCommission.toStringAsFixed(0)}%)',
                    '− ${Formatters.currency(produit.prix - montantNet)}',
                  ),
                  _LigneMontant(
                    'Vendeur recevra',
                    Formatters.currency(montantNet),
                    accent: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.huge),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AppPrimaryButton(
            label: 'Publier en boutique',
            isLoading: _enCours,
            onPressed: _enCours ? null : () => _publier(context),
          ),
        ),
      ),
    );
  }

  Future<void> _publier(BuildContext context) async {
    if (_mode == null) {
      AppSnackbar.showError(context, 'Choisissez une option pour les défauts avant de publier.');
      return;
    }
    if (_titreCtrl.text.trim().isEmpty || _descriptionCtrl.text.trim().isEmpty) {
      AppSnackbar.showError(context, 'Le titre et la description sont obligatoires.');
      return;
    }

    setState(() => _enCours = true);

    String? defautsConnus;
    switch (_mode!) {
      case _ModeDefauts.liste:
        defautsConnus = _defautsCtrl.text.trim().isEmpty ? null : _defautsCtrl.text.trim();
        break;
      case _ModeDefauts.aucun:
        defautsConnus = null;
        break;
      case _ModeDefauts.nonGaranti:
        defautsConnus = 'Défauts internes non garantis par TrustNova.';
        break;
    }

    final produitMisAJour = widget.produit.copyWith(
      titre: _titreCtrl.text.trim(),
      description: _descriptionCtrl.text.trim(),
      defautsConnus: defautsConnus,
    );

    await ref.read(productRepositoryProvider).save(produitMisAJour);
    await ref
        .read(adminProductNotifierProvider.notifier)
        .changerStatut(produitMisAJour.id, ProductStatus.enVente);

    if (context.mounted) {
      AppSnackbar.showSuccess(context, 'Produit publié en boutique.');
      context.pop();
    }
  }
}

class _LigneMontant extends StatelessWidget {
  final String label;
  final String valeur;
  final bool accent;

  const _LigneMontant(this.label, this.valeur, {this.accent = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodyMedium),
          Text(
            valeur,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: accent ? FontWeight.w700 : FontWeight.w400,
              color: accent ? AppColors.success : AppColors.black,
            ),
          ),
        ],
      ),
    );
  }
}
