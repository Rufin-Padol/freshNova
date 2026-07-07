import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/errors/error_view.dart';
import '../../../../domain/entities/demande_vendeur.dart';
import '../../../../domain/entities/utilisateur.dart';
import '../../../../domain/enums/seller_request_status.dart';
import '../../../../shared/widgets/cards/status_badge.dart';
import '../../../../shared/widgets/feedback/app_loading_indicator.dart';
import '../../../../shared/widgets/feedback/app_snackbar.dart';
import '../../providers/admin_provider.dart';

/// Écran admin de traitement des demandes vendeurs — le maillon
/// central du cycle métier : c'est ici que chaque soumission reçoit un
/// agent, ce qui crée la mission de collecte et le produit brouillon
/// correspondant (voir AdminSellerRequestNotifier.assignerAgent).
class AdminSellerRequestsScreen extends ConsumerWidget {
  const AdminSellerRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demandesAsync = ref.watch(allSellerRequestsAdminProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text('Demandes vendeurs', style: AppTypography.displayMedium),
          ),
          Expanded(
            child: demandesAsync.when(
              loading: () => const AppLoadingIndicator(),
              error: (_, __) => ErrorView(
                message: 'Impossible de charger les demandes.',
                onRetry: () => ref.invalidate(allSellerRequestsAdminProvider),
              ),
              data: (demandes) {
                if (demandes.isEmpty) {
                  return const EmptyView(
                    message: 'Aucune demande vendeur',
                    icon: Icons.inventory_outlined,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  itemCount: demandes.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final d = demandes[i];
                    final peutAssigner = d.statut == SellerRequestStatus.enAttente ||
                        d.statut == SellerRequestStatus.validee;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(d.typeProduitSouhaite, style: AppTypography.titleMedium),
                          ),
                          StatusBadge(label: d.statut.label, color: d.statut.color),
                        ],
                      ),
                      subtitle: Text(
                        '${Formatters.currency(d.prixSouhaite)} · ${d.zone} · '
                        '${Formatters.shortDate(d.dateCreation)}',
                        style: AppTypography.bodySmall,
                      ),
                      trailing: peutAssigner
                          ? TextButton(
                              onPressed: () => _ouvrirAssignation(context, ref, d),
                              child: const Text('Assigner un agent'),
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

  Future<void> _ouvrirAssignation(
    BuildContext context,
    WidgetRef ref,
    DemandeVendeur demande,
  ) async {
    final agents = await ref.read(agentsAdminProvider.future);
    if (!context.mounted) return;

    if (agents.isEmpty) {
      AppSnackbar.showError(context, 'Aucun agent terrain disponible.');
      return;
    }

    final agentChoisi = await showDialog<Utilisateur>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Choisir un agent'),
        children: agents
            .map(
              (agent) => SimpleDialogOption(
                onPressed: () => Navigator.of(dialogContext).pop(agent),
                child: Text(agent.nomComplet),
              ),
            )
            .toList(),
      ),
    );

    if (agentChoisi == null || !context.mounted) return;

    await ref
        .read(adminSellerRequestNotifierProvider.notifier)
        .assignerAgent(demande, agentChoisi.id);

    if (context.mounted) {
      AppSnackbar.showSuccess(context, 'Agent assigné. Mission de collecte créée.');
    }
  }
}
