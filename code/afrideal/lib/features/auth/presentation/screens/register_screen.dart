import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/entities/utilisateur.dart';
import '../../../../domain/enums/user_role.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/feedback/app_snackbar.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../providers/session_provider.dart';

const _uuid = Uuid();

/// Écran de création de compte.
///
/// La ville est un champ obligatoire (pas seulement un champ optionnel
/// de profil) : elle sert à mettre en avant, dans la boutique, les
/// annonces situées dans la même ville que l'acheteur (voir
/// shopProductsProvider) — un signal utile pour évaluer la
/// faisabilité d'une livraison rapide.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _villeController = TextEditingController();
  final _motDePasseController = TextEditingController();
  bool _motDePasseVisible = false;

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _villeController.dispose();
    _motDePasseController.dispose();
    super.dispose();
  }

  Future<void> _creerCompte() async {
    if (!_formKey.currentState!.validate()) return;

    final utilisateur = Utilisateur(
      id: _uuid.v4(),
      nom: _nomController.text.trim(),
      prenom: _prenomController.text.trim(),
      telephone: _telephoneController.text.trim(),
      motDePasseHash: '',
      role: UserRole.acheteur,
      ville: _villeController.text.trim(),
      dateInscription: DateTime.now(),
    );

    await ref.read(sessionProvider.notifier).register(
          utilisateur,
          _motDePasseController.text,
        );

    if (!mounted) return;
    final session = ref.read(sessionProvider);
    if (session.hasError) {
      final erreur = session.error;
      final message = erreur is AppException ? erreur.message : 'Inscription impossible.';
      AppSnackbar.showError(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final enCours = session.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Créer un compte')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bienvenue sur TrustNova', style: AppTypography.headline),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Créez votre compte pour acheter et vendre en toute confiance.',
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Prénom',
                        controller: _prenomController,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Requis' : null,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppTextField(
                        label: 'Nom',
                        controller: _nomController,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Requis' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Numéro de téléphone',
                  hint: '6XX XXX XXX',
                  controller: _telephoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  validator: (valeur) {
                    if (valeur == null || valeur.trim().isEmpty) {
                      return 'Veuillez saisir votre numéro de téléphone.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Ville',
                  hint: 'Douala, Yaoundé...',
                  controller: _villeController,
                  prefixIcon: Icons.location_city_outlined,
                  validator: (valeur) {
                    if (valeur == null || valeur.trim().isEmpty) {
                      return 'Votre ville nous aide à vous montrer les annonces proches.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Mot de passe',
                  hint: '••••••••',
                  controller: _motDePasseController,
                  obscureText: !_motDePasseVisible,
                  prefixIcon: Icons.lock_outline_rounded,
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _motDePasseVisible = !_motDePasseVisible),
                    icon: Icon(
                      _motDePasseVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                  validator: (valeur) {
                    if (valeur == null || valeur.length < 6) {
                      return 'Au moins 6 caractères.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                AppPrimaryButton(
                  label: 'Créer mon compte',
                  isLoading: enCours,
                  onPressed: enCours ? null : _creerCompte,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
