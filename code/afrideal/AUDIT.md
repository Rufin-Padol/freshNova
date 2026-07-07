# Audit du projet AfriDeal (Flutter)

Date de l'audit : 2026-07-07
Généré après lancement réussi de l'application sur Chrome (web).

---

## 1. Résumé exécutif

**AfriDeal** est une application Flutter (marketplace de seconde main au Cameroun) en architecture
propre (`domain` / `data` / `features`), actuellement en **mode 100% local** (Hive), sans backend
branché. Le projet est bien avancé côté structure et écrans, mais contient :
- **1 erreur bloquante** (suite de tests cassée),
- **1 écran développé mais non branché au routeur** (checkout),
- **3 fonctionnalités entières manquantes** (panier, connexion par mot de passe, assets/fonts),
- **2 modules vides** (onboarding, super admin) et plusieurs routes en `PlaceholderScreen`.

L'app **se lance et fonctionne** sur Chrome (Windows desktop et Android ne sont pas disponibles,
voir §2).

---

## 2. Environnement & lancement

| Élément | État |
|---|---|
| Flutter | 3.35.4 (stable) — OK |
| Dart | 3.9.2 — OK |
| Espace disque (C:) | 21 Go libres / 471 Go (96% utilisé) — suffisant mais **serré**, à surveiller |
| Espace disque (E:) | 2,5 Go libres / 6 Go — très limité |
| `flutter pub get` | ✅ Réussi |
| `flutter run -d chrome` | ✅ **Lancé avec succès**, Hive initialise ses 15 box locales sans erreur |
| Chrome (web) | ✅ Disponible et fonctionnel |
| Edge (web) | ✅ Disponible |
| Windows (desktop) | ❌ Visual Studio (workload "Desktop development with C++") **non installé** — build natif Windows impossible |
| Android | ❌ `cmdline-tools` manquant dans le SDK Android — build/émulation Android impossible tant que non installé |
| Dépôt Git | ❌ Le dossier `afrideal` n'est **pas** un dépôt Git initialisé |

**Recommandation immédiate si tu veux tester sur Windows natif** : installer Visual Studio avec le
workload "Desktop development with C++".
**Recommandation immédiate si tu veux tester sur Android** : installer les Android SDK
Command-line Tools depuis Android Studio (SDK Manager) ou définir `ANDROID_HOME`.

---

## 3. Ce qui existe (points forts)

- **136 fichiers Dart**, ~10 470 lignes de code dans `lib/`.
- Architecture en couches claire : `domain/entities`, `domain/enums`, `domain/repositories`
  (interfaces), `data/models`, `data/repositories/local`, `data/local/datasources` (Hive).
- **13 entités métier** complètes : utilisateur, produit, commande, paiement, demande vendeur,
  mission, litige, notification, conversation, message, catégorie, photo.
- **11 repositories locaux** implémentés (auth, produit, commande, paiement, demande vendeur,
  mission, litige, notification, catégorie, favoris, utilisateur), tous basés sur Hive.
- **Gestion d'état** : Riverpod (`flutter_riverpod`) utilisé de façon cohérente via des providers
  par feature.
- **Routing** : `go_router` avec redirection centralisée par rôle (acheteur, vendeur, agent
  terrain, admin, super admin) dans `app_router.dart` — logique propre et bien commentée.
- **Écrans fonctionnels branchés au routeur** :
  - Auth : choix d'entrée, comptes de démo
  - Boutique : liste produits, détail produit
  - Vente : accueil vendeur + 3 étapes + confirmation
  - Commandes : liste + détail
  - Favoris
  - Agent terrain : dashboard + détail mission
  - Messagerie : liste conversations + conversation
  - Notifications
  - Profil
  - Admin : dashboard, catalogue, commandes, utilisateurs
- **Design system** partagé (`shared/widgets`) : boutons, champs de saisie, cartes, badges de
  statut, illustrations SVG, indicateurs de chargement, snackbars — bien organisé par catégorie.
- **Point de bascule local → API unique et documenté** (`AppConfig.dataMode`), avec les
  repositories "API" déjà **stubés** (lèvent `UnimplementedError` en attendant le backend Spring
  Boot).
- L'app seed automatiquement des données de démonstration au premier lancement
  (`DemoDataSeeder.seedIfNeeded`).
- 14 scripts shell (`01_...sh` à `14_...sh`) documentent l'ordre de génération du projet — utile
  comme historique/roadmap de construction.

---

## 4. Ce qui manque ou est incomplet

### 4.1 Bloquant

- **`test/widget_test.dart` ne compile pas.** Il référence encore le test par défaut de
  `flutter create` (`MyApp`, compteur "+1"), alors que la classe racine réelle s'appelle
  `AfriDealApp` (`lib/main.dart:35`). Résultat : `flutter analyze` remonte une erreur et
  `flutter test` échouerait totalement. **Il n'existe donc aucun test automatisé fonctionnel dans
  tout le projet.**

### 4.2 Écran développé mais non branché

- **`checkout_screen.dart`** (feature `cart_checkout`) est entièrement écrit (~260 lignes,
  `checkout_provider.dart` associé) mais la route `/checkout` dans `app_router.dart:135-137`
  pointe toujours vers un `PlaceholderScreen`. À corriger : remplacer le `PlaceholderScreen` par
  `CheckoutScreen()`.

### 4.3 Fonctionnalités manquantes

- **Panier (cart)** : aucune classe `Cart`/`CartItem` n'existe dans tout le projet. La route
  `/cart` est un simple `PlaceholderScreen` sans provider ni entité derrière. Le flux
  acheteur → produit → **panier** → checkout n'est donc pas implémentable en l'état : il manque
  l'entité panier, son repository/provider, et l'écran.
- **Connexion classique (login/mot de passe)** : aucun fichier `*login*` dans `lib/`. Seuls
  existent l'écran de choix d'entrée (`entry_choice_screen.dart`) et les comptes de démonstration
  (`demo_accounts_screen.dart`). La route `/login` reste un `PlaceholderScreen`. Il n'y a donc pas
  de vrai formulaire d'authentification (email/mot de passe ou téléphone) — uniquement le mode
  démo.
- **Assets vides** : `assets/images/`, `assets/icons/`, `assets/illustrations/`, `assets/fonts/`
  ne contiennent chacun qu'un `.gitkeep`. Aucune image, icône, illustration ou police n'est
  présente, alors que le code référence des illustrations SVG
  (`shared/widgets/illustrations/*`) et que `pubspec.yaml` déclare ces dossiers comme assets. Le
  commentaire du `pubspec.yaml` indique explicitement : *"Les polices seront ajoutées par le
  script de thème (02) une fois les fichiers de police placés dans assets/fonts/"* — jamais fait.

### 4.4 Modules vides (dossiers créés, aucun contenu)

- **`features/onboarding/`** : dossiers `screens/` et `widgets/` présents mais vides
  (`.gitkeep` seulement). La route `/onboarding` est un `PlaceholderScreen`.
- **`features/super_admin/`** : dossiers `screens/`, `widgets/`, `providers/` vides. Les 4 routes
  super admin (dashboard, admins, commissions, rapports) sont toutes des `PlaceholderScreen`.

### 4.5 Routes encore en `PlaceholderScreen`

En plus de celles déjà citées (`onboarding`, `login`, `cart`, `checkout`, super admin) :
- `sellRequestDetail` ("Détail de la demande")
- `adminDisputes` ("Litiges")
- `adminAgents` ("Agents terrain")

Soit **11 routes sur ~30** encore non implémentées (placeholders).

### 4.6 Qualité de code (`flutter analyze` → 59 problèmes)

- **1 erreur** : test cassé (voir 4.1).
- **6 avertissements** : imports inutilisés (fichiers concernés : `demo_data_seeder.dart`,
  `produit_model.dart`, `checkout_provider.dart`, `notifications_screen.dart`,
  `app_icon_button.dart`, `app_bottom_nav.dart`).
- **1 avertissement de dépréciation** : `activeColor` déprécié dans
  `admin_users_screen.dart:64` (remplacer par `activeThumbColor`).
- **~50 infos mineures** : essentiellement des suggestions `prefer_const_constructors` /
  `use_super_parameters` — cosmétique, sans impact fonctionnel.

### 4.7 Autres points notés

- `applicationId` Android encore à sa valeur par défaut `com.example.afrideal`
  (`android/app/build.gradle`) — à renommer avant toute publication.
- Aucun dépôt Git initialisé pour le projet — aucun historique de versions, aucune sauvegarde.
- Le dossier `build/` (57 Mo d'artefacts de compilation) est présent à la racine du projet ; à
  exclure d'un futur dépôt Git via `.gitignore` (déjà généré par défaut par Flutter).
- Espace disque C: à 96% d'utilisation (21 Go restants) — pas bloquant aujourd'hui mais à
  surveiller, notamment si des SDK supplémentaires (Visual Studio, Android cmdline-tools) sont
  installés pour débloquer les autres plateformes.

---

## 5. Plan d'action suggéré (par priorité)

1. **Corriger `test/widget_test.dart`** — remplacer le test compteur par un vrai smoke test sur
   `AfriDealApp`.
2. **Brancher `CheckoutScreen`** sur la route `/checkout` (le code existe déjà).
3. **Implémenter le panier** : entité `CartItem`, provider Riverpod, écran, avant de pouvoir
   utiliser le checkout de façon réaliste.
4. **Ajouter un vrai écran de connexion** (`/login`) si le mode démo seul ne suffit pas au besoin
   final.
5. **Peupler les assets** (`assets/images`, `assets/icons`, `assets/illustrations`,
   `assets/fonts`) ou retirer les entrées correspondantes du `pubspec.yaml` si non utilisées pour
   l'instant.
6. **Nettoyer les imports inutilisés** et le `activeColor` déprécié (rapide, low-effort).
7. **Décider du sort de `onboarding/` et `super_admin/`** : les développer ou les retirer du
   routeur si non prioritaires.
8. **Initialiser un dépôt Git** pour sécuriser l'historique du projet.

---

## 6. Détails techniques (annexe)

- **Mode de données actuel** : `AppConfig.dataMode = DataMode.local` (`lib/core/config/app_config.dart:27`)
  — tout passe par Hive, aucune requête réseau réelle. Les repositories "API" existent en stub
  (`repository_providers.dart`) et lèveront `UnimplementedError` si sollicités par erreur.
- **Rôles utilisateurs gérés** : acheteur, vendeur, agent terrain, admin, super admin
  (`domain/enums/user_role.dart`), avec redirection et autorisation de routes centralisées dans
  `app_router.dart`.
- **Devices testés au lancement** : Windows (desktop, non buildable faute de Visual Studio),
  Chrome (web, ✅ fonctionnel), Edge (web, disponible).
