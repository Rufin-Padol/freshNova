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
