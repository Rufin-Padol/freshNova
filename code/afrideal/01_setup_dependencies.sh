#!/bin/bash
# ============================================================================
# SCRIPT 01 — Configuration des dépendances et structure de dossiers
# Projet : AfriDeal — Plateforme de revente de seconde main (Cameroun)
# ============================================================================
#
# CE QUE FAIT CE SCRIPT :
#   1. Sauvegarde votre pubspec.yaml actuel (au cas où) dans pubspec.yaml.backup
#   2. Remplace pubspec.yaml par une version complète avec toutes les
#      dépendances nécessaires au projet, figées à des versions stables
#      connues pour être compatibles entre elles.
#   3. Crée TOUTE l'arborescence de dossiers vide du projet (lib/...) pour
#      que les scripts suivants puissent y déposer leurs fichiers sans
#      jamais se soucier de créer un dossier manquant.
#
# CHOIX TECHNIQUES IMPORTANTS (pourquoi ces dépendances précises) :
#   - flutter_riverpod : gestion d'état. On utilise la syntaxe CLASSIQUE
#     (sans génération de code / build_runner) pour éviter tout risque de
#     plantage de compilation lié à la génération automatique de fichiers.
#   - hive_ce + hive_ce_flutter : base de données locale. ATTENTION, on
#     n'utilise PAS le package "hive" original (il est officiellement
#     abandonné par son auteur). On utilise "hive_ce" qui est le fork
#     activement maintenu en 2026, compatible Android/iOS/Web.
#     IMPORTANT : on n'utilise PAS la génération de code (build_runner)
#     pour les adaptateurs Hive, afin d'éliminer tout risque de
#     plantage de compilation lié à la génération automatique. Chaque
#     entité est sérialisée en JSON (String) et stockée dans des box
#     Hive de type Box<String> — aussi rapide, mais à zéro risque.
#   - dio : client HTTP pour la future connexion à l'API Spring Boot.
#     Il est installé et configuré mais resté INACTIF tant que le mode
#     local est utilisé (voir app_config.dart dans le script 02).
#   - go_router : navigation déclarative, fonctionne aussi bien pour
#     les routes mobile que pour les URLs propres de l'interface web admin.
#   - flutter_svg : affichage des illustrations vectorielles (zéro emoji).
#   - image_picker : sélection de vraies photos (galerie/caméra), supporté
#     nativement sur Android, iOS ET Web (le plugin web est inclus
#     automatiquement, pas besoin de l'ajouter séparément).
#   - flutter_secure_storage : stockage sécurisé du token de session
#     (préparé pour le jour où l'API sera branchée).
#   - connectivity_plus : détection de la connexion réseau, utile pour
#     afficher un état "hors-ligne" propre plutôt qu'un écran qui plante.
#
# COMMENT EXÉCUTER CE SCRIPT :
#   1. Ouvrez un terminal à la racine de votre projet (le dossier qui
#      contient déjà pubspec.yaml, lib/, android/, ios/, etc.)
#   2. Copiez ce fichier dans ce dossier sous le nom 01_setup_dependencies.sh
#   3. Lancez : bash 01_setup_dependencies.sh
#   4. Puis lancez : flutter pub get
#
# CE QUE VOUS DEVEZ VOIR SI TOUT FONCTIONNE :
#   - Le message final "✔ Script 01 terminé avec succès."
#   - Après "flutter pub get", aucune erreur rouge dans le terminal.
# ============================================================================

set -e  # Arrête le script immédiatement si une commande échoue

echo "============================================================"
echo "  AfriDeal — Script 01/14 : Dépendances et structure"
echo "============================================================"

# --- Vérification qu'on est bien à la racine d'un projet Flutter ---
if [ ! -f "pubspec.yaml" ]; then
  echo "ERREUR : pubspec.yaml introuvable."
  echo "Veuillez exécuter ce script depuis la racine de votre projet Flutter"
  echo "(le dossier qui contient déjà pubspec.yaml, lib/, android/, ios/)."
  exit 1
fi

# --- Sauvegarde de sécurité du pubspec.yaml existant ---
cp pubspec.yaml pubspec.yaml.backup
echo "→ Sauvegarde créée : pubspec.yaml.backup"

# --- Récupération du nom du projet existant (pour ne pas le casser) ---
PROJECT_NAME=$(grep -m1 '^name:' pubspec.yaml | sed 's/name:[[:space:]]*//')
if [ -z "$PROJECT_NAME" ]; then
  PROJECT_NAME="afrideal"
fi
echo "→ Nom du projet détecté : $PROJECT_NAME"

# ----------------------------------------------------------------------
# 1. Écriture du nouveau pubspec.yaml
# ----------------------------------------------------------------------
cat > pubspec.yaml << PUBSPEC_EOF
name: ${PROJECT_NAME}
description: "AfriDeal — Plateforme de revente de produits de seconde main au Cameroun."
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.5.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # ── Icônes Material (utilisées avec parcimonie, pas d'emoji) ──
  cupertino_icons: ^1.0.8

  # ── Gestion d'état ──
  flutter_riverpod: ^2.5.1

  # ── Navigation (mobile + web, URLs propres pour l'admin) ──
  go_router: ^14.6.2

  # ── Stockage local persistant (fork maintenu de Hive) ──
  hive_ce: ^2.10.1
  hive_ce_flutter: ^2.2.0
  path_provider: ^2.1.4

  # ── Client HTTP (prêt pour l'API Spring Boot, inactif pour l'instant) ──
  dio: ^5.7.0

  # ── Stockage sécurisé (token de session, pour plus tard) ──
  flutter_secure_storage: ^9.2.2

  # ── Détection de connectivité réseau ──
  connectivity_plus: ^6.1.0

  # ── Sélection de photos (galerie + caméra), supporte Web nativement ──
  image_picker: ^1.1.2

  # ── Illustrations vectorielles SVG ──
  flutter_svg: ^2.0.16

  # ── Formatage des dates et montants (FCFA) ──
  intl: ^0.19.0

  # ── Identifiants uniques (pour les entités créées en local) ──
  uuid: ^4.5.1

  # ── Hash de mot de passe (package officiel dart-lang, zéro risque) ──
  crypto: ^3.0.6

  # ── Égalité de valeur pour nos modèles (sans génération de code) ──
  equatable: ^2.0.5

  # ── Cache d'images réseau (utile dès qu'on passera à l'API) ──
  cached_network_image: ^3.4.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0

flutter:
  uses-material-design: true

  assets:
    - assets/images/
    - assets/icons/
    - assets/illustrations/

  # Les polices seront ajoutées par le script de thème (02) une fois
  # les fichiers de police placés dans assets/fonts/.
PUBSPEC_EOF

echo "→ pubspec.yaml réécrit avec succès."

# ----------------------------------------------------------------------
# 2. Création de l'arborescence complète de dossiers (vide pour l'instant)
# ----------------------------------------------------------------------
echo "→ Création de l'arborescence de dossiers..."

# --- lib/core : fondations transverses de l'application ---
mkdir -p lib/core/config
mkdir -p lib/core/theme
mkdir -p lib/core/router
mkdir -p lib/core/errors
mkdir -p lib/core/constants
mkdir -p lib/core/utils
mkdir -p lib/core/network

# --- lib/domain : entités métier pures, indépendantes de toute techno ---
mkdir -p lib/domain/entities
mkdir -p lib/domain/enums
mkdir -p lib/domain/repositories

# --- lib/data : implémentation concrète (local Hive + futur API) ---
mkdir -p lib/data/models
mkdir -p lib/data/local/datasources
mkdir -p lib/data/local/seed
mkdir -p lib/data/remote/datasources
mkdir -p lib/data/repositories

# --- lib/shared : composants UI réutilisables dans toute l'app ---
mkdir -p lib/shared/widgets/buttons
mkdir -p lib/shared/widgets/inputs
mkdir -p lib/shared/widgets/cards
mkdir -p lib/shared/widgets/feedback
mkdir -p lib/shared/widgets/illustrations
mkdir -p lib/shared/widgets/layout

# --- lib/features : un dossier par fonctionnalité métier ---
mkdir -p lib/features/auth/presentation/screens
mkdir -p lib/features/auth/presentation/widgets
mkdir -p lib/features/auth/providers

mkdir -p lib/features/onboarding/presentation/screens
mkdir -p lib/features/onboarding/presentation/widgets

mkdir -p lib/features/shop/presentation/screens
mkdir -p lib/features/shop/presentation/widgets
mkdir -p lib/features/shop/providers

mkdir -p lib/features/product_detail/presentation/screens
mkdir -p lib/features/product_detail/presentation/widgets
mkdir -p lib/features/product_detail/providers

mkdir -p lib/features/cart_checkout/presentation/screens
mkdir -p lib/features/cart_checkout/presentation/widgets
mkdir -p lib/features/cart_checkout/providers

mkdir -p lib/features/orders/presentation/screens
mkdir -p lib/features/orders/presentation/widgets
mkdir -p lib/features/orders/providers

mkdir -p lib/features/favorites/presentation/screens
mkdir -p lib/features/favorites/providers

mkdir -p lib/features/sell/presentation/screens
mkdir -p lib/features/sell/presentation/widgets
mkdir -p lib/features/sell/providers

mkdir -p lib/features/agent/presentation/screens
mkdir -p lib/features/agent/presentation/widgets
mkdir -p lib/features/agent/providers

mkdir -p lib/features/messages/presentation/screens
mkdir -p lib/features/messages/presentation/widgets
mkdir -p lib/features/messages/providers

mkdir -p lib/features/notifications/presentation/screens
mkdir -p lib/features/notifications/providers

mkdir -p lib/features/profile/presentation/screens
mkdir -p lib/features/profile/providers

mkdir -p lib/features/admin/presentation/screens
mkdir -p lib/features/admin/presentation/widgets
mkdir -p lib/features/admin/providers

mkdir -p lib/features/super_admin/presentation/screens
mkdir -p lib/features/super_admin/presentation/widgets
mkdir -p lib/features/super_admin/providers

# --- assets : ressources statiques ---
mkdir -p assets/images
mkdir -p assets/icons
mkdir -p assets/illustrations
mkdir -p assets/fonts

echo "→ Arborescence créée avec succès."

# ----------------------------------------------------------------------
# 3. Fichier .gitkeep pour préserver les dossiers vides dans git
# ----------------------------------------------------------------------
find lib -type d -empty -exec touch {}/.gitkeep \;
find assets -type d -empty -exec touch {}/.gitkeep \;

echo ""
echo "============================================================"
echo "  ✔ Script 01 terminé avec succès."
echo "============================================================"
echo ""
echo "PROCHAINE ÉTAPE :"
echo "  1. Lancez : flutter pub get"
echo "  2. Vérifiez qu'aucune erreur n'apparaît."
echo "  3. Une fois confirmé, je vous donnerai le script 02"
echo "     (thème, configuration, gestion d'erreurs, routeur)."
echo ""
