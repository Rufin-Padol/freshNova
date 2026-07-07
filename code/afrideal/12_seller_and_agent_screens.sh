#!/bin/bash
# ============================================================================
# SCRIPT 12 — Parcours Vendeur et Agent terrain
# Projet : AfriDeal — Plateforme de revente de seconde main (Cameroun)
# ============================================================================
#
# CE QUE FAIT CE SCRIPT :
#   1. Providers :
#        • lib/features/sell/providers/sell_provider.dart
#        • lib/features/agent/providers/agent_provider.dart
#   2. Écrans Vendeur :
#        • SellHomeScreen      → tableau de bord vendeur (mes demandes,
#          statuts, bouton "Soumettre un produit")
#        • SellStep1Screen     → étape 1 : description du produit
#          (titre, catégorie, prix souhaité, description)
#        • SellStep2Screen     → étape 2 : disponibilité & adresse
#          de collecte (zone, adresse, créneaux de disponibilité)
#        • SellStep3Screen     → étape 3 : récapitulatif et envoi
#        • SellConfirmScreen   → confirmation avec explication du
#          processus (illustration, étapes à venir)
#   3. Écrans Agent terrain :
#        • AgentDashboardScreen → liste des missions assignées
#          (collectes + livraisons)
#        • AgentMissionDetailScreen → détail d'une mission avec
#          actions (démarrer, signaler arrivée, valider, signaler
#          refus du vendeur)
#
# COMMENT EXÉCUTER CE SCRIPT :
#   bash 12_seller_and_agent_screens.sh
#
# CE QUE VOUS DEVEZ VOIR SI TOUT FONCTIONNE :
#   Le message final "✔ Script 12 terminé avec succès."
# ============================================================================

set -e

echo "============================================================"
echo "  AfriDeal — Script 12/14 : Vendeur et Agent terrain"
echo "============================================================"

if [ ! -f "lib/features/orders/presentation/screens/orders_screen.dart" ]; then
  echo "ERREUR : orders_screen.dart introuvable. Avez-vous exécuté le script 11 ?"
  exit 1
fi

mkdir -p lib/features/sell/providers
mkdir -p lib/features/sell/presentation/screens
mkdir -p lib/features/agent/providers
mkdir -p lib/features/agent/presentation/screens

# ============================================================================
# 1. PROVIDER — Soumission vendeur
# ============================================================================
cat > lib/features/sell/providers/sell_provider.dart << 'EOF'
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../domain/entities/demande_vendeur.dart';
import '../../../domain/enums/seller_request_status.dart';
import '../../auth/providers/session_provider.dart';

const _uuid = Uuid();

/// État du formulaire de soumission en 3 étapes.
class SellFormState {
  // Étape 1 — description
  final String typeProduit;
  final String categorieId;
  final double prixSouhaite;
  final String description;
  final int quantite;

  // Étape 2 — logistique
  final String adresse;
  final String zone;
  final String disponibilite;

  // Navigation
  final int etapeActuelle;
  final bool estEnvoi;
  final bool estEnvoye;
  final String? erreur;

  const SellFormState({
    this.typeProduit = '',
    this.categorieId = '',
    this.prixSouhaite = 0,
    this.description = '',
    this.quantite = 1,
    this.adresse = '',
    this.zone = '',
    this.disponibilite = '',
    this.etapeActuelle = 0,
    this.estEnvoi = false,
    this.estEnvoye = false,
    this.erreur,
  });

  SellFormState copyWith({
    String? typeProduit,
    String? categorieId,
    double? prixSouhaite,
    String? description,
    int? quantite,
    String? adresse,
    String? zone,
    String? disponibilite,
    int? etapeActuelle,
    bool? estEnvoi,
    bool? estEnvoye,
    String? erreur,
    bool clearErreur = false,
  }) {
    return SellFormState(
      typeProduit: typeProduit ?? this.typeProduit,
      categorieId: categorieId ?? this.categorieId,
      prixSouhaite: prixSouhaite ?? this.prixSouhaite,
      description: description ?? this.description,
      quantite: quantite ?? this.quantite,
      adresse: adresse ?? this.adresse,
      zone: zone ?? this.zone,
      disponibilite: disponibilite ?? this.disponibilite,
      etapeActuelle: etapeActuelle ?? this.etapeActuelle,
      estEnvoi: estEnvoi ?? this.estEnvoi,
      estEnvoye: estEnvoye ?? this.estEnvoye,
      erreur: clearErreur ? null : (erreur ?? this.erreur),
    );
  }
}

class SellNotifier extends Notifier<SellFormState> {
  @override
  SellFormState build() => const SellFormState();

  void setTypeProduit(String v) => state = state.copyWith(typeProduit: v, clearErreur: true);
  void setCategorieId(String v) => state = state.copyWith(categorieId: v, clearErreur: true);
  void setPrix(String v) {
    final parsed = double.tryParse(v.replaceAll(' ', '')) ?? 0;
    state = state.copyWith(prixSouhaite: parsed, clearErreur: true);
  }
  void setDescription(String v) => state = state.copyWith(description: v, clearErreur: true);
  void setAdresse(String v) => state = state.copyWith(adresse: v, clearErreur: true);
  void setZone(String v) => state = state.copyWith(zone: v, clearErreur: true);
  void setDisponibilite(String v) => state = state.copyWith(disponibilite: v, clearErreur: true);

  bool validerEtape1() {
    if (state.typeProduit.trim().isEmpty) {
      state = state.copyWith(erreur: 'Veuillez indiquer le type de produit.');
      return false;
    }
    if (state.categorieId.isEmpty) {
      state = state.copyWith(erreur: 'Veuillez choisir une catégorie.');
      return false;
    }
    if (state.prixSouhaite <= 0) {
      state = state.copyWith(erreur: 'Veuillez indiquer un prix valide.');
      return false;
    }
    return true;
  }

  bool validerEtape2() {
    if (state.adresse.trim().isEmpty) {
      state = state.copyWith(erreur: 'Veuillez indiquer l\'adresse de collecte.');
      return false;
    }
    if (state.disponibilite.trim().isEmpty) {
      state = state.copyWith(erreur: 'Veuillez indiquer vos disponibilités.');
      return false;
    }
    return true;
  }

  void allerEtapeSuivante() {
    state = state.copyWith(etapeActuelle: state.etapeActuelle + 1, clearErreur: true);
  }

  void allerEtapePrecedente() {
    if (state.etapeActuelle > 0) {
      state = state.copyWith(etapeActuelle: state.etapeActuelle - 1, clearErreur: true);
    }
  }

  Future<void> soumettre() async {
    final utilisateur = ref.read(currentUserProvider);
    if (utilisateur == null) return;

    state = state.copyWith(estEnvoi: true, clearErreur: true);

    try {
      final repo = ref.read(sellerRequestRepositoryProvider);
      await repo.save(DemandeVendeur(
        id: _uuid.v4(),
        statut: SellerRequestStatus.enAttente,
        adresse: state.adresse,
        disponibilite: state.disponibilite,
        contactVendeur: utilisateur.telephone,
        zone: state.zone.isEmpty ? 'Non précisée' : state.zone,
        dateCreation: DateTime.now(),
        vendeurId: utilisateur.id,
        typeProduitSouhaite: state.typeProduit,
        quantite: state.quantite,
        descriptionInitiale: state.description,
        prixSouhaite: state.prixSouhaite,
      ));
      state = state.copyWith(estEnvoi: false, estEnvoye: true);
    } catch (e) {
      state = state.copyWith(
        estEnvoi: false,
        erreur: 'Envoi impossible. Veuillez réessayer.',
      );
    }
  }

  void reset() => state = const SellFormState();
}

final sellProvider = NotifierProvider<SellNotifier, SellFormState>(SellNotifier.new);

/// Liste des demandes du vendeur connecté, triées par date décroissante.
final mySellerRequestsProvider = FutureProvider<List<DemandeVendeur>>((ref) async {
  final utilisateur = ref.watch(currentUserProvider);
  if (utilisateur == null) return [];
  final repo = ref.watch(sellerRequestRepositoryProvider);
  final demandes = await repo.getByVendeur(utilisateur.id);
  demandes.sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
  return demandes;
});
EOF
echo "→ lib/features/sell/providers/sell_provider.dart créé."

# ============================================================================
# 2. PROVIDER — Agent terrain
# ============================================================================
cat > lib/features/agent/providers/agent_provider.dart << 'EOF'
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../domain/entities/mission.dart';
import '../../../domain/enums/mission_status.dart';
import '../../../domain/enums/product_status.dart';
import '../../../domain/enums/seller_request_status.dart';
import '../../auth/providers/session_provider.dart';

/// Missions de l'agent connecté, triées par date d'intervention.
final myMissionsProvider = FutureProvider<List<Mission>>((ref) async {
  final utilisateur = ref.watch(currentUserProvider);
  if (utilisateur == null) return [];
  final repo = ref.watch(missionRepositoryProvider);
  final missions = await repo.getByAgent(utilisateur.id);
  missions.sort((a, b) => a.dateHeure.compareTo(b.dateHeure));
  return missions;
});

/// Détail d'une mission unique.
final missionDetailProvider = FutureProvider.family<Mission?, String>((ref, id) async {
  final repo = ref.watch(missionRepositoryProvider);
  return repo.getById(id);
});

/// Pilote les actions de terrain de l'agent sur une mission.
class AgentMissionNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> demarrer(Mission mission) async {
    state = const AsyncLoading();
    try {
      await _saveMission(mission.copyWith(statut: MissionStatus.enRoute));
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> signalerArrivee(Mission mission) async {
    state = const AsyncLoading();
    try {
      await _saveMission(mission.copyWith(statut: MissionStatus.surSite));
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  /// Valide une collecte réussie : met à jour le statut de la mission
  /// ET celui du produit/demande vendeur associé.
  Future<void> validerCollecte(Mission mission) async {
    state = const AsyncLoading();
    try {
      await _saveMission(mission.copyWith(statut: MissionStatus.complete));

      final requestRepo = ref.read(sellerRequestRepositoryProvider);
      final demande = await requestRepo.getById(mission.referenceId);
      if (demande != null) {
        await requestRepo.save(
          demande.copyWith(statut: SellerRequestStatus.terminee),
        );
      }

      final productRepo = ref.read(productRepositoryProvider);
      final produits = await productRepo.getByAgent(mission.agentId);
      for (final p in produits) {
        if (p.statut == ProductStatus.enVerification) {
          await productRepo.updateStatut(p.id, ProductStatus.enTraitement);
        }
      }

      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  /// Signale un refus : le vendeur n'a pas pu prouver sa propriété.
  Future<void> signalerRefus(Mission mission, String raison) async {
    state = const AsyncLoading();
    try {
      await _saveMission(
        mission.copyWith(statut: MissionStatus.echec, raisonRefus: raison),
      );

      final requestRepo = ref.read(sellerRequestRepositoryProvider);
      final demande = await requestRepo.getById(mission.referenceId);
      if (demande != null) {
        await requestRepo.save(
          demande.copyWith(
            statut: SellerRequestStatus.refusee,
            raisonRefus: raison,
          ),
        );
      }
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> _saveMission(Mission mission) async {
    final repo = ref.read(missionRepositoryProvider);
    await repo.save(mission);
    ref.invalidate(myMissionsProvider);
    ref.invalidate(missionDetailProvider(mission.id));
  }
}

final agentMissionNotifierProvider =
    NotifierProvider<AgentMissionNotifier, AsyncValue<void>>(
  AgentMissionNotifier.new,
);
EOF
echo "→ lib/features/agent/providers/agent_provider.dart créé."

# ============================================================================
# 3. ÉCRANS — Vendeur
# ============================================================================
cat > lib/features/sell/presentation/screens/sell_home_screen.dart << 'EOF'
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
EOF
echo "→ lib/features/sell/presentation/screens/sell_home_screen.dart créé."

cat > lib/features/sell/presentation/screens/sell_step1_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/layout/progress_steps.dart';
import '../../../shop/providers/category_provider.dart';
import '../../providers/sell_provider.dart';

class SellStep1Screen extends ConsumerWidget {
  const SellStep1Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(sellProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Vendre un produit'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(AppRoutes.sellHome),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProgressSteps(steps: const ['Description', 'Logistique', 'Récapitulatif'], currentIndex: 0),
            const SizedBox(height: AppSpacing.xxl),
            Text('Description du produit', style: AppTypography.headline),
            const SizedBox(height: AppSpacing.xs),
            Text('Dites-nous ce que vous souhaitez vendre.', style: AppTypography.bodyMedium),
            const SizedBox(height: AppSpacing.xl),
            AppTextField(
              label: 'Nom du produit',
              hint: 'Ex : iPhone 12, Chaise scandinave...',
              initialValue: form.typeProduit,
              onChanged: ref.read(sellProvider.notifier).setTypeProduit,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Catégorie', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            categoriesAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Impossible de charger les catégories.'),
              data: (cats) => Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: cats.map((cat) {
                  final sel = form.categorieId == cat.id;
                  return ChoiceChip(
                    label: Text(cat.nom),
                    selected: sel,
                    onSelected: (_) => ref.read(sellProvider.notifier).setCategorieId(cat.id),
                    selectedColor: AppColors.violetSurface,
                    labelStyle: AppTypography.bodyMedium.copyWith(
                      color: sel ? AppColors.violet : AppColors.gray700,
                      fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Prix souhaité (FCFA)',
              hint: 'Ex : 50000',
              keyboardType: TextInputType.number,
              initialValue: form.prixSouhaite > 0 ? form.prixSouhaite.toInt().toString() : '',
              onChanged: ref.read(sellProvider.notifier).setPrix,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Description',
              hint: 'État, accessoires inclus, défauts éventuels...',
              maxLines: 4,
              initialValue: form.description,
              onChanged: ref.read(sellProvider.notifier).setDescription,
            ),
            if (form.erreur != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(form.erreur!, style: AppTypography.bodyMedium.copyWith(color: AppColors.danger)),
            ],
            const SizedBox(height: AppSpacing.huge),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AppPrimaryButton(
            label: 'Continuer',
            onPressed: () {
              if (ref.read(sellProvider.notifier).validerEtape1()) {
                context.go(AppRoutes.sellStep2);
              }
            },
          ),
        ),
      ),
    );
  }
}
EOF
echo "→ lib/features/sell/presentation/screens/sell_step1_screen.dart créé."

cat > lib/features/sell/presentation/screens/sell_step2_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/layout/progress_steps.dart';
import '../../providers/sell_provider.dart';

class SellStep2Screen extends ConsumerWidget {
  const SellStep2Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(sellProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Vendre un produit'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(AppRoutes.sellStep1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProgressSteps(steps: const ['Description', 'Logistique', 'Récapitulatif'], currentIndex: 1),
            const SizedBox(height: AppSpacing.xxl),
            Text('Collecte à domicile', style: AppTypography.headline),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Un agent se déplacera chez vous pour vérifier et récupérer votre produit.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppTextField(
              label: 'Adresse de collecte',
              hint: 'Quartier, rue, point de repère...',
              initialValue: form.adresse,
              onChanged: ref.read(sellProvider.notifier).setAdresse,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Zone (ville / arrondissement)',
              hint: 'Ex : Douala, Akwa',
              initialValue: form.zone,
              onChanged: ref.read(sellProvider.notifier).setZone,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Disponibilité',
              hint: 'Ex : Lundi-Vendredi après 17h, ou week-end toute la journée',
              maxLines: 2,
              initialValue: form.disponibilite,
              onChanged: ref.read(sellProvider.notifier).setDisponibilite,
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.violetSurface,
                borderRadius: AppRadius.lgRadius,
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: AppColors.violet, size: 22),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'L\'agent se présentera avec son badge AfriDeal. '
                      'Votre identité et la propriété du produit seront vérifiées.',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.violetDark),
                    ),
                  ),
                ],
              ),
            ),
            if (form.erreur != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(form.erreur!, style: AppTypography.bodyMedium.copyWith(color: AppColors.danger)),
            ],
            const SizedBox(height: AppSpacing.huge),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AppPrimaryButton(
            label: 'Continuer',
            onPressed: () {
              if (ref.read(sellProvider.notifier).validerEtape2()) {
                context.go(AppRoutes.sellStep3);
              }
            },
          ),
        ),
      ),
    );
  }
}
EOF
echo "→ lib/features/sell/presentation/screens/sell_step2_screen.dart créé."

cat > lib/features/sell/presentation/screens/sell_step3_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/cards/info_row.dart';
import '../../../../shared/widgets/layout/progress_steps.dart';
import '../../providers/sell_provider.dart';

class SellStep3Screen extends ConsumerWidget {
  const SellStep3Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(sellProvider);

    if (form.estEnvoye) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.go(AppRoutes.sellConfirmation),
      );
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Vendre un produit'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(AppRoutes.sellStep2),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProgressSteps(steps: const ['Description', 'Logistique', 'Récapitulatif'], currentIndex: 2),
            const SizedBox(height: AppSpacing.xxl),
            Text('Récapitulatif', style: AppTypography.headline),
            const SizedBox(height: AppSpacing.xs),
            Text('Vérifiez les informations avant d\'envoyer.', style: AppTypography.bodyMedium),
            const SizedBox(height: AppSpacing.xl),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.lgRadius,
                border: Border.all(color: AppColors.gray200),
              ),
              child: Column(
                children: [
                  InfoRow(icon: Icons.inventory_2_outlined, label: 'Produit', value: form.typeProduit),
                  const Divider(height: AppSpacing.xl),
                  InfoRow(
                    icon: Icons.payments_outlined,
                    label: 'Prix souhaité',
                    value: Formatters.currency(form.prixSouhaite),
                  ),
                  const Divider(height: AppSpacing.xl),
                  InfoRow(icon: Icons.location_on_outlined, label: 'Adresse', value: form.adresse),
                  const Divider(height: AppSpacing.xl),
                  InfoRow(icon: Icons.schedule_outlined, label: 'Disponibilité', value: form.disponibilite),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.goldSurface,
                borderRadius: AppRadius.lgRadius,
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.gold, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Une commission de 8 à 25 % sera déduite du prix de vente final selon la catégorie.',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.goldDark),
                    ),
                  ),
                ],
              ),
            ),
            if (form.erreur != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(form.erreur!, style: AppTypography.bodyMedium.copyWith(color: AppColors.danger)),
            ],
            const SizedBox(height: AppSpacing.huge),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AppPrimaryButton(
            label: 'Envoyer ma demande',
            icon: Icons.send_rounded,
            isLoading: form.estEnvoi,
            onPressed: form.estEnvoi ? null : () => ref.read(sellProvider.notifier).soumettre(),
          ),
        ),
      ),
    );
  }
}
EOF
echo "→ lib/features/sell/presentation/screens/sell_step3_screen.dart créé."

cat > lib/features/sell/presentation/screens/sell_confirmation_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/buttons/app_secondary_button.dart';
import '../../../../shared/widgets/illustrations/onboarding_illustrations.dart';
import '../../providers/sell_provider.dart';

class SellConfirmationScreen extends ConsumerWidget {
  const SellConfirmationScreen({super.key});

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
              const SuccessIllustration(size: 130),
              const SizedBox(height: AppSpacing.xl),
              Text('Demande envoyée !', style: AppTypography.displayMedium, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Nous avons bien reçu votre demande. Un administrateur va l\'examiner '
                'et un agent terrain sera bientôt en contact avec vous pour convenir '
                'd\'un rendez-vous de collecte.',
                style: AppTypography.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxxl),
              _EtapeItem(
                icon: Icons.manage_search_rounded,
                color: AppColors.gold,
                titre: 'Validation',
                description: 'Un admin examine votre demande sous 24h.',
              ),
              const SizedBox(height: AppSpacing.md),
              _EtapeItem(
                icon: Icons.person_pin_circle_outlined,
                color: AppColors.blue,
                titre: 'Collecte',
                description: 'Un agent vous rend visite pour vérifier votre produit.',
              ),
              const SizedBox(height: AppSpacing.md),
              _EtapeItem(
                icon: Icons.storefront_outlined,
                color: AppColors.success,
                titre: 'Mise en vente',
                description: 'Votre produit est publié et visible dans la boutique.',
              ),
              const SizedBox(height: AppSpacing.xxxl),
              AppPrimaryButton(
                label: 'Voir mes demandes',
                onPressed: () {
                  ref.read(sellProvider.notifier).reset();
                  context.go(AppRoutes.sellHome);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              AppSecondaryButton(
                label: 'Soumettre un autre produit',
                onPressed: () {
                  ref.read(sellProvider.notifier).reset();
                  context.go(AppRoutes.sellStep1);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EtapeItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String titre;
  final String description;

  const _EtapeItem({
    required this.icon,
    required this.color,
    required this.titre,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titre, style: AppTypography.titleMedium),
              Text(description, style: AppTypography.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
EOF
echo "→ lib/features/sell/presentation/screens/sell_confirmation_screen.dart créé."

# ============================================================================
# 4. ÉCRANS — Agent terrain
# ============================================================================
cat > lib/features/agent/presentation/screens/agent_dashboard_screen.dart << 'EOF'
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
EOF
echo "→ lib/features/agent/presentation/screens/agent_dashboard_screen.dart créé."

cat > lib/features/agent/presentation/screens/agent_mission_detail_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/errors/error_view.dart';
import '../../../../domain/enums/mission_status.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/buttons/app_secondary_button.dart';
import '../../../../shared/widgets/cards/info_row.dart';
import '../../../../shared/widgets/cards/status_badge.dart';
import '../../../../shared/widgets/feedback/app_loading_indicator.dart';
import '../../../../shared/widgets/feedback/app_snackbar.dart';
import '../../providers/agent_provider.dart';

class AgentMissionDetailScreen extends ConsumerWidget {
  final String missionId;
  const AgentMissionDetailScreen({super.key, required this.missionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missionAsync = ref.watch(missionDetailProvider(missionId));
    final notifierState = ref.watch(agentMissionNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Détail de la mission')),
      body: missionAsync.when(
        loading: () => const AppLoadingIndicator(),
        error: (_, __) => const ErrorView(message: 'Mission introuvable.'),
        data: (mission) {
          if (mission == null) return const ErrorView(message: 'Mission introuvable.');
          final estComplete = mission.statut == MissionStatus.complete;
          final estEchec = mission.statut == MissionStatus.echec;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(mission.type.label, style: AppTypography.displayMedium),
                    StatusBadge(label: mission.statut.label, color: mission.statut.color),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
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
                        icon: Icons.schedule_outlined,
                        label: 'Date et heure prévues',
                        value: Formatters.dateWithTime(mission.dateHeure),
                      ),
                      if (mission.latitude != null) ...[
                        const Divider(height: AppSpacing.xl),
                        InfoRow(
                          icon: Icons.location_on_outlined,
                          label: 'Localisation GPS',
                          value: '${mission.latitude!.toStringAsFixed(4)}, '
                              '${mission.longitude!.toStringAsFixed(4)}',
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (!estComplete && !estEchec) ...[
                  if (mission.statut == MissionStatus.assignee)
                    AppPrimaryButton(
                      label: 'Démarrer la mission',
                      icon: Icons.directions_car_outlined,
                      isLoading: notifierState.isLoading,
                      onPressed: () async {
                        await ref.read(agentMissionNotifierProvider.notifier).demarrer(mission);
                        if (context.mounted) AppSnackbar.showSuccess(context, 'Mission démarrée.');
                      },
                    ),
                  if (mission.statut == MissionStatus.enRoute)
                    AppPrimaryButton(
                      label: 'Signaler mon arrivée',
                      icon: Icons.where_to_vote_outlined,
                      isLoading: notifierState.isLoading,
                      onPressed: () async {
                        await ref.read(agentMissionNotifierProvider.notifier).signalerArrivee(mission);
                        if (context.mounted) AppSnackbar.showSuccess(context, 'Arrivée signalée.');
                      },
                    ),
                  if (mission.statut == MissionStatus.surSite) ...[
                    AppPrimaryButton(
                      label: 'Valider la collecte',
                      icon: Icons.check_circle_outline_rounded,
                      isLoading: notifierState.isLoading,
                      onPressed: () async {
                        await ref.read(agentMissionNotifierProvider.notifier).validerCollecte(mission);
                        if (context.mounted) AppSnackbar.showSuccess(context, 'Collecte validée !');
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppSecondaryButton(
                      label: 'Signaler un refus',
                      icon: Icons.cancel_outlined,
                      onPressed: () => _showRefusDialog(context, ref, mission),
                    ),
                  ],
                ],
                if (estComplete)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.successSurface,
                      borderRadius: AppRadius.lgRadius,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppColors.success),
                        const SizedBox(width: AppSpacing.sm),
                        Text('Mission complétée avec succès.',
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.success)),
                      ],
                    ),
                  ),
                if (estEchec && mission.raisonRefus != null)
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
                            Text('Mission échouée', style: AppTypography.titleMedium.copyWith(color: AppColors.danger)),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(mission.raisonRefus!, style: AppTypography.bodySmall),
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

  void _showRefusDialog(BuildContext context, WidgetRef ref, mission) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Raison du refus'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Décrivez pourquoi la collecte échoue...'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(agentMissionNotifierProvider.notifier).signalerRefus(mission, controller.text);
              if (context.mounted) AppSnackbar.showInfo(context, 'Refus signalé.');
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }
}
EOF
echo "→ lib/features/agent/presentation/screens/agent_mission_detail_screen.dart créé."

# ============================================================================
# 5. MISE À JOUR DU ROUTEUR — branchement des écrans Vendeur et Agent
# ============================================================================
echo "→ Mise à jour de app_router.dart pour brancher Vendeur et Agent..."

python3 << 'PYEOF'
path = "lib/core/router/app_router.dart"
with open(path, encoding="utf-8") as f:
    content = f.read()

new_imports = (
    "import '../../features/sell/presentation/screens/sell_home_screen.dart';\n"
    "import '../../features/sell/presentation/screens/sell_step1_screen.dart';\n"
    "import '../../features/sell/presentation/screens/sell_step2_screen.dart';\n"
    "import '../../features/sell/presentation/screens/sell_step3_screen.dart';\n"
    "import '../../features/sell/presentation/screens/sell_confirmation_screen.dart';\n"
    "import '../../features/agent/presentation/screens/agent_dashboard_screen.dart';\n"
    "import '../../features/agent/presentation/screens/agent_mission_detail_screen.dart';\n"
)
marker = "import '../../features/orders/presentation/screens/orders_screen.dart';\n"
if marker not in content:
    raise SystemExit("ERREUR : marqueur d'import introuvable dans app_router.dart")
content = content.replace(marker, marker + new_imports, 1)

replacements = [
    (
        "GoRoute(\n        path: AppRoutes.sellHome,\n        builder: (context, state) => const PlaceholderScreen(titre: 'Espace vendeur'),\n      ),",
        "GoRoute(\n        path: AppRoutes.sellHome,\n        builder: (context, state) => const SellHomeScreen(),\n      ),",
    ),
    (
        "GoRoute(\n        path: AppRoutes.sellStep1,\n        builder: (context, state) => const PlaceholderScreen(titre: 'Vendre — étape 1'),\n      ),",
        "GoRoute(\n        path: AppRoutes.sellStep1,\n        builder: (context, state) => const SellStep1Screen(),\n      ),",
    ),
    (
        "GoRoute(\n        path: AppRoutes.sellStep2,\n        builder: (context, state) => const PlaceholderScreen(titre: 'Vendre — étape 2'),\n      ),",
        "GoRoute(\n        path: AppRoutes.sellStep2,\n        builder: (context, state) => const SellStep2Screen(),\n      ),",
    ),
    (
        "GoRoute(\n        path: AppRoutes.sellStep3,\n        builder: (context, state) => const PlaceholderScreen(titre: 'Vendre — étape 3'),\n      ),",
        "GoRoute(\n        path: AppRoutes.sellStep3,\n        builder: (context, state) => const SellStep3Screen(),\n      ),",
    ),
    (
        "GoRoute(\n        path: AppRoutes.sellConfirmation,\n        builder: (context, state) => const PlaceholderScreen(titre: 'Demande envoyée'),\n      ),",
        "GoRoute(\n        path: AppRoutes.sellConfirmation,\n        builder: (context, state) => const SellConfirmationScreen(),\n      ),",
    ),
    (
        "GoRoute(\n        path: AppRoutes.agentDashboard,\n        builder: (context, state) => const PlaceholderScreen(titre: 'Mes missions'),\n      ),",
        "GoRoute(\n        path: AppRoutes.agentDashboard,\n        builder: (context, state) => const AgentDashboardScreen(),\n      ),",
    ),
    (
        "GoRoute(\n        path: AppRoutes.agentMissionDetail,\n        builder: (context, state) => const PlaceholderScreen(titre: 'Détail mission'),\n      ),",
        "GoRoute(\n        path: AppRoutes.agentMissionDetail,\n        builder: (context, state) {\n          final missionId = state.pathParameters['missionId']!;\n          return AgentMissionDetailScreen(missionId: missionId);\n        },\n      ),",
    ),
]

for old, new in replacements:
    if old not in content:
        raise SystemExit(f"ERREUR : bloc de route introuvable :\n{old[:80]}...")
    content = content.replace(old, new, 1)

with open(path, "w", encoding="utf-8") as f:
    f.write(content)

print("app_router.dart mis à jour avec succès (7 routes branchées).")
PYEOF

echo ""
echo "============================================================"
echo "  ✔ Script 12 terminé avec succès."
echo "============================================================"
echo ""
echo "RÉCAPITULATIF DE CE QUI A ÉTÉ CRÉÉ :"
echo "  • SellProvider : formulaire en 3 étapes, validation par étape,"
echo "    soumission de DemandeVendeur en base locale."
echo "  • AgentProvider : gestion des statuts de mission (démarrer,"
echo "    arriver, valider, refuser) avec effets de bord sur les"
echo "    entités liées (DemandeVendeur, Produit)."
echo "  • SellHomeScreen, SellStep1-3, SellConfirmationScreen"
echo "  • AgentDashboardScreen, AgentMissionDetailScreen"
echo "  • 7 routes branchées dans app_router.dart"
echo ""
echo "PROCHAINE ÉTAPE :"
echo "  Dites-moi quand vous êtes prêt pour le script 13 : Messages,"
echo "  Notifications, écran Profil, et l'interface Admin web."
echo ""
