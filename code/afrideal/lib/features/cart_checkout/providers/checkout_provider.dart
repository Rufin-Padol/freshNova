import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../domain/entities/commande.dart';
import '../../../domain/entities/produit.dart';
import '../../../domain/enums/order_status.dart';
import '../../../domain/enums/payment_status.dart';
import '../../../domain/enums/product_status.dart';
import '../../auth/providers/session_provider.dart';

const _uuid = Uuid();

/// Représente l'avancement de la confirmation de commande, pour
/// piloter l'interface (bouton désactivé pendant l'enregistrement,
/// affichage d'un message de succès ou d'erreur).
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
    this.methode = PaymentMethod.especes,
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

/// Pilote la confirmation de commande : création de la commande,
/// mise à jour du statut du produit (En vente → Réservé).
///
/// Le paiement (espèces ou Mobile Money) n'a jamais lieu ici : il est
/// collecté au moment de la livraison, par la personne qui livre.
/// Aucun [Paiement] n'est donc créé à cette étape — seule la méthode
/// choisie est mémorisée sur la commande (voir AdminOrderNotifier,
/// qui enregistre le paiement lorsque la commande passe à "livrée").
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

  /// Confirme la commande pour l'ensemble des produits passés — un
  /// panier de plusieurs articles donne UNE seule commande, avec un
  /// montant total unique et un paiement unique à la livraison, pas
  /// une commande par article.
  Future<void> confirmerAchat(List<Produit> produits) async {
    if (produits.isEmpty) return;
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
    final paiementMobile = state.methode != PaymentMethod.especes;
    if (paiementMobile && state.numeroPaieur.trim().isEmpty) {
      state = state.copyWith(messageErreur: 'Veuillez renseigner le numéro Mobile Money.');
      return;
    }

    state = state.copyWith(step: CheckoutStep.traitement, messageErreur: null);

    try {
      final orderRepo = ref.read(orderRepositoryProvider);
      final productRepo = ref.read(productRepositoryProvider);

      final commandeId = _uuid.v4();
      final reference = Commande.genererReference(
        DateTime.now().millisecondsSinceEpoch.remainder(10000),
      );
      final montantTotal = produits.fold<double>(0, (somme, p) => somme + p.prix);

      final commande = Commande(
        id: commandeId,
        reference: reference,
        montantTotal: montantTotal,
        statut: OrderStatus.pendante,
        dateCommande: DateTime.now(),
        modeLivraison: state.modeLivraison,
        adresseLivraison: state.adresse,
        methodePaiement: state.methode,
        numeroPaieur: paiementMobile ? state.numeroPaieur : null,
        acheteurId: utilisateur.id,
        produitIds: produits.map((p) => p.id).toList(),
      );
      await orderRepo.save(commande);
      for (final produit in produits) {
        await productRepo.updateStatut(produit.id, ProductStatus.reserve);
      }

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
