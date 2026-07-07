import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/errors/error_view.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/cards/status_badge.dart';
import '../../../../shared/widgets/feedback/app_loading_indicator.dart';
import '../../../../shared/widgets/layout/section_header.dart';
import '../../../auth/providers/session_provider.dart';
import '../../providers/sell_provider.dart';

class SellHomeScreen extends ConsumerWidget {
  const SellHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final utilisateur = ref.watch(currentUserProvider);
    final demandesAsync = ref.watch(mySellerRequestsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.violet,
          onRefresh: () async => ref.invalidate(mySellerRequestsProvider),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bonjour, ${utilisateur?.prenom ?? 'Vendeur'}',
                        style: AppTypography.headline,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Soumettez un produit — un agent le vérifiera chez vous.',
                        style: AppTypography.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AppPrimaryButton(
                        label: 'Soumettre un produit',
                        icon: Icons.add_rounded,
                        onPressed: () => context.go(AppRoutes.sellStep1),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      const SectionHeader(title: 'Mes demandes'),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ),
              demandesAsync.when(
                loading: () => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppLoadingIndicator(),
                ),
                error: (_, __) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: ErrorView(
                    message: 'Impossible de charger vos demandes.',
                    onRetry: () => ref.invalidate(mySellerRequestsProvider),
                  ),
                ),
                data: (demandes) {
                  if (demandes.isEmpty) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xxl),
                        child: EmptyView(
                          message: 'Aucune demande en cours',
                          subtitle: 'Commencez par soumettre votre premier produit.',
                          icon: Icons.inventory_2_outlined,
                        ),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final d = demandes[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.lg),
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
                                      Expanded(
                                        child: Text(
                                          d.typeProduitSouhaite,
                                          style: AppTypography.titleMedium,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      StatusBadge(
                                        label: d.statut.label,
                                        color: d.statut.color,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    '${Formatters.currency(d.prixSouhaite)} souhaité · ${Formatters.shortDate(d.dateCreation)}',
                                    style: AppTypography.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: demandes.length,
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
