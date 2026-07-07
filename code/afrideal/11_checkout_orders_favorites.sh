#!/bin/bash
# ============================================================================
# SCRIPT 11 — Paiement, Commandes et Favoris (parcours Acheteur complet)
# Projet : AfriDeal — Plateforme de revente de seconde main (Cameroun)
# ============================================================================
#
# CE QUE FAIT CE SCRIPT :
#   1. Providers :
#        • lib/features/cart_checkout/providers/checkout_provider.dart
#        • lib/features/orders/providers/order_list_provider.dart
#   2. Écrans :
#        • CheckoutScreen   → choix du mode de livraison, méthode de
#          paiement (Orange Money / MTN MoMo), confirmation d'achat
#        • OrdersScreen     → liste des commandes de l'acheteur, avec
#          statut coloré (cohérent avec ProductStatus du script 03)
#        • OrderDetailScreen → suivi détaillé d'une commande, avec
#          barre de progression (ProgressSteps du script 07)
#        • FavoritesScreen  → grille des produits favoris
#
# NOTE SUR LE MODÈLE D'ACHAT :
#   Conformément au cahier des charges (chaque produit d'occasion est
#   UNIQUE, contrairement à un e-commerce classique avec stock), il
#   n'existe pas de "panier multi-articles" : l'achat se fait
#   directement depuis la fiche produit vers le paiement d'un seul
#   article à la fois. La route /cart existante dans le routeur reste
#   déclarée pour une éventuelle évolution future, mais le flux
#   principal passe par /checkout directement.
#
# COMMENT EXÉCUTER CE SCRIPT :
#   bash 11_checkout_orders_favorites.sh
#
# CE QUE VOUS DEVEZ VOIR SI TOUT FONCTIONNE :
#   Le message final "✔ Script 11 terminé avec succès."
#   Le parcours Acheteur est désormais complet : boutique → fiche
#   produit → paiement → confirmation → suivi de commande.
# ============================================================================

set -e

echo "============================================================"
echo "  AfriDeal — Script 11/14 : Paiement, Commandes, Favoris"
echo "============================================================"

if [ ! -f "lib/features/product_detail/presentation/screens/product_detail_screen.dart" ]; then
  echo "ERREUR : product_detail_screen.dart introuvable. Avez-vous exécuté le script 10 ?"
  exit 1
fi

mkdir -p lib/features/cart_checkout/providers
mkdir -p lib/features/cart_checkout/presentation/screens
mkdir -p lib/features/orders/providers
mkdir -p lib/features/orders/presentation/screens
mkdir -p lib/features/favorites/presentation/screens

# ============================================================================
# 1. PROVIDER — Checkout (paiement)
# ============================================================================
cat > lib/features/cart_checkout/providers/checkout_provider.dart << 'EOF'
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../domain/entities/commande.dart';
import '../../../domain/entities/paiement.dart';
import '../../../domain/entities/produit.dart';
import '../../../domain/enums/order_status.dart';
import '../../../domain/enums/payment_status.dart';
import '../../../domain/enums/product_status.dart';
import '../../auth/providers/session_provider.dart';

const _uuid = Uuid();

/// Représente l'avancement du processus de paiement, pour piloter
/// l'interface (bouton désactivé pendant le traitement, affichage
/// d'un message de succès ou d'erreur).
enum CheckoutStep { formulaire, traitement, succes, echec }

class CheckoutState {
  final CheckoutStep step;
  final DeliveryMode modeLivraison;
  final PaymentMethod methode;
  final String adresse;
  final String numeroPaieur;
  final String? messageErreur;
  final Commande? commandeCreee;

  const CheckoutState({
    this.step = CheckoutStep.formulaire,
    this.modeLivraison = DeliveryMode.livraison,
    this.methode = PaymentMethod.orangeMoney,
    this.adresse = '',
    this.numeroPaieur = '',
    this.messageErreur,
    this.commandeCreee,
  });

  CheckoutState copyWith({
    CheckoutStep? step,
    DeliveryMode? modeLivraison,
    PaymentMethod? methode,
    String? adresse,
    String? numeroPaieur,
    String? messageErreur,
    Commande? commandeCreee,
  }) {
    return CheckoutState(
      step: step ?? this.step,
      modeLivraison: modeLivraison ?? this.modeLivraison,
      methode: methode ?? this.methode,
      adresse: adresse ?? this.adresse,
      numeroPaieur: numeroPaieur ?? this.numeroPaieur,
      messageErreur: messageErreur,
      commandeCreee: commandeCreee ?? this.commandeCreee,
    );
  }
}

/// Pilote le processus complet de paiement : création de la
/// commande, simulation du paiement Mobile Money, mise à jour du
/// statut du produit (En vente → Réservé → En livraison).
///
/// En mode local, le paiement est simulé après un court délai pour
/// reproduire l'expérience d'attente réelle d'une confirmation
/// Mobile Money, sans jamais faire échouer arbitrairement la
/// transaction (l'objectif ici est de démontrer le parcours, pas de
/// tester la gestion d'échec de paiement).
class CheckoutNotifier extends Notifier<CheckoutState> {
  @override
  CheckoutState build() => const CheckoutState();

  void setModeLivraison(DeliveryMode mode) {
    state = state.copyWith(modeLivraison: mode);
  }

  void setMethode(PaymentMethod methode) {
    state = state.copyWith(methode: methode);
  }

  void setAdresse(String adresse) {
    state = state.copyWith(adresse: adresse);
  }

  void setNumeroPaieur(String numero) {
    state = state.copyWith(numeroPaieur: numero);
  }

  void reset() {
    state = const CheckoutState();
  }

  Future<void> confirmerAchat(Produit produit) async {
    final utilisateur = ref.read(currentUserProvider);
    if (utilisateur == null) {
      state = state.copyWith(
        step: CheckoutStep.echec,
        messageErreur: 'Vous devez être connecté pour acheter.',
      );
      return;
    }
    if (state.adresse.trim().isEmpty) {
      state = state.copyWith(messageErreur: 'Veuillez renseigner une adresse de livraison.');
      return;
    }
    if (state.numeroPaieur.trim().isEmpty) {
      state = state.copyWith(messageErreur: 'Veuillez renseigner le numéro Mobile Money.');
      return;
    }

    state = state.copyWith(step: CheckoutStep.traitement, messageErreur: null);

    // Simule le délai de confirmation Mobile Money.
    await Future.delayed(const Duration(seconds: 2));

    try {
      final orderRepo = ref.read(orderRepositoryProvider);
      final paymentRepo = ref.read(paymentRepositoryProvider);
      final productRepo = ref.read(productRepositoryProvider);

      final commandeId = _uuid.v4();
      final reference = Commande.genererReference(
        DateTime.now().millisecondsSinceEpoch.remainder(10000),
      );

      final commande = Commande(
        id: commandeId,
        reference: reference,
        montantTotal: produit.prix,
        statut: OrderStatus.payee,
        dateCommande: DateTime.now(),
        modeLivraison: state.modeLivraison,
        adresseLivraison: state.adresse,
        acheteurId: utilisateur.id,
        produitId: produit.id,
      );
      await orderRepo.save(commande);

      await paymentRepo.save(Paiement(
        id: _uuid.v4(),
        montant: produit.prix,
        methode: state.methode,
        reference: 'PAY-${_uuid.v4().substring(0, 8).toUpperCase()}',
        statut: PaymentStatus.valide,
        dateHeure: DateTime.now(),
        numeroPaieur: state.numeroPaieur,
        commandeId: commandeId,
      ));

      await productRepo.updateStatut(produit.id, ProductStatus.reserve);

      state = state.copyWith(step: CheckoutStep.succes, commandeCreee: commande);
    } catch (e) {
      state = state.copyWith(
        step: CheckoutStep.echec,
        messageErreur: 'Une erreur est survenue. Veuillez réessayer.',
      );
    }
  }
}

final checkoutProvider = NotifierProvider<CheckoutNotifier, CheckoutState>(
  CheckoutNotifier.new,
);
EOF
echo "→ lib/features/cart_checkout/providers/checkout_provider.dart créé."

# ============================================================================
# 2. PROVIDER — Liste des commandes
# ============================================================================
cat > lib/features/orders/providers/order_list_provider.dart << 'EOF'
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../domain/entities/commande.dart';
import '../../auth/providers/session_provider.dart';

/// Commandes de l'acheteur connecté, triées des plus récentes aux
/// plus anciennes.
final myOrdersProvider = FutureProvider<List<Commande>>((ref) async {
  final utilisateur = ref.watch(currentUserProvider);
  if (utilisateur == null) return [];
  final repo = ref.watch(orderRepositoryProvider);
  final commandes = await repo.getByAcheteur(utilisateur.id);
  commandes.sort((a, b) => b.dateCommande.compareTo(a.dateCommande));
  return commandes;
});

/// Détail d'une commande unique, utilisé par l'écran de suivi.
final orderDetailProvider = FutureProvider.family<Commande?, String>((ref, orderId) async {
  final repo = ref.watch(orderRepositoryProvider);
  return repo.getById(orderId);
});
EOF
echo "→ lib/features/orders/providers/order_list_provider.dart créé."

# ============================================================================
# 3. ÉCRAN — Checkout / Paiement
# ============================================================================
cat > lib/features/cart_checkout/presentation/screens/checkout_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../domain/entities/produit.dart';
import '../../../../domain/enums/order_status.dart';
import '../../../../domain/enums/payment_status.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/illustrations/onboarding_illustrations.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../providers/checkout_provider.dart';

/// Écran de paiement, déclenché depuis la fiche produit.
///
/// Reçoit le produit à acheter directement (plutôt que de passer par
/// un identifiant et un nouveau chargement), car au moment où
/// l'utilisateur arrive ici, le produit est déjà chargé en mémoire
/// par l'écran précédent — évite un aller-retour réseau inutile,
/// important pour la fluidité sur connexion lente.
class CheckoutScreen extends ConsumerWidget {
  final Produit produit;

  const CheckoutScreen({super.key, required this.produit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(checkoutProvider);

    if (state.step == CheckoutStep.succes) {
      return _CheckoutSuccessView(produit: produit);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Paiement sécurisé')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.lgRadius,
                border: Border.all(color: AppColors.gray200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(produit.titre, style: AppTypography.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          Formatters.currency(produit.prix),
                          style: AppTypography.titleLarge.copyWith(color: AppColors.violet),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Mode de livraison', style: AppTypography.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            _DeliveryModeSelector(
              selected: state.modeLivraison,
              onChanged: (mode) => ref.read(checkoutProvider.notifier).setModeLivraison(mode),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppTextField(
              label: 'Adresse de livraison',
              hint: 'Quartier, rue, point de repère...',
              onChanged: (v) => ref.read(checkoutProvider.notifier).setAdresse(v),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Méthode de paiement', style: AppTypography.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            _PaymentMethodSelector(
              selected: state.methode,
              onChanged: (methode) => ref.read(checkoutProvider.notifier).setMethode(methode),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Numéro Mobile Money',
              hint: '6XX XXX XXX',
              keyboardType: TextInputType.phone,
              onChanged: (v) => ref.read(checkoutProvider.notifier).setNumeroPaieur(v),
            ),
            if (state.messageErreur != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                state.messageErreur!,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.danger),
              ),
            ],
            const SizedBox(height: AppSpacing.huge),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AppPrimaryButton(
            label: state.step == CheckoutStep.traitement
                ? 'Confirmation en cours...'
                : 'Payer ${Formatters.currency(produit.prix)}',
            isLoading: state.step == CheckoutStep.traitement,
            onPressed: state.step == CheckoutStep.traitement
                ? null
                : () => ref.read(checkoutProvider.notifier).confirmerAchat(produit),
          ),
        ),
      ),
    );
  }
}

class _DeliveryModeSelector extends StatelessWidget {
  final DeliveryMode selected;
  final void Function(DeliveryMode) onChanged;

  const _DeliveryModeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: DeliveryMode.values.map((mode) {
        final estSelectionne = mode == selected;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: mode == DeliveryMode.livraison ? AppSpacing.sm : 0),
            child: GestureDetector(
              onTap: () => onChanged(mode),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: estSelectionne ? AppColors.violetSurface : AppColors.surface,
                  borderRadius: AppRadius.mdRadius,
                  border: Border.all(
                    color: estSelectionne ? AppColors.violet : AppColors.gray200,
                    width: estSelectionne ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      mode == DeliveryMode.livraison
                          ? Icons.local_shipping_outlined
                          : Icons.storefront_outlined,
                      color: estSelectionne ? AppColors.violet : AppColors.gray500,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      mode.label,
                      style: AppTypography.bodySmall.copyWith(
                        color: estSelectionne ? AppColors.violet : AppColors.gray600,
                        fontWeight: estSelectionne ? FontWeight.w600 : FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PaymentMethodSelector extends StatelessWidget {
  final PaymentMethod selected;
  final void Function(PaymentMethod) onChanged;

  const _PaymentMethodSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: PaymentMethod.values.map((methode) {
        final estSelectionne = methode == selected;
        final couleur = methode == PaymentMethod.orangeMoney
            ? const Color(0xFFFF6600)
            : const Color(0xFFFFCC00);
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: methode == PaymentMethod.orangeMoney ? AppSpacing.sm : 0,
            ),
            child: GestureDetector(
              onTap: () => onChanged(methode),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: estSelectionne ? AppColors.violetSurface : AppColors.surface,
                  borderRadius: AppRadius.mdRadius,
                  border: Border.all(
                    color: estSelectionne ? AppColors.violet : AppColors.gray200,
                    width: estSelectionne ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      methode.label,
                      style: AppTypography.bodySmall.copyWith(
                        color: estSelectionne ? AppColors.violet : AppColors.gray600,
                        fontWeight: estSelectionne ? FontWeight.w600 : FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CheckoutSuccessView extends ConsumerWidget {
  final Produit produit;

  const _CheckoutSuccessView({required this.produit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SuccessIllustration(size: 140),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Paiement confirmé !',
                style: AppTypography.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Votre achat de "${produit.titre}" a été sécurisé. '
                'Le vendeur a été notifié et votre produit sera bientôt en livraison.',
                style: AppTypography.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxxl),
              AppPrimaryButton(
                label: 'Suivre ma commande',
                onPressed: () {
                  ref.read(checkoutProvider.notifier).reset();
                  context.go(AppRoutes.orders);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
EOF
echo "→ lib/features/cart_checkout/presentation/screens/checkout_screen.dart créé."

# ============================================================================
# 4. ÉCRAN — Liste des commandes
# ============================================================================
cat > lib/features/orders/presentation/screens/orders_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/errors/error_view.dart';
import '../../../../shared/widgets/cards/status_badge.dart';
import '../../../../shared/widgets/feedback/app_loading_indicator.dart';
import '../../providers/order_list_provider.dart';

/// Liste des commandes de l'acheteur, avec statut coloré cohérent
/// avec le système de statut utilisé partout ailleurs dans l'app.
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commandesAsync = ref.watch(myOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mes commandes')),
      body: commandesAsync.when(
        loading: () => const AppLoadingIndicator(),
        error: (_, __) => ErrorView(
          message: 'Impossible de charger vos commandes.',
          onRetry: () => ref.invalidate(myOrdersProvider),
        ),
        data: (commandes) {
          if (commandes.isEmpty) {
            return const EmptyView(
              message: 'Aucune commande pour le moment',
              subtitle: 'Vos achats apparaîtront ici.',
              icon: Icons.receipt_long_outlined,
            );
          }
          return RefreshIndicator(
            color: AppColors.violet,
            onRefresh: () async => ref.invalidate(myOrdersProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: commandes.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final commande = commandes[index];
                return InkWell(
                  onTap: () => context.push(
                    AppRoutes.orderDetail.replaceFirst(':orderId', commande.id),
                  ),
                  borderRadius: AppRadius.lgRadius,
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
                            Text('#${commande.reference}', style: AppTypography.titleMedium),
                            StatusBadge(
                              label: commande.statut.label,
                              color: commande.statut.color,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          Formatters.shortDate(commande.dateCommande),
                          style: AppTypography.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          Formatters.currency(commande.montantTotal),
                          style: AppTypography.titleMedium.copyWith(color: AppColors.violet),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
EOF
echo "→ lib/features/orders/presentation/screens/orders_screen.dart créé."

# ============================================================================
# 5. ÉCRAN — Détail d'une commande
# ============================================================================
cat > lib/features/orders/presentation/screens/order_detail_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/errors/error_view.dart';
import '../../../../domain/enums/order_status.dart';
import '../../../../shared/widgets/cards/info_row.dart';
import '../../../../shared/widgets/feedback/app_loading_indicator.dart';
import '../../../../shared/widgets/layout/progress_steps.dart';
import '../../../shop/providers/product_list_provider.dart';
import '../../providers/order_list_provider.dart';

/// Suivi détaillé d'une commande, avec barre de progression visuelle
/// de l'avancement (Payée → En livraison → Livrée).
class OrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commandeAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Suivi de commande')),
      body: commandeAsync.when(
        loading: () => const AppLoadingIndicator(),
        error: (_, __) => ErrorView(
          message: 'Impossible de charger cette commande.',
          onRetry: () => ref.invalidate(orderDetailProvider(orderId)),
        ),
        data: (commande) {
          if (commande == null) {
            return const ErrorView(message: 'Commande introuvable.');
          }
          final produitAsync = ref.watch(productDetailProvider(commande.produitId));
          final etapeIndex = _etapeIndexPourStatut(commande.statut);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('#${commande.reference}', style: AppTypography.displayMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  Formatters.dateWithTime(commande.dateCommande),
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xxl),
                if (commande.statut != OrderStatus.annulee)
                  ProgressSteps(
                    steps: const ['Payée', 'Livraison', 'Livrée'],
                    currentIndex: etapeIndex,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      produitAsync.when(
                        loading: () => const SizedBox(height: 24),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (produit) => Text(
                          produit?.titre ?? 'Produit',
                          style: AppTypography.titleLarge,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      InfoRow(
                        icon: Icons.payments_outlined,
                        label: 'Montant payé',
                        value: Formatters.currency(commande.montantTotal),
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
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  int _etapeIndexPourStatut(OrderStatus statut) {
    switch (statut) {
      case OrderStatus.pendante:
        return 0;
      case OrderStatus.payee:
        return 0;
      case OrderStatus.enLivraison:
        return 1;
      case OrderStatus.livree:
        return 2;
      case OrderStatus.annulee:
        return 0;
    }
  }
}
EOF
echo "→ lib/features/orders/presentation/screens/order_detail_screen.dart créé."

# ============================================================================
# 6. ÉCRAN — Favoris
# ============================================================================
cat > lib/features/favorites/presentation/screens/favorites_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/errors/error_view.dart';
import '../../../../domain/entities/produit.dart';
import '../../../../shared/widgets/cards/product_card.dart';
import '../../../../shared/widgets/feedback/app_loading_indicator.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../providers/favorites_provider.dart';

/// Grille des produits favoris de l'acheteur. Charge les identifiants
/// favoris puis résout chaque produit correspondant, en filtrant
/// silencieusement les produits qui ne seraient plus disponibles
/// (supprimés ou retirés de la vente entre-temps).
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorisAsync = ref.watch(favoritesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mes favoris')),
      body: favorisAsync.when(
        loading: () => const AppLoadingIndicator(),
        error: (_, __) => ErrorView(
          message: 'Impossible de charger vos favoris.',
          onRetry: () => ref.invalidate(favoritesProvider),
        ),
        data: (favoriteIds) {
          if (favoriteIds.isEmpty) {
            return const EmptyView(
              message: 'Aucun favori pour le moment',
              subtitle: 'Appuyez sur le cœur d\'un produit pour le retrouver ici.',
              icon: Icons.favorite_border_rounded,
            );
          }
          return _FavoritesGrid(favoriteIds: favoriteIds);
        },
      ),
    );
  }
}

class _FavoritesGrid extends ConsumerWidget {
  final List<String> favoriteIds;

  const _FavoritesGrid({required this.favoriteIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productRepo = ref.watch(productRepositoryProvider);

    return FutureBuilder<List<Produit>>(
      future: Future.wait(favoriteIds.map((id) => productRepo.getById(id)))
          .then((liste) => liste.whereType<Produit>().toList()),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const AppLoadingIndicator();
        }
        final produits = snapshot.data!;
        if (produits.isEmpty) {
          return const EmptyView(
            message: 'Aucun favori disponible',
            subtitle: 'Ces produits ne sont plus en vente.',
            icon: Icons.favorite_border_rounded,
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 0.68,
          ),
          itemCount: produits.length,
          itemBuilder: (context, index) {
            final produit = produits[index];
            return ProductCard(
              titre: produit.titre,
              prix: produit.prix,
              localisation: produit.localisation,
              photoUrl: produit.photoPrincipale?.url,
              estFavori: true,
              onFavoriteTap: () => ref.read(favoritesProvider.notifier).toggle(produit.id),
              onTap: () => context.push(
                AppRoutes.productDetail.replaceFirst(':productId', produit.id),
              ),
            );
          },
        );
      },
    );
  }
}
EOF
echo "→ lib/features/favorites/presentation/screens/favorites_screen.dart créé."

# ============================================================================
# 7. MISE À JOUR DE LA FICHE PRODUIT — bouton Acheter ouvre le checkout
#    avec le produit déjà chargé (au lieu de pousser vers /checkout
#    sans contexte).
# ============================================================================
echo "→ Mise à jour de product_detail_screen.dart pour brancher l'achat..."

python3 << 'PYEOF'
import re

path = "lib/features/product_detail/presentation/screens/product_detail_screen.dart"
with open(path, encoding="utf-8") as f:
    content = f.read()

old_import_marker = "import '../../../shop/providers/product_list_provider.dart';\n"
new_import = "import '../../../cart_checkout/presentation/screens/checkout_screen.dart';\n"
if old_import_marker not in content:
    raise SystemExit("ERREUR : marqueur d'import introuvable dans product_detail_screen.dart")
content = content.replace(old_import_marker, old_import_marker + new_import, 1)

old_button = """                        child: AppPrimaryButton(
                          label: 'Acheter en sécurité',
                          icon: Icons.shield_outlined,
                          onPressed: () => context.push(AppRoutes.checkout),
                        ),"""
new_button = """                        child: AppPrimaryButton(
                          label: 'Acheter en sécurité',
                          icon: Icons.shield_outlined,
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CheckoutScreen(produit: produit),
                            ),
                          ),
                        ),"""
if old_button not in content:
    raise SystemExit("ERREUR : bouton Acheter introuvable dans product_detail_screen.dart")
content = content.replace(old_button, new_button, 1)

with open(path, "w", encoding="utf-8") as f:
    f.write(content)

print("product_detail_screen.dart mis à jour : le bouton Acheter ouvre désormais CheckoutScreen avec le produit en mémoire.")
PYEOF

# ============================================================================
# 8. MISE À JOUR DU ROUTEUR — branchement des écrans Commandes/Favoris
# ============================================================================
echo "→ Mise à jour de app_router.dart pour brancher Commandes et Favoris..."

python3 << 'PYEOF'
import re

path = "lib/core/router/app_router.dart"
with open(path, encoding="utf-8") as f:
    content = f.read()

new_imports = (
    "import '../../features/orders/presentation/screens/orders_screen.dart';\n"
    "import '../../features/orders/presentation/screens/order_detail_screen.dart';\n"
    "import '../../features/favorites/presentation/screens/favorites_screen.dart';\n"
)
marker = "import '../../features/product_detail/presentation/screens/product_detail_screen.dart';\n"
if marker not in content:
    raise SystemExit("ERREUR : marqueur d'import introuvable dans app_router.dart")
content = content.replace(marker, marker + new_imports, 1)

replacements = [
    (
        "GoRoute(\n        path: AppRoutes.orders,\n        builder: (context, state) => const PlaceholderScreen(titre: 'Mes commandes'),\n      ),",
        "GoRoute(\n        path: AppRoutes.orders,\n        builder: (context, state) => const OrdersScreen(),\n      ),",
    ),
    (
        "GoRoute(\n        path: AppRoutes.orderDetail,\n        builder: (context, state) => const PlaceholderScreen(titre: 'Détail commande'),\n      ),",
        "GoRoute(\n        path: AppRoutes.orderDetail,\n        builder: (context, state) {\n          final orderId = state.pathParameters['orderId']!;\n          return OrderDetailScreen(orderId: orderId);\n        },\n      ),",
    ),
    (
        "GoRoute(\n        path: AppRoutes.favorites,\n        builder: (context, state) => const PlaceholderScreen(titre: 'Favoris'),\n      ),",
        "GoRoute(\n        path: AppRoutes.favorites,\n        builder: (context, state) => const FavoritesScreen(),\n      ),",
    ),
]

for old, new in replacements:
    if old not in content:
        raise SystemExit(f"ERREUR : bloc de route introuvable :\n{old[:80]}...")
    content = content.replace(old, new, 1)

with open(path, "w", encoding="utf-8") as f:
    f.write(content)

print("app_router.dart mis à jour avec succès (3 routes branchées).")
PYEOF

echo ""
echo "============================================================"
echo "  ✔ Script 11 terminé avec succès."
echo "============================================================"
echo ""
echo "RÉCAPITULATIF DE CE QUI A ÉTÉ CRÉÉ :"
echo "  • Providers : checkout (paiement simulé Orange Money/MTN MoMo,"
echo "    création de commande, mise à jour du statut produit),"
echo "    liste et détail des commandes."
echo "  • CheckoutScreen : choix livraison, méthode de paiement,"
echo "    confirmation avec illustration de succès."
echo "  • OrdersScreen : liste des commandes avec statuts colorés."
echo "  • OrderDetailScreen : suivi avec barre de progression."
echo "  • FavoritesScreen : grille des produits favoris."
echo "  • product_detail_screen.dart : bouton Acheter connecté."
echo "  • app_router.dart : 3 routes supplémentaires branchées."
echo ""
echo "LE PARCOURS ACHETEUR EST MAINTENANT COMPLET :"
echo "  Boutique → Fiche produit → Paiement → Confirmation → Suivi"
echo ""
echo "PROCHAINE ÉTAPE :"
echo "  Dites-moi quand vous êtes prêt pour le script 12 : le"
echo "  parcours Vendeur complet (soumission de produit en 3 étapes,"
echo "  suivi des demandes) et le tableau de bord Agent terrain."
echo ""
