# Audit du projet TrustNova (Flutter)

Date de l'audit initial : 2026-07-07 — mis à jour le 2026-07-09 après une série de correctifs
(rebranding AfriDeal → TrustNova, panier, connexion, nettoyage).

---

## 1. Résumé exécutif

**TrustNova** est une application Flutter (marketplace de seconde main au Cameroun) en architecture
propre (`domain` / `data` / `features`), actuellement en **mode 100% local** (Hive), sans backend
branché. Depuis l'audit initial :

- le test cassé, l'écran checkout non branché, le panier manquant, l'écran de connexion manquant,
  et le module onboarding mort ont tous été traités ;
- `flutter analyze` est passé de 59 problèmes (1 erreur, 6 avertissements) à **0 erreur, 0
  avertissement** (95 infos cosmétiques `prefer_const_constructors` restantes, sans impact) ;
- le dépôt Git est initialisé et poussé sur GitHub.

Il ne reste plus qu'**une seule route** en `PlaceholderScreen` (`/super-admin/reports`, feature
volontairement hors périmètre — voir §4.1), et deux points cosmétiques/tooling différés
délibérément (voir §4.2).

L'app **se lance et fonctionne** sur Chrome (Windows desktop et Android ne sont pas disponibles,
voir §2).

---

## 2. Environnement & lancement

| Élément | État |
|---|---|
| Flutter | 3.35.4 (stable) — OK |
| `flutter pub get` | ✅ Réussi |
| `flutter analyze` | ✅ 0 erreur, 0 avertissement (95 infos cosmétiques) |
| `flutter test` | ✅ Tous les tests passent |
| `flutter build web` | ✅ Réussi |
| Chrome (web) | ✅ Disponible et fonctionnel |
| Edge (web) | ✅ Disponible |
| Windows (desktop) | ❌ Visual Studio (workload "Desktop development with C++") **non installé** — build natif Windows impossible |
| Android | ❌ `cmdline-tools` manquant dans le SDK Android — build/émulation Android impossible tant que non installé |
| Dépôt Git | ✅ Initialisé, poussé sur GitHub (`origin/main`) |

**Recommandation si tu veux tester sur Windows natif** : installer Visual Studio avec le workload
"Desktop development with C++".
**Recommandation si tu veux tester sur Android** : installer les Android SDK Command-line Tools
depuis Android Studio (SDK Manager) ou définir `ANDROID_HOME`.

---

## 3. Ce qui existe (points forts)

- Architecture en couches claire : `domain/entities`, `domain/enums`, `domain/repositories`
  (interfaces), `data/models`, `data/repositories/local`, `data/local/datasources` (Hive).
- **13 entités métier** complètes : utilisateur, produit, commande, paiement, demande vendeur,
  mission, litige, notification, conversation, message, catégorie, photo.
- **12 repositories locaux** implémentés (auth, produit, commande, paiement, demande vendeur,
  mission, litige, notification, catégorie, favoris, **panier**, utilisateur), tous basés sur Hive.
- **Gestion d'état** : Riverpod (`flutter_riverpod`) utilisé de façon cohérente via des providers
  par feature.
- **Routing** : `go_router` avec redirection centralisée par rôle (acheteur, vendeur, agent
  terrain, admin, super admin) dans `app_router.dart`.
- **Écrans fonctionnels branchés au routeur** : auth (choix d'entrée, **connexion classique**,
  comptes de démo), boutique (liste + détail produit), **panier**, checkout, vente (accueil + 3
  étapes + confirmation + détail de demande), commandes (liste + détail), favoris, agent terrain
  (dashboard + détail mission), messagerie, notifications, profil, admin (dashboard, catalogue,
  commandes, utilisateurs, litiges, agents), super admin (dashboard, administrateurs, commissions).
- **Design system** partagé (`shared/widgets`) : boutons, champs de saisie, cartes, badges de
  statut, illustrations (widgets Dart), indicateurs de chargement, snackbars.
- **Point de bascule local → API unique et documenté** (`AppConfig.dataMode`), avec les
  repositories "API" déjà **stubés** (lèvent `UnimplementedError` en attendant le backend Spring
  Boot).
- L'app seed automatiquement des données de démonstration au premier lancement
  (`DemoDataSeeder.seedIfNeeded`), y compris un mot de passe commun (`demo1234`) permettant de
  tester la connexion classique avec n'importe quel compte de démo.

---

## 4. Ce qui reste ouvert

### 4.1 Fonctionnalité hors périmètre (décision produit nécessaire)

- **`/super-admin/reports`** reste un `PlaceholderScreen`. Contrairement à l'ex-`/onboarding`
  (supprimé, voir historique Git), cette route n'est pas morte par oubli : elle n'est
  délibérément pas exposée dans `SuperAdminSidebar` (seuls Vue globale / Administrateurs /
  Commissions y figurent). Le tableau de bord Super Admin (`superAdminStatsProvider`) couvre déjà
  les KPI globaux (revenus, utilisateurs, produits en vente, commandes livrées) ; un écran
  "Rapports" distinct suppose une portée à définir (période, export, ventilation par catégorie ou
  par agent...) avant d'être développé.

### 4.2 Différés intentionnellement

- **`applicationId` Android** toujours à sa valeur par défaut `com.example.afrideal`
  (`android/app/build.gradle.kts`), de même que le bundle identifier iOS/macOS et
  `APPLICATION_ID` sous Linux. Renommer ces identifiants implique une restructuration de dossiers
  (package Kotlin notamment) sans bénéfice avant une publication réelle — à faire à ce moment-là.
- **Windows/Android non buildables** faute d'outils installés localement (Visual Studio,
  Android SDK cmdline-tools) — action utilisateur, pas un défaut du code.

### 4.3 Couverture de tests minimale

Un seul test existe (`test/widget_test.dart`, smoke test sur `TrustNovaApp`). Aucun test unitaire
sur les repositories, providers ou la logique métier (calcul de commission, statuts de commande,
etc.). Non bloquant pour l'usage actuel, mais à surveiller si le projet grossit encore.

---

## 5. Historique des correctifs (depuis l'audit initial du 2026-07-07)

1. Rebranding complet AfriDeal → TrustNova sur toutes les surfaces visibles (Android, iOS, macOS,
   Windows, Linux, Web, README).
2. `test/widget_test.dart` corrigé (référençait encore `MyApp`/`AfriDealApp`).
3. `CheckoutScreen` branché sur `/checkout` (déjà fait avant cette série de correctifs).
4. **Panier implémenté** : `ICartRepository`/`LocalCartRepository` (même schéma que les favoris —
   liste d'ids produits par utilisateur, sans quantité car chaque annonce est un article unique de
   seconde main), `cartProvider`, `CartScreen`, route `/cart` branchée, points d'entrée (icône
   panier avec badge sur la boutique, icône d'ajout sur la fiche produit).
5. **Écran de connexion classique implémenté** (`LoginScreen`, téléphone + mot de passe) : la
   couche données (`IAuthRepository.login`, `sessionProvider.login`) existait déjà, seul l'écran
   manquait.
6. Nettoyage `flutter analyze` : imports inutilisés (6 fichiers), `activeColor` déprécié →
   `activeThumbColor`.
7. `/onboarding` retiré (route, constante, dossier `features/onboarding/` vide) — n'était
   référencé nulle part dans l'app.
8. Entrées `assets:` retirées de `pubspec.yaml` — aucune image/icône n'est chargée depuis
   `assets/images|icons|illustrations` dans tout le code (illustrations = widgets Dart), dossiers
   restés vides à dessein.
9. Dépôt Git initialisé et poussé sur GitHub.

---

## 6. Détails techniques (annexe)

- **Mode de données actuel** : `AppConfig.dataMode = DataMode.local` (`lib/core/config/app_config.dart`)
  — tout passe par Hive, aucune requête réseau réelle. Les repositories "API" existent en stub
  (`repository_providers.dart`) et lèveront `UnimplementedError` si sollicités par erreur.
- **Rôles utilisateurs gérés** : acheteur, vendeur, agent terrain, admin, super admin
  (`domain/enums/user_role.dart`), avec redirection et autorisation de routes centralisées dans
  `app_router.dart`.
- **Connexion classique** : `IAuthRepository.login(telephone, motDePasse)` vérifie le hash du mot
  de passe contre les comptes stockés localement ; tous les comptes de démo partagent le mot de
  passe `demo1234` (défini dans `DemoDataSeeder`).
