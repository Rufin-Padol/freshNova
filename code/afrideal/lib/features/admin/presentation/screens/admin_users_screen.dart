import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/errors/error_view.dart';
import '../../../../domain/entities/utilisateur.dart';
import '../../../../shared/widgets/cards/app_avatar.dart';
import '../../../../shared/widgets/cards/status_badge.dart';
import '../../../../shared/widgets/feedback/app_loading_indicator.dart';
import '../../../../shared/widgets/feedback/app_snackbar.dart';
import '../../../../shared/widgets/inputs/app_search_field.dart';
import '../../providers/admin_provider.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  String _requete = '';

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersAdminProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Utilisateurs', style: AppTypography.displayMedium),
              const SizedBox(height: AppSpacing.xl),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.lgRadius,
                  border: Border.all(color: AppColors.gray200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSearchField(
                      hint: 'Rechercher un utilisateur...',
                      onChanged: (v) => setState(() => _requete = v),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    usersAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: Center(child: AppLoadingIndicator()),
                      ),
                      error: (_, __) => ErrorView(
                        message: 'Impossible de charger les utilisateurs.',
                        onRetry: () => ref.invalidate(allUsersAdminProvider),
                      ),
                      data: (users) {
                        final req = _requete.trim().toLowerCase();
                        final filtres = users.where((u) {
                          if (req.isEmpty) return true;
                          return u.nomComplet.toLowerCase().contains(req) ||
                              u.telephone.contains(req);
                        }).toList();

                        if (filtres.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                            child: EmptyView(
                              message: 'Aucun utilisateur',
                              icon: Icons.people_outline_rounded,
                            ),
                          );
                        }

                        return Column(
                          children: [
                            for (final u in filtres) ...[
                              _UserTile(utilisateur: u),
                              if (u != filtres.last) const Divider(height: 1),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserTile extends ConsumerWidget {
  final Utilisateur utilisateur;
  const _UserTile({required this.utilisateur});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          AppAvatar(initiales: utilisateur.initiales, size: 44),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(utilisateur.nomComplet, style: AppTypography.titleMedium),
                const SizedBox(height: 2),
                Text(
                  '${utilisateur.role.label} · ${utilisateur.telephone}',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          StatusBadge(
            label: utilisateur.estActif ? 'Actif' : 'Désactivé',
            color: utilisateur.estActif ? AppColors.success : AppColors.danger,
          ),
          const SizedBox(width: AppSpacing.md),
          Switch(
            value: utilisateur.estActif,
            activeThumbColor: AppColors.violet,
            onChanged: (val) async {
              await ref
                  .read(adminUserNotifierProvider.notifier)
                  .toggleActif(utilisateur.id, val);
              if (context.mounted) {
                AppSnackbar.showSuccess(
                  context,
                  val ? '${utilisateur.prenom} activé.' : '${utilisateur.prenom} désactivé.',
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
