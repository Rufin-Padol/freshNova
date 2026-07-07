import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/errors/error_view.dart';
import '../../../../domain/enums/user_role.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/buttons/app_secondary_button.dart';
import '../../../../shared/widgets/cards/app_avatar.dart';
import '../../../../shared/widgets/cards/info_row.dart';
import '../../../../shared/widgets/feedback/app_loading_indicator.dart';
import '../../../../shared/widgets/illustrations/empty_image_illustration.dart';
import '../../../auth/providers/session_provider.dart';
import '../../../favorites/providers/favorites_provider.dart';
import '../../../shop/providers/product_list_provider.dart';

/// Fiche détaillée d'un produit, accessible aux acheteurs depuis la
/// boutique. Affiche la photo officielle, le vendeur, l'état, la
/// localisation, et la description — y compris les défauts connus
/// affichés de façon transparente, conformément au cahier des charges.
class ProductDetailScreen extends ConsumerWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final produitAsync = ref.watch(productDetailProvider(productId));
    final utilisateur = ref.watch(currentUserProvider);
    final estAcheteur = utilisateur?.role == UserRole.acheteur;
    final favoris = ref.watch(favoritesProvider).valueOrNull ?? [];
    final estFavori = favoris.contains(productId);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: produitAsync.when(
        loading: () => const AppLoadingIndicator(),
        error: (_, __) => ErrorView(
          message: 'Impossible de charger ce produit.',
          onRetry: () => ref.invalidate(productDetailProvider(productId)),
        ),
        data: (produit) {
          if (produit == null) {
            return const ErrorView(message: 'Ce produit n\'existe plus.');
          }
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.black,
                expandedHeight: 320,
                leading: IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.white,
                  ),
                ),
                actions: [
                  if (estAcheteur)
                    IconButton(
                      onPressed: () =>
                          ref.read(favoritesProvider.notifier).toggle(productId),
                      icon: Icon(
                        estFavori ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: estFavori ? AppColors.danger : AppColors.black,
                      ),
                      style: IconButton.styleFrom(backgroundColor: AppColors.white),
                    ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: produit.photoPrincipale != null
                      ? Image.network(
                          produit.photoPrincipale!.url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const EmptyImageIllustration(),
                        )
                      : const EmptyImageIllustration(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(produit.titre, style: AppTypography.displayMedium),
                      const SizedBox(height: 6),
                      Text(
                        Formatters.currency(produit.prix),
                        style: AppTypography.displayMedium.copyWith(color: AppColors.violet),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppRadius.lgRadius,
                          border: Border.all(color: AppColors.gray200),
                        ),
                        child: Row(
                          children: [
                            const AppAvatar(initiales: 'V', size: 44),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text('Vendeur vérifié', style: AppTypography.titleMedium),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.verified_rounded,
                                          size: 16, color: AppColors.blue),
                                    ],
                                  ),
                                  Text(
                                    'Identité et produit vérifiés par AfriDeal',
                                    style: AppTypography.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text('Description', style: AppTypography.titleLarge),
                      const SizedBox(height: AppSpacing.sm),
                      Text(produit.description, style: AppTypography.bodyLarge),
                      if (produit.defautsConnus != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.warningSurface,
                            borderRadius: AppRadius.mdRadius,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline_rounded,
                                  size: 18, color: AppColors.warning),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  produit.defautsConnus!,
                                  style: AppTypography.bodyMedium
                                      .copyWith(color: AppColors.gray700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        children: [
                          Expanded(
                            child: InfoRow(
                              icon: Icons.checkroom_outlined,
                              label: 'État',
                              value: produit.etat.label,
                            ),
                          ),
                          Expanded(
                            child: InfoRow(
                              icon: Icons.location_on_outlined,
                              label: 'Localisation',
                              value: produit.localisation,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.huge),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: produitAsync.maybeWhen(
        data: (produit) => produit == null
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppSecondaryButton(
                          label: 'Contacter',
                          icon: Icons.chat_bubble_outline_rounded,
                          onPressed: () => context.push(AppRoutes.messages),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        flex: 2,
                        child: AppPrimaryButton(
                          label: 'Acheter en sécurité',
                          icon: Icons.shield_outlined,
                          onPressed: () => context.push(AppRoutes.checkout, extra: produit),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        orElse: () => null,
      ),
    );
  }
}
