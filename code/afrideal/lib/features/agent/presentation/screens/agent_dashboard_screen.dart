import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/errors/error_view.dart';
import '../../../../domain/enums/mission_status.dart';
import '../../../../shared/widgets/cards/status_badge.dart';
import '../../../../shared/widgets/feedback/app_loading_indicator.dart';
import '../../../auth/providers/session_provider.dart';
import '../../providers/agent_provider.dart';

class AgentDashboardScreen extends ConsumerWidget {
  const AgentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final utilisateur = ref.watch(currentUserProvider);
    final missionsAsync = ref.watch(myMissionsProvider);
    final stats = ref.watch(agentStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.violet,
          onRefresh: () async => ref.invalidate(myMissionsProvider),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bonjour, ${utilisateur?.prenom ?? 'Agent'}',
                        style: AppTypography.headline,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text('Vos missions du jour', style: AppTypography.bodyMedium),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              valeur: '${stats.missionsCompleteesCeMois}',
                              label: 'Complétées\nce mois',
                              couleur: AppColors.violet,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _StatCard(
                              valeur: '${stats.tauxReussite.toStringAsFixed(0)}%',
                              label: 'Taux de\nréussite',
                              couleur: AppColors.success,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _StatCard(
                              valeur: '${stats.zonesCouvertes}',
                              label: 'Zones\ncouvertes',
                              couleur: AppColors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      OutlinedButton.icon(
                        onPressed: () => context.push(AppRoutes.agentNewCollecte),
                        icon: const Icon(Icons.add_location_alt_outlined),
                        label: const Text('Nouvelle collecte terrain (non assignée)'),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
              missionsAsync.when(
                loading: () => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppLoadingIndicator(),
                ),
                error: (_, __) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: ErrorView(
                    message: 'Impossible de charger vos missions.',
                    onRetry: () => ref.invalidate(myMissionsProvider),
                  ),
                ),
                data: (missions) {
                  if (missions.isEmpty) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xxl),
                        child: EmptyView(
                          message: 'Aucune mission assignée',
                          subtitle: 'Vos prochaines missions apparaîtront ici.',
                          icon: Icons.route_outlined,
                        ),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final m = missions[i];
                          final estCollecte = m.type == MissionType.collecte;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: InkWell(
                              onTap: () => context.push(
                                AppRoutes.agentMissionDetail.replaceFirst(':missionId', m.id),
                              ),
                              borderRadius: AppRadius.lgRadius,
                              child: Container(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: AppRadius.lgRadius,
                                  border: Border.all(color: AppColors.gray200),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: estCollecte
                                            ? AppColors.violetSurface
                                            : AppColors.blueSurface,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        estCollecte
                                            ? Icons.inventory_2_outlined
                                            : Icons.local_shipping_outlined,
                                        color: estCollecte ? AppColors.violet : AppColors.blue,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(m.type.label, style: AppTypography.titleMedium),
                                          const SizedBox(height: 2),
                                          Text(
                                            Formatters.dateWithTime(m.dateHeure),
                                            style: AppTypography.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    StatusBadge(
                                      label: m.statut.label,
                                      color: m.statut.color,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: missions.length,
                      ),
                    ),
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

class _StatCard extends StatelessWidget {
  final String valeur;
  final String label;
  final Color couleur;

  const _StatCard({required this.valeur, required this.label, required this.couleur});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        children: [
          Text(
            valeur,
            style: AppTypography.displayMedium.copyWith(color: couleur),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }
}
