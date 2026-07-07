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
