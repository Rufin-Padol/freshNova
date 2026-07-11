import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/errors/error_view.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../domain/entities/commande.dart';
import '../../../../domain/entities/produit.dart';
import '../../../../domain/entities/utilisateur.dart';
import '../../../../domain/enums/order_status.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/buttons/app_secondary_button.dart';
import '../../../../shared/widgets/cards/info_row.dart';
import '../../../../shared/widgets/cards/status_badge.dart';
import '../../../../shared/widgets/feedback/app_loading_indicator.dart';
import '../../../../shared/widgets/feedback/app_snackbar.dart';
import '../../../../shared/widgets/inputs/app_search_field.dart';
import '../../providers/admin_provider.dart';

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  String _requete = '';

  @override
  Widget build(BuildContext context) {
    final commandesAsync = ref.watch(allOrdersAdminProvider);
    final usersAsync = ref.watch(allUsersAdminProvider);
    final utilisateurParId = {
      for (final u in usersAsync.valueOrNull ?? const <Utilisateur>[]) u.id: u,
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Commandes', style: AppTypography.displayMedium),
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
                      hint: 'Rechercher une commande...',
                      onChanged: (v) => setState(() => _requete = v),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    commandesAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: Center(child: AppLoadingIndicator()),
                      ),
                      error: (_, __) => const Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: Text('Impossible de charger les commandes.'),
                      ),
                      data: (commandes) {
                        final req = _requete.trim().toLowerCase();
                        final filtrees = commandes.where((c) {
                          if (req.isEmpty) return true;
                          final client =
                              utilisateurParId[c.acheteurId]?.nomComplet.toLowerCase() ?? '';
                          return c.reference.toLowerCase().contains(req) || client.contains(req);
                        }).toList();

                        if (filtrees.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                            child: EmptyView(message: 'Aucune commande', icon: Icons.receipt_long_outlined),
                          );
                        }

                        return LayoutBuilder(
                          builder: (context, constraints) => SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minWidth: constraints.maxWidth),
                              child: DataTable(
                                headingRowHeight: 40,
                                dataRowMinHeight: 52,
                                dataRowMaxHeight: 60,
                                columns: const [
                                  DataColumn(label: Text('Référence')),
                                  DataColumn(label: Text('Client')),
                                  DataColumn(label: Text('Date')),
                                  DataColumn(label: Text('Montant')),
                                  DataColumn(label: Text('Statut')),
                                ],
                                rows: [
                                  for (final c in filtrees)
                                    DataRow(
                                      onSelectChanged: (_) => _ouvrirDetail(context, ref, c),
                                      cells: [
                                        DataCell(Text('#${c.reference}',
                                            style: AppTypography.bodyMedium
                                                .copyWith(fontWeight: FontWeight.w600))),
                                        DataCell(
                                            Text(utilisateurParId[c.acheteurId]?.nomComplet ?? '—')),
                                        DataCell(Text(Formatters.shortDate(c.dateCommande))),
                                        DataCell(Text(Formatters.currency(c.montantTotal))),
                                        DataCell(
                                            StatusBadge(label: c.statut.label, color: c.statut.color)),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
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

  void _ouvrirDetail(BuildContext context, WidgetRef ref, Commande commande) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _AdminOrderDetailSheet(commande: commande),
    );
  }
}

class _AdminOrderDetailSheet extends ConsumerWidget {
  final Commande commande;

  const _AdminOrderDetailSheet({required this.commande});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productRepo = ref.watch(productRepositoryProvider);

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
          Row(
            children: [
              Expanded(
                child: Text('#${commande.reference}', style: AppTypography.titleLarge),
              ),
              StatusBadge(label: commande.statut.label, color: commande.statut.color),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          FutureBuilder<List<Produit>>(
            future: Future.wait(commande.lignes.keys.map((id) => productRepo.getById(id)))
                .then((liste) => liste.whereType<Produit>().toList()),
            builder: (context, snapshot) {
              final produits = snapshot.data;
              if (produits == null) return const SizedBox(height: 24);
              if (produits.isEmpty) {
                return Text('Produit', style: AppTypography.titleMedium);
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final produit in produits)
                    Text(
                      (commande.lignes[produit.id] ?? 1) > 1
                          ? '${produit.titre} × ${commande.lignes[produit.id]}'
                          : produit.titre,
                      style: AppTypography.titleMedium,
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          InfoRow(
            icon: Icons.payments_outlined,
            label: 'Montant à collecter à la livraison',
            value: Formatters.currency(commande.montantTotal),
          ),
          const SizedBox(height: AppSpacing.md),
          InfoRow(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Paiement',
            value: commande.numeroPaieur != null && commande.numeroPaieur!.isNotEmpty
                ? '${commande.methodePaiement.label} (${commande.numeroPaieur})'
                : commande.methodePaiement.label,
          ),
          const SizedBox(height: AppSpacing.md),
          InfoRow(
            icon: Icons.local_shipping_outlined,
            label: 'Mode de livraison',
            value: commande.modeLivraison.label,
          ),
          const SizedBox(height: AppSpacing.md),
          InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Adresse',
            value: commande.adresseLivraison,
          ),
          const SizedBox(height: AppSpacing.xl),
          if (commande.statut == OrderStatus.pendante)
            AppPrimaryButton(
              label: 'Marquer en livraison',
              onPressed: () => _changerStatut(context, ref, OrderStatus.enLivraison),
            )
          else if (commande.statut == OrderStatus.enLivraison)
            AppPrimaryButton(
              label: 'Marquer livrée et encaissée',
              onPressed: () => _changerStatut(context, ref, OrderStatus.livree),
            ),
          if (commande.statut == OrderStatus.pendante ||
              commande.statut == OrderStatus.enLivraison) ...[
            const SizedBox(height: AppSpacing.sm),
            AppSecondaryButton(
              label: 'Annuler la commande',
              onPressed: () => _changerStatut(context, ref, OrderStatus.annulee),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _changerStatut(BuildContext context, WidgetRef ref, OrderStatus statut) async {
    await ref.read(adminOrderNotifierProvider.notifier).changerStatut(commande.id, statut);
    if (context.mounted) {
      Navigator.of(context).pop();
      AppSnackbar.showSuccess(context, 'Commande mise à jour.');
    }
  }
}
