import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/entities/proprietaire.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/feedback/app_snackbar.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../auth/providers/session_provider.dart';
import '../../../shop/providers/category_provider.dart';
import '../../providers/agent_provider.dart';
import '../widgets/proprietaire_selector_sheet.dart';

/// Permet à l'agent d'initier lui-même une collecte, sans attendre
/// une assignation de l'admin (démarchage terrain proactif). Le
/// produit qui en résulte reste soumis à la même relecture et
/// publication par l'admin que le reste du catalogue.
class AgentNewCollecteScreen extends ConsumerStatefulWidget {
  const AgentNewCollecteScreen({super.key});

  @override
  ConsumerState<AgentNewCollecteScreen> createState() => _AgentNewCollecteScreenState();
}

class _AgentNewCollecteScreenState extends ConsumerState<AgentNewCollecteScreen> {
  final _titreCtrl = TextEditingController();
  final _prixCtrl = TextEditingController();
  final _localisationCtrl = TextEditingController();
  Proprietaire? _proprietaire;
  String? _categorieId;
  bool _enCours = false;

  @override
  void dispose() {
    _titreCtrl.dispose();
    _prixCtrl.dispose();
    _localisationCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectionnerProprietaire() async {
    final proprietaire = await showProprietaireSelector(context);
    if (proprietaire != null) setState(() => _proprietaire = proprietaire);
  }

  Future<void> _creer() async {
    final utilisateur = ref.read(currentUserProvider);
    if (utilisateur == null) return;

    if (_proprietaire == null ||
        _titreCtrl.text.trim().isEmpty ||
        _categorieId == null ||
        _localisationCtrl.text.trim().isEmpty) {
      AppSnackbar.showError(context, 'Complétez le propriétaire, le titre, la catégorie et la localisation.');
      return;
    }
    final prix = double.tryParse(_prixCtrl.text.replaceAll(' ', ''));
    if (prix == null || prix <= 0) {
      AppSnackbar.showError(context, 'Indiquez un prix valide.');
      return;
    }

    final categories = await ref.read(categoriesProvider.future);
    final categorie = categories.where((c) => c.id == _categorieId).firstOrNull;

    setState(() => _enCours = true);

    final missionId = await ref.read(agentMissionNotifierProvider.notifier).creerCollecteAutoInitiee(
          agentId: utilisateur.id,
          proprietaireId: _proprietaire!.id,
          titre: _titreCtrl.text.trim(),
          categorieId: _categorieId!,
          tauxCommission: categorie?.tauxCommission ?? 10.0,
          prix: prix,
          localisation: _localisationCtrl.text.trim(),
        );

    if (mounted) {
      context.go(AppRoutes.agentMissionDetail.replaceFirst(':missionId', missionId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Nouvelle collecte terrain')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vous avez trouvé un vendeur sur le terrain ? Renseignez les infos essentielles '
              'ici — vous compléterez la fiche complète (photos, état, preuve) juste après.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Propriétaire *', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            InkWell(
              onTap: _selectionnerProprietaire,
              borderRadius: AppRadius.mdRadius,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.mdRadius,
                  border: Border.all(
                    color: _proprietaire != null ? AppColors.violet : AppColors.gray200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person_outline_rounded,
                        color: _proprietaire != null ? AppColors.violet : AppColors.gray400),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _proprietaire != null
                            ? '${_proprietaire!.nom} · ${_proprietaire!.telephone}'
                            : 'Rechercher ou créer un propriétaire',
                        style: AppTypography.bodyMedium,
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.gray400),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(label: 'Titre du produit', controller: _titreCtrl),
            const SizedBox(height: AppSpacing.lg),
            Text('Catégorie', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            categoriesAsync.when(
              loading: () => const SizedBox(height: 32),
              error: (_, __) => const SizedBox.shrink(),
              data: (cats) => Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: cats.map((c) {
                  final sel = _categorieId == c.id;
                  return ChoiceChip(
                    label: Text(c.nom),
                    selected: sel,
                    onSelected: (_) => setState(() => _categorieId = c.id),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Prix (FCFA)',
              controller: _prixCtrl,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(label: 'Zone / localisation', controller: _localisationCtrl),
            const SizedBox(height: AppSpacing.xxl),
            AppPrimaryButton(
              label: 'Créer et démarrer la collecte',
              isLoading: _enCours,
              onPressed: _enCours ? null : _creer,
            ),
          ],
        ),
      ),
    );
  }
}
