import 'dart:convert';
import 'dart:typed_data';

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
import '../../../../shared/widgets/cards/info_row.dart';
import '../../../../shared/widgets/cards/status_badge.dart';
import '../../../../shared/widgets/feedback/app_loading_indicator.dart';
import '../../../../shared/widgets/feedback/app_snackbar.dart';
import '../../../../shared/widgets/inputs/app_search_field.dart';
import '../../providers/admin_provider.dart';

Uint8List _decodeDataUrl(String dataUrl) => base64Decode(dataUrl.split(',').last);

/// Écran admin de traitement des demandes vendeurs — le maillon
/// central du cycle métier : c'est ici que chaque soumission reçoit un
/// agent, ce qui crée la mission de collecte et le produit brouillon
/// correspondant (voir AdminSellerRequestNotifier.assignerAgent).
class AdminSellerRequestsScreen extends ConsumerStatefulWidget {
  const AdminSellerRequestsScreen({super.key});

  @override
  ConsumerState<AdminSellerRequestsScreen> createState() => _AdminSellerRequestsScreenState();
}

class _AdminSellerRequestsScreenState extends ConsumerState<AdminSellerRequestsScreen> {
  String _requete = '';

  @override
  Widget build(BuildContext context) {
    final demandesAsync = ref.watch(allSellerRequestsAdminProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Demandes vendeurs', style: AppTypography.displayMedium),
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
                      hint: 'Rechercher une demande...',
                      onChanged: (v) => setState(() => _requete = v),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    demandesAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: Center(child: AppLoadingIndicator()),
                      ),
                      error: (_, __) => ErrorView(
                        message: 'Impossible de charger les demandes.',
                        onRetry: () => ref.invalidate(allSellerRequestsAdminProvider),
                      ),
                      data: (demandes) {
                        final req = _requete.trim().toLowerCase();
                        final filtres = demandes
                            .where((d) =>
                                req.isEmpty || d.typeProduitSouhaite.toLowerCase().contains(req))
                            .toList();

                        if (filtres.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                            child: EmptyView(
                              message: 'Aucune demande vendeur',
                              icon: Icons.inventory_outlined,
                            ),
                          );
                        }

                        return Column(
                          children: [
                            for (final d in filtres) ...[
                              _DemandeTile(demande: d, onTap: () => _ouvrirDetail(context, ref, d)),
                              if (d != filtres.last) const Divider(height: 1),
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

Future<void> _ouvrirDetail(BuildContext context, WidgetRef ref, DemandeVendeur d) async {
  final peutAssigner =
        d.statut == SellerRequestStatus.enAttente || d.statut == SellerRequestStatus.validee;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.xlRadius),
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(d.typeProduitSouhaite, style: AppTypography.titleLarge),
                  ),
                  StatusBadge(label: d.statut.label, color: d.statut.color),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${Formatters.currency(d.prixSouhaite)} souhaité · '
                '${Formatters.shortDate(d.dateCreation)}',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(d.descriptionInitiale, style: AppTypography.bodyLarge),
              const SizedBox(height: AppSpacing.lg),
              InfoRow(icon: Icons.location_on_outlined, label: 'Adresse', value: d.adresse),
              const SizedBox(height: AppSpacing.md),
              InfoRow(icon: Icons.map_outlined, label: 'Zone', value: d.zone),
              const SizedBox(height: AppSpacing.md),
              InfoRow(
                icon: Icons.schedule_outlined,
                label: 'Disponibilité',
                value: d.disponibilite,
              ),
              const SizedBox(height: AppSpacing.md),
              InfoRow(
                icon: Icons.inventory_2_outlined,
                label: 'Quantité',
                value: '${d.quantite}',
              ),
              if (d.photos.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text('Photos du vendeur', style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final photo in d.photos)
                      ClipRRect(
                        borderRadius: AppRadius.smRadius,
                        child: Image.memory(
                          _decodeDataUrl(photo),
                          height: 96,
                          width: 96,
                          fit: BoxFit.cover,
                        ),
                      ),
                  ],
                ),
              ],
              if (peutAssigner) ...[
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      _ouvrirAssignation(context, ref, d);
                    },
                    child: const Text('Assigner un agent'),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
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

class _DemandeTile extends ConsumerWidget {
  final DemandeVendeur demande;
  final VoidCallback onTap;
  const _DemandeTile({required this.demande, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peutAssigner = demande.statut == SellerRequestStatus.enAttente ||
        demande.statut == SellerRequestStatus.validee;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(demande.typeProduitSouhaite, style: AppTypography.titleMedium),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      StatusBadge(label: demande.statut.label, color: demande.statut.color),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${Formatters.currency(demande.prixSouhaite)} · ${demande.zone} · '
                    '${Formatters.shortDate(demande.dateCreation)}',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
            if (peutAssigner)
              TextButton(
                onPressed: () => _ouvrirAssignation(context, ref, demande),
                child: const Text('Assigner un agent'),
              )
            else
              const Icon(Icons.chevron_right_rounded, color: AppColors.gray400),
          ],
        ),
      ),
    );
  }
}
