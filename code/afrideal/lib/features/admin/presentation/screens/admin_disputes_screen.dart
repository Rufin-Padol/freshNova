import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/errors/error_view.dart';
import '../../../../domain/entities/litige.dart';
import '../../../../domain/enums/dispute_status.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/cards/status_badge.dart';
import '../../../../shared/widgets/feedback/app_loading_indicator.dart';
import '../../../../shared/widgets/feedback/app_snackbar.dart';
import '../../../../shared/widgets/inputs/app_search_field.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../providers/admin_provider.dart';

class AdminDisputesScreen extends ConsumerStatefulWidget {
  const AdminDisputesScreen({super.key});

  @override
  ConsumerState<AdminDisputesScreen> createState() => _AdminDisputesScreenState();
}

class _AdminDisputesScreenState extends ConsumerState<AdminDisputesScreen> {
  String _requete = '';

  @override
  Widget build(BuildContext context) {
    final litigesAsync = ref.watch(allDisputesAdminProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Litiges', style: AppTypography.displayMedium),
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
                      hint: 'Rechercher un litige...',
                      onChanged: (v) => setState(() => _requete = v),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    litigesAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: Center(child: AppLoadingIndicator()),
                      ),
                      error: (_, __) => ErrorView(
                        message: 'Impossible de charger les litiges.',
                        onRetry: () => ref.invalidate(allDisputesAdminProvider),
                      ),
                      data: (litiges) {
                        final req = _requete.trim().toLowerCase();
                        final filtres = litiges
                            .where((l) => req.isEmpty || l.motif.toLowerCase().contains(req))
                            .toList();

                        if (filtres.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                            child: EmptyView(message: 'Aucun litige', icon: Icons.gavel_outlined),
                          );
                        }

                        return Column(
                          children: [
                            for (final l in filtres) ...[
                              _DisputeTile(litige: l),
                              if (l != filtres.last) const Divider(height: 1),
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
}

class _DisputeTile extends ConsumerWidget {
  final Litige litige;
  const _DisputeTile({required this.litige});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peutTraiter =
        litige.statut == DisputeStatus.ouvert || litige.statut == DisputeStatus.enExamen;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(litige.motif, style: AppTypography.titleMedium)),
                    const SizedBox(width: AppSpacing.sm),
                    StatusBadge(label: litige.statut.label, color: litige.statut.color),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Commande #${litige.commandeId} · ${Formatters.shortDate(litige.dateOuverture)}'
                  '${litige.decision != null ? ' · ${litige.decision}' : ''}',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          if (peutTraiter)
            TextButton(
              onPressed: () => _ouvrirDecision(context, ref, litige),
              child: const Text('Traiter'),
            ),
        ],
      ),
    );
  }

  Future<void> _ouvrirDecision(BuildContext context, WidgetRef ref, Litige litige) async {
    final decisionCtrl = TextEditingController();
    final montantCtrl = TextEditingController();

    final resultat = await showDialog<DisputeStatus>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Décision du litige'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              label: 'Décision',
              hint: 'Ex : remboursement partiel accordé',
              controller: decisionCtrl,
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Montant remboursé (FCFA, optionnel)',
              hint: '0',
              controller: montantCtrl,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(DisputeStatus.rejete),
            child: const Text('Rejeter'),
          ),
          AppPrimaryButton(
            label: 'Résoudre',
            fullWidth: false,
            onPressed: () => Navigator.of(dialogContext).pop(DisputeStatus.resolu),
          ),
        ],
      ),
    );

    if (resultat == null || !context.mounted) return;
    if (decisionCtrl.text.trim().isEmpty) {
      AppSnackbar.showError(context, 'Veuillez préciser la décision.');
      return;
    }

    final montant = double.tryParse(montantCtrl.text.replaceAll(' ', ''));
    await ref.read(adminDisputeNotifierProvider.notifier).resoudre(
          litige,
          statut: resultat,
          decision: decisionCtrl.text.trim(),
          montantRembourse: montant != null && montant > 0 ? montant : null,
        );

    if (context.mounted) {
      AppSnackbar.showSuccess(context, 'Litige mis à jour.');
    }
  }
}
