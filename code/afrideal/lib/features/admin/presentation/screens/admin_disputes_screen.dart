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
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../providers/admin_provider.dart';

class AdminDisputesScreen extends ConsumerWidget {
  const AdminDisputesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final litigesAsync = ref.watch(allDisputesAdminProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text('Litiges', style: AppTypography.displayMedium),
          ),
          Expanded(
            child: litigesAsync.when(
              loading: () => const AppLoadingIndicator(),
              error: (_, __) => ErrorView(
                message: 'Impossible de charger les litiges.',
                onRetry: () => ref.invalidate(allDisputesAdminProvider),
              ),
              data: (litiges) {
                if (litiges.isEmpty) {
                  return const EmptyView(message: 'Aucun litige', icon: Icons.gavel_outlined);
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  itemCount: litiges.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final l = litiges[i];
                    final peutTraiter =
                        l.statut == DisputeStatus.ouvert || l.statut == DisputeStatus.enExamen;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      title: Row(
                        children: [
                          Expanded(child: Text(l.motif, style: AppTypography.titleMedium)),
                          StatusBadge(label: l.statut.label, color: l.statut.color),
                        ],
                      ),
                      subtitle: Text(
                        'Commande #${l.commandeId} · ${Formatters.shortDate(l.dateOuverture)}'
                        '${l.decision != null ? ' · ${l.decision}' : ''}',
                        style: AppTypography.bodySmall,
                      ),
                      trailing: peutTraiter
                          ? TextButton(
                              onPressed: () => _ouvrirDecision(context, ref, l),
                              child: const Text('Traiter'),
                            )
                          : null,
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
