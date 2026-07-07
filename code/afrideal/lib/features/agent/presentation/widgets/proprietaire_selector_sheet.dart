import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/entities/proprietaire.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/cards/app_avatar.dart';
import '../../../../shared/widgets/feedback/app_loading_indicator.dart';
import '../../../../shared/widgets/feedback/app_snackbar.dart';
import '../../../../shared/widgets/inputs/app_search_field.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../providers/proprietaire_provider.dart';

/// Ouvre la sélection/création de propriétaire et retourne le
/// [Proprietaire] choisi, ou `null` si l'agent annule.
Future<Proprietaire?> showProprietaireSelector(BuildContext context) {
  return showModalBottomSheet<Proprietaire>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const ProprietaireSelectorSheet(),
  );
}

class ProprietaireSelectorSheet extends ConsumerStatefulWidget {
  const ProprietaireSelectorSheet({super.key});

  @override
  ConsumerState<ProprietaireSelectorSheet> createState() =>
      _ProprietaireSelectorSheetState();
}

class _ProprietaireSelectorSheetState extends ConsumerState<ProprietaireSelectorSheet> {
  String _recherche = '';
  bool _modeCreation = false;
  final _nomCtrl = TextEditingController();
  final _telephoneCtrl = TextEditingController();
  final _villeCtrl = TextEditingController();
  bool _enCours = false;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _telephoneCtrl.dispose();
    _villeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
          ),
          child: _modeCreation
              ? _buildFormulaireCreation(context)
              : _buildRecherche(context, scrollController),
        );
      },
    );
  }

  Widget _buildRecherche(BuildContext context, ScrollController scrollController) {
    final proprietairesAsync = ref.watch(allProprietairesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Propriétaire du bien', style: AppTypography.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Recherchez un propriétaire déjà connu, ou créez-en un nouveau.',
          style: AppTypography.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        AppSearchField(onChanged: (v) => setState(() => _recherche = v)),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: proprietairesAsync.when(
            loading: () => const AppLoadingIndicator(),
            error: (_, __) => const Text('Impossible de charger les propriétaires.'),
            data: (proprietaires) {
              final filtres = _recherche.trim().isEmpty
                  ? proprietaires
                  : proprietaires.where((p) {
                      final q = _recherche.toLowerCase();
                      return p.nom.toLowerCase().contains(q) || p.telephone.contains(q);
                    }).toList();

              if (filtres.isEmpty) {
                return Center(
                  child: Text('Aucun propriétaire trouvé.', style: AppTypography.bodyMedium),
                );
              }

              return ListView.separated(
                controller: scrollController,
                itemCount: filtres.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final p = filtres[i];
                  return ListTile(
                    leading: AppAvatar(initiales: _initiales(p.nom), size: 40),
                    title: Text(p.nom, style: AppTypography.titleMedium),
                    subtitle: Text(
                      '${p.telephone}${p.ville != null ? ' · ${p.ville}' : ''}',
                      style: AppTypography.bodySmall,
                    ),
                    onTap: () => Navigator.of(context).pop(p),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppPrimaryButton(
          label: '+ Nouveau propriétaire',
          onPressed: () => setState(() => _modeCreation = true),
        ),
      ],
    );
  }

  Widget _buildFormulaireCreation(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => setState(() => _modeCreation = false),
              ),
              Text('Nouveau propriétaire', style: AppTypography.titleLarge),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(label: 'Nom complet', controller: _nomCtrl),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Téléphone',
            controller: _telephoneCtrl,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(label: 'Ville (optionnel)', controller: _villeCtrl),
          const SizedBox(height: AppSpacing.xl),
          AppPrimaryButton(
            label: 'Créer et sélectionner',
            isLoading: _enCours,
            onPressed: _enCours ? null : () => _creer(context),
          ),
        ],
      ),
    );
  }

  Future<void> _creer(BuildContext context) async {
    if (_nomCtrl.text.trim().isEmpty || _telephoneCtrl.text.trim().isEmpty) {
      AppSnackbar.showError(context, 'Le nom et le téléphone sont obligatoires.');
      return;
    }

    setState(() => _enCours = true);
    final proprietaire = await ref.read(proprietaireNotifierProvider.notifier).creer(
          nom: _nomCtrl.text.trim(),
          telephone: _telephoneCtrl.text.trim(),
          ville: _villeCtrl.text.trim().isEmpty ? null : _villeCtrl.text.trim(),
        );

    if (context.mounted) Navigator.of(context).pop(proprietaire);
  }

  String _initiales(String nom) {
    final parts = nom.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
