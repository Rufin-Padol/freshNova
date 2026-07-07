import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/errors/error_view.dart';
import '../../../../domain/entities/demande_vendeur.dart';
import '../../../../domain/enums/product_status.dart';
import '../../../../domain/enums/seller_request_status.dart';
import '../../../../shared/widgets/cards/info_row.dart';
import '../../../../shared/widgets/feedback/app_loading_indicator.dart';
import '../../../../shared/widgets/layout/progress_steps.dart';
import '../../../agent/providers/agent_provider.dart';

const _etapes = ['Soumise', 'Agent assigné', 'Collectée', 'En traitement', 'En vente'];

final _demandeDetailProvider =
    FutureProvider.family<DemandeVendeur?, String>((ref, requestId) async {
  final repo = ref.watch(sellerRequestRepositoryProvider);
  return repo.getById(requestId);
});

/// Suivi visuel de la progression d'une demande vendeur — du dépôt de
/// la demande jusqu'à la mise en vente effective du produit.
class SellRequestDetailScreen extends ConsumerWidget {
  final String requestId;
  const SellRequestDetailScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demandeAsync = ref.watch(_demandeDetailProvider(requestId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Suivi de ma demande')),
      body: demandeAsync.when(
        loading: () => const AppLoadingIndicator(),
        error: (_, __) => const ErrorView(message: 'Impossible de charger cette demande.'),
        data: (demande) {
          if (demande == null) {
            return const ErrorView(message: 'Demande introuvable.');
          }
          return _Contenu(demande: demande);
        },
      ),
    );
  }
}

class _Contenu extends ConsumerWidget {
  final DemandeVendeur demande;
  const _Contenu({required this.demande});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estException = demande.statut == SellerRequestStatus.refusee;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(demande.typeProduitSouhaite, style: AppTypography.displayMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${Formatters.currency(demande.prixSouhaite)} souhaité · '
            '${Formatters.shortDate(demande.dateCreation)}',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xxl),
          if (estException)
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.dangerSurface,
                borderRadius: AppRadius.lgRadius,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cancel_rounded, color: AppColors.danger),
                      const SizedBox(width: AppSpacing.sm),
                      Text('Demande refusée',
                          style: AppTypography.titleMedium.copyWith(color: AppColors.danger)),
                    ],
                  ),
                  if (demande.raisonRefus != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(demande.raisonRefus!, style: AppTypography.bodySmall),
                  ],
                ],
              ),
            )
          else if (demande.missionId == null)
            ProgressSteps(steps: _etapes, currentIndex: 0)
          else
            Consumer(
              builder: (context, ref, _) {
                final produitAsync = ref.watch(produitDeMissionProvider(demande.missionId!));
                return produitAsync.when(
                  loading: () => ProgressSteps(steps: _etapes, currentIndex: 1),
                  error: (_, __) => ProgressSteps(steps: _etapes, currentIndex: 1),
                  data: (produit) =>
                      ProgressSteps(steps: _etapes, currentIndex: _indexPour(produit?.statut)),
                );
              },
            ),
          const SizedBox(height: AppSpacing.xxl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.lgRadius,
              border: Border.all(color: AppColors.gray200),
            ),
            child: Column(
              children: [
                InfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Zone',
                  value: demande.zone,
                ),
                const Divider(height: AppSpacing.xl),
                InfoRow(
                  icon: Icons.schedule_outlined,
                  label: 'Disponibilité',
                  value: demande.disponibilite,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _indexPour(ProductStatus? statut) {
    if (statut == null) return 1;
    switch (statut) {
      case ProductStatus.soumis:
      case ProductStatus.missionAssignee:
      case ProductStatus.enVerification:
        return 1;
      case ProductStatus.collecte:
        return 2;
      case ProductStatus.enTraitement:
        return 3;
      case ProductStatus.enVente:
      case ProductStatus.reserve:
      case ProductStatus.enLivraison:
      case ProductStatus.livre:
        return 4;
      default:
        return 1;
    }
  }
}
