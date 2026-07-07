import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/errors/error_view.dart';
import '../../../../shared/widgets/cards/app_avatar.dart';
import '../../../../shared/widgets/cards/status_badge.dart';
import '../../../../shared/widgets/feedback/app_loading_indicator.dart';
import '../../../../shared/widgets/feedback/app_snackbar.dart';
import '../../providers/admin_provider.dart';

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersAdminProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text('Utilisateurs', style: AppTypography.displayMedium),
          ),
          Expanded(
            child: usersAsync.when(
              loading: () => const AppLoadingIndicator(),
              error: (_, __) => ErrorView(
                message: 'Impossible de charger les utilisateurs.',
                onRetry: () => ref.invalidate(allUsersAdminProvider),
              ),
              data: (users) {
                if (users.isEmpty) {
                  return const EmptyView(message: 'Aucun utilisateur', icon: Icons.people_outline_rounded);
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final u = users[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      leading: AppAvatar(initiales: u.initiales, size: 44),
                      title: Row(
                        children: [
                          Expanded(child: Text(u.nomComplet, style: AppTypography.titleMedium)),
                          StatusBadge(
                            label: u.estActif ? 'Actif' : 'Désactivé',
                            color: u.estActif ? AppColors.success : AppColors.danger,
                          ),
                        ],
                      ),
                      subtitle: Text(
                        '${u.role.label} · ${u.telephone}',
                        style: AppTypography.bodySmall,
                      ),
                      trailing: Switch(
                        value: u.estActif,
                        activeColor: AppColors.violet,
                        onChanged: (val) async {
                          await ref.read(adminUserNotifierProvider.notifier).toggleActif(u.id, val);
                          if (context.mounted) {
                            AppSnackbar.showSuccess(
                              context,
                              val ? '${u.prenom} activé.' : '${u.prenom} désactivé.',
                            );
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
