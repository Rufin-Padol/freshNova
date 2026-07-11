import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../domain/entities/commande.dart';
import '../../../../domain/entities/demande_vendeur.dart';
import '../../../../domain/entities/litige.dart';
import '../../../../domain/entities/produit.dart';
import '../../../../domain/entities/utilisateur.dart';
import '../../../../domain/enums/dispute_status.dart';
import '../../../../domain/enums/order_status.dart';
import '../../../../domain/enums/product_status.dart';
import '../../../../domain/enums/seller_request_status.dart';
import '../../../../shared/widgets/cards/app_avatar.dart';
import '../../../../shared/widgets/cards/status_badge.dart';
import '../../../../shared/widgets/inputs/app_search_field.dart';
import '../../../auth/providers/session_provider.dart';
import '../../providers/admin_provider.dart';

enum _Periode { j7, j30 }

/// Tableau de bord admin : données stratégiques de gestion de la
/// plateforme (produits, commandes, demandes vendeurs, litiges),
/// activité récente sous forme de courbe, dernières commandes et
/// meilleures ventes — plus un simple compteur de statuts produit.
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  _Periode _periode = _Periode.j7;
  String _rechercheCommandes = '';

  @override
  Widget build(BuildContext context) {
    final admin = ref.watch(currentUserProvider);
    final produitsAsync = ref.watch(allProductsAdminProvider);
    final commandesAsync = ref.watch(allOrdersAdminProvider);
    final demandesAsync = ref.watch(allSellerRequestsAdminProvider);
    final litigesAsync = ref.watch(allDisputesAdminProvider);
    final usersAsync = ref.watch(allUsersAdminProvider);
    final activiteAsync = ref.watch(adminActiviteProvider);
    final topProduitsAsync = ref.watch(adminTopProduitsProvider);

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
              _Header(
                admin: admin,
                demandesAsync: demandesAsync,
                litigesAsync: litigesAsync,
              ),
              const SizedBox(height: AppSpacing.xxl),
              _KpiRow(
                produitsAsync: produitsAsync,
                commandesAsync: commandesAsync,
                demandesAsync: demandesAsync,
                litigesAsync: litigesAsync,
              ),
              const SizedBox(height: AppSpacing.xl),
              _ActiviteCard(
                periode: _periode,
                onPeriodeChange: (p) => setState(() => _periode = p),
                activiteAsync: activiteAsync,
              ),
              const SizedBox(height: AppSpacing.xl),
              LayoutBuilder(
                builder: (context, constraints) {
                  final table = _DernieresCommandesCard(
                    commandesAsync: commandesAsync,
                    utilisateurParId: utilisateurParId,
                    recherche: _rechercheCommandes,
                    onRechercheChange: (v) => setState(() => _rechercheCommandes = v),
                  );
                  final topProduits = _TopProduitsCard(topProduitsAsync: topProduitsAsync);

                  if (constraints.maxWidth > 900) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: table),
                        const SizedBox(width: AppSpacing.xl),
                        Expanded(child: topProduits),
                      ],
                    );
                  }
                  return Column(
                    children: [table, const SizedBox(height: AppSpacing.xl), topProduits],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Utilisateur? admin;
  final AsyncValue<List<DemandeVendeur>> demandesAsync;
  final AsyncValue<List<Litige>> litigesAsync;

  const _Header({required this.admin, required this.demandesAsync, required this.litigesAsync});

  @override
  Widget build(BuildContext context) {
    final demandesEnAttente = demandesAsync.valueOrNull
            ?.where((d) => d.statut == SellerRequestStatus.enAttente)
            .length ??
        0;
    final litigesOuverts = litigesAsync.valueOrNull
            ?.where((l) => l.statut == DisputeStatus.ouvert || l.statut == DisputeStatus.enExamen)
            .length ??
        0;
    final alertes = demandesEnAttente + litigesOuverts;

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: AppSpacing.md,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bonjour, ${admin?.prenom ?? 'Admin'} !', style: AppTypography.displayMedium),
            const SizedBox(height: 2),
            Text(
              'Voici ce qui se passe sur votre plateforme aujourd\'hui.',
              style: AppTypography.bodyMedium,
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.mdRadius,
                border: Border.all(color: AppColors.gray200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 15, color: AppColors.gray500),
                  const SizedBox(width: 6),
                  Text(Formatters.shortDate(DateTime.now()), style: AppTypography.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.mdRadius,
                    border: Border.all(color: AppColors.gray200),
                  ),
                  child: const Icon(Icons.notifications_outlined, color: AppColors.gray700),
                ),
                if (alertes > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        '$alertes',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppSpacing.md),
            AppAvatar(initiales: admin?.initiales ?? '?', size: 44),
          ],
        ),
      ],
    );
  }
}

class _KpiRow extends StatelessWidget {
  final AsyncValue<List<Produit>> produitsAsync;
  final AsyncValue<List<Commande>> commandesAsync;
  final AsyncValue<List<DemandeVendeur>> demandesAsync;
  final AsyncValue<List<Litige>> litigesAsync;

  const _KpiRow({
    required this.produitsAsync,
    required this.commandesAsync,
    required this.demandesAsync,
    required this.litigesAsync,
  });

  @override
  Widget build(BuildContext context) {
    final produits = produitsAsync.valueOrNull;
    final commandes = commandesAsync.valueOrNull;
    final demandes = demandesAsync.valueOrNull;
    final litiges = litigesAsync.valueOrNull;

    final enVente = produits?.where((p) => p.statut == ProductStatus.enVente).length;
    final commandesEnCours = commandes
        ?.where((c) => c.statut != OrderStatus.livree && c.statut != OrderStatus.annulee)
        .length;
    final demandesEnAttente =
        demandes?.where((d) => d.statut == SellerRequestStatus.enAttente).length;
    final litigesOuverts = litiges
        ?.where((l) => l.statut == DisputeStatus.ouvert || l.statut == DisputeStatus.enExamen)
        .length;

    final cartes = [
      _KpiCard(
        titre: 'Produits en vente',
        valeur: enVente,
        icon: Icons.storefront_rounded,
        couleur: AppColors.success,
      ),
      _KpiCard(
        titre: 'Commandes en cours',
        valeur: commandesEnCours,
        icon: Icons.local_shipping_outlined,
        couleur: AppColors.blue,
      ),
      _KpiCard(
        titre: 'Demandes en attente',
        valeur: demandesEnAttente,
        icon: Icons.assignment_outlined,
        couleur: AppColors.gold,
      ),
      _KpiCard(
        titre: 'Litiges ouverts',
        valeur: litigesOuverts,
        icon: Icons.gavel_rounded,
        couleur: AppColors.danger,
      ),
    ];

    // Grille qui occupe toute la largeur disponible plutôt que des
    // cartes à taille fixe collées à gauche : 4 colonnes sur grand
    // écran, 2 sur tablette/téléphone, 1 sur les très petits écrans.
    return LayoutBuilder(
      builder: (context, constraints) {
        final colonnes = constraints.maxWidth >= 1000
            ? 4
            : constraints.maxWidth >= 620
                ? 2
                : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cartes.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: colonnes,
            crossAxisSpacing: AppSpacing.lg,
            mainAxisSpacing: AppSpacing.lg,
            mainAxisExtent: 128,
          ),
          itemBuilder: (context, i) => cartes[i],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String titre;
  final int? valeur;
  final IconData icon;
  final Color couleur;

  const _KpiCard({
    required this.titre,
    required this.valeur,
    required this.icon,
    required this.couleur,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: couleur.withValues(alpha: 0.12),
              borderRadius: AppRadius.smRadius,
            ),
            child: Icon(icon, color: couleur, size: 22),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            valeur == null ? '…' : '$valeur',
            style: AppTypography.displayMedium.copyWith(color: AppColors.black),
          ),
          Text(titre, style: AppTypography.bodySmall),
        ],
      ),
    );
  }
}

class _ActiviteCard extends StatelessWidget {
  final _Periode periode;
  final ValueChanged<_Periode> onPeriodeChange;
  final AsyncValue<List<DailyActivite>> activiteAsync;

  const _ActiviteCard({
    required this.periode,
    required this.onPeriodeChange,
    required this.activiteAsync,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.gray200),
      ),
      child: activiteAsync.when(
        loading: () => const SizedBox(
          height: 260,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => const SizedBox(
          height: 260,
          child: Center(child: Text('Impossible de charger l\'activité.')),
        ),
        data: (jours) {
          final donnees = periode == _Periode.j7 ? jours.sublist(jours.length - 7) : jours;
          final totalCommandes = donnees.fold<int>(0, (s, j) => s + j.nombreCommandes);
          final totalRevenu = donnees.fold<double>(0, (s, j) => s + j.revenuCommission);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: AppSpacing.sm,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Activité de la plateforme', style: AppTypography.titleLarge),
                      const SizedBox(height: 2),
                      Text('Commandes passées sur la période', style: AppTypography.bodySmall),
                    ],
                  ),
                  _PeriodeSelector(periode: periode, onChange: onPeriodeChange),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                runSpacing: 4,
                children: [
                  Text('$totalCommandes', style: AppTypography.displayLarge),
                  const SizedBox(width: AppSpacing.sm),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, right: AppSpacing.lg),
                    child: Text('commande(s)', style: AppTypography.bodyMedium),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '≈ ${Formatters.currency(totalRevenu)} de commission',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                height: 220,
                child: donnees.every((j) => j.nombreCommandes == 0)
                    ? Center(
                        child: Text(
                          'Aucune commande sur cette période.',
                          style: AppTypography.bodyMedium,
                        ),
                      )
                    : _CourbeCommandes(donnees: donnees),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PeriodeSelector extends StatelessWidget {
  final _Periode periode;
  final ValueChanged<_Periode> onChange;

  const _PeriodeSelector({required this.periode, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: AppRadius.fullRadius),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PeriodeChip(
            label: '7 jours',
            selected: periode == _Periode.j7,
            onTap: () => onChange(_Periode.j7),
          ),
          _PeriodeChip(
            label: '30 jours',
            selected: periode == _Periode.j30,
            onTap: () => onChange(_Periode.j30),
          ),
        ],
      ),
    );
  }
}

class _PeriodeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodeChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? AppColors.black : Colors.transparent,
          borderRadius: AppRadius.fullRadius,
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: selected ? AppColors.white : AppColors.gray600,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _CourbeCommandes extends StatelessWidget {
  final List<DailyActivite> donnees;
  const _CourbeCommandes({required this.donnees});

  @override
  Widget build(BuildContext context) {
    final maxCommandes =
        donnees.map((d) => d.nombreCommandes).fold<int>(0, (a, b) => a > b ? a : b);
    final maxY = maxCommandes == 0 ? 5.0 : (maxCommandes * 1.3);
    final spots = [
      for (var i = 0; i < donnees.length; i++)
        FlSpot(i.toDouble(), donnees[i].nombreCommandes.toDouble()),
    ];
    final intervalleLabel = donnees.length <= 7 ? 1 : (donnees.length / 6).ceil();

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.gray100, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: intervalleLabel.toDouble(),
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= donnees.length) return const SizedBox.shrink();
                final jour = donnees[i].jour;
                final label = donnees.length <= 7
                    ? DateFormat('E', 'fr_FR').format(jour)
                    : DateFormat('d/MM').format(jour);
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(label, style: AppTypography.caption),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.black,
            getTooltipItems: (touched) => touched.map((s) {
              final j = donnees[s.x.toInt()];
              return LineTooltipItem(
                '${Formatters.shortDate(j.jour)}\n${j.nombreCommandes} commande(s)',
                const TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.w600),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.violet,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.violet.withValues(alpha: 0.18),
                  AppColors.violet.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DernieresCommandesCard extends StatelessWidget {
  final AsyncValue<List<Commande>> commandesAsync;
  final Map<String, Utilisateur> utilisateurParId;
  final String recherche;
  final ValueChanged<String> onRechercheChange;

  const _DernieresCommandesCard({
    required this.commandesAsync,
    required this.utilisateurParId,
    required this.recherche,
    required this.onRechercheChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Dernières commandes', style: AppTypography.titleLarge),
              TextButton(
                onPressed: () => context.go(AppRoutes.adminOrders),
                child: const Text('Voir tout'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppSearchField(hint: 'Rechercher une commande...', onChanged: onRechercheChange),
          const SizedBox(height: AppSpacing.md),
          commandesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Text('Impossible de charger les commandes.'),
            ),
            data: (commandes) {
              final requete = recherche.toLowerCase();
              final filtrees = commandes.where((c) {
                if (requete.isEmpty) return true;
                final client = utilisateurParId[c.acheteurId]?.nomComplet.toLowerCase() ?? '';
                return c.reference.toLowerCase().contains(requete) || client.contains(requete);
              }).take(8).toList();

              if (filtrees.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Center(
                    child: Text('Aucune commande trouvée.', style: AppTypography.bodyMedium),
                  ),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      headingRowHeight: 40,
                      dataRowMinHeight: 48,
                      dataRowMaxHeight: 56,
                      columns: const [
                        DataColumn(label: Text('Référence')),
                        DataColumn(label: Text('Client')),
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Montant')),
                        DataColumn(label: Text('Statut')),
                      ],
                      rows: [
                        for (final c in filtrees)
                          DataRow(cells: [
                            DataCell(Text(
                              c.reference,
                              style:
                                  AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                            )),
                            DataCell(Text(utilisateurParId[c.acheteurId]?.nomComplet ?? '—')),
                            DataCell(Text(Formatters.shortDate(c.dateCommande))),
                            DataCell(Text(Formatters.currency(c.montantTotal))),
                            DataCell(StatusBadge(label: c.statut.label, color: c.statut.color)),
                          ]),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TopProduitsCard extends StatelessWidget {
  final AsyncValue<List<TopProduit>> topProduitsAsync;
  const _TopProduitsCard({required this.topProduitsAsync});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: AppRadius.lgRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: AppColors.white),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Meilleures ventes',
                  style: AppTypography.titleLarge.copyWith(color: AppColors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Les produits qui se vendent le mieux sur la plateforme.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.white.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: AppSpacing.lg),
          topProduitsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.white)),
            error: (_, __) => Text(
              'Impossible de charger.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.white),
            ),
            data: (produits) {
              if (produits.isEmpty) {
                return Text(
                  'Pas encore de vente enregistrée.',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.white),
                );
              }
              return Column(
                children: [
                  for (final tp in produits)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: AppRadius.smRadius,
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: tp.produit.photoPrincipale != null
                                  ? Image.network(tp.produit.photoPrincipale!.url, fit: BoxFit.cover)
                                  : Container(color: AppColors.white.withValues(alpha: 0.15)),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tp.produit.titre,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${tp.quantiteVendue} vendu(s)',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
