import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/feedback/app_snackbar.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../providers/session_provider.dart';

/// Écran de connexion classique par numéro de téléphone et mot de
/// passe, pour les utilisateurs disposant déjà d'un compte.
///
/// Complète le mode démo (sélection directe de profil) sans le
/// remplacer : les deux entrées coexistent, l'utilisateur choisissant
/// depuis [EntryChoiceScreen] ou [DemoAccountsScreen]. La navigation
/// après connexion réussie est entièrement gérée par le redirect
/// centralisé du routeur (voir app_router.dart), qui réagit au
/// changement de session — cet écran n'a donc qu'à déclencher la
/// connexion et afficher une erreur le cas échéant.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _telephoneController = TextEditingController();
  final _motDePasseController = TextEditingController();
  bool _motDePasseVisible = false;

  @override
  void dispose() {
    _telephoneController.dispose();
    _motDePasseController.dispose();
    super.dispose();
  }

  Future<void> _seConnecter() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(sessionProvider.notifier).login(
          telephone: _telephoneController.text.trim(),
          motDePasse: _motDePasseController.text,
        );

    if (!mounted) return;
    final session = ref.read(sessionProvider);
    if (session.hasError) {
      final erreur = session.error;
      final message = erreur is AppException ? erreur.message : 'Connexion impossible.';
      AppSnackbar.showError(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final enCours = session.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Connexion')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Content de vous revoir', style: AppTypography.headline),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Connectez-vous avec votre numéro de téléphone et votre mot de passe.',
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xl),
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
                    if (valeur == null || valeur.isEmpty) {
                      return 'Veuillez saisir votre mot de passe.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                AppPrimaryButton(
                  label: 'Se connecter',
                  isLoading: enCours,
                  onPressed: enCours ? null : _seConnecter,
                ),
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: TextButton(
                    onPressed: enCours
                        ? null
                        : () {
                            final from = GoRouterState.of(context).uri.queryParameters['from'];
                            final chemin = from == null
                                ? AppRoutes.register
                                : '${AppRoutes.register}?from=${Uri.encodeComponent(from)}';
                            context.push(chemin);
                          },
                    child: const Text('Pas de compte ? Créer un compte'),
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: enCours
                        ? null
                        : () {
                            final from = GoRouterState.of(context).uri.queryParameters['from'];
                            final chemin = from == null
                                ? AppRoutes.demoAccounts
                                : '${AppRoutes.demoAccounts}?from=${Uri.encodeComponent(from)}';
                            context.push(chemin);
                          },
                    child: const Text('Découvrir un compte de démonstration'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
