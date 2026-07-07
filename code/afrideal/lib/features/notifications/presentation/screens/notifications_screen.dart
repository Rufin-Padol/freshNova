import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/errors/error_view.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../domain/enums/notification_type.dart';
import '../../../../shared/widgets/feedback/app_loading_indicator.dart';
import '../../../auth/providers/session_provider.dart';
import '../../providers/notification_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(myNotificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Notifications')),
      body: notifsAsync.when(
        loading: () => const AppLoadingIndicator(),
        error: (_, __) => ErrorView(
          message: 'Impossible de charger vos notifications.',
          onRetry: () => ref.invalidate(myNotificationsProvider),
        ),
        data: (notifs) {
          if (notifs.isEmpty) {
            return const EmptyView(
              message: 'Aucune notification',
              subtitle: 'Vos alertes importantes apparaîtront ici.',
              icon: Icons.notifications_none_rounded,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            itemCount: notifs.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, i) {
              final notif = notifs[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: notif.estLue ? AppColors.gray100 : AppColors.violetSurface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _iconeType(notif.type),
                    color: notif.estLue ? AppColors.gray400 : AppColors.violet,
                    size: 22,
                  ),
                ),
                title: Text(
                  notif.message,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: notif.estLue ? FontWeight.w400 : FontWeight.w600,
                    color: notif.estLue ? AppColors.gray600 : AppColors.black,
                  ),
                ),
                subtitle: Text(
                  Formatters.relativeDate(notif.dateEnvoi),
                  style: AppTypography.caption,
                ),
                onTap: notif.estLue
                    ? null
                    : () async {
                        final repo = ref.read(notificationRepositoryProvider);
                        await repo.marquerCommeLue(notif.id);
                        ref.invalidate(myNotificationsProvider);
                        ref.invalidate(unreadCountProvider);
                      },
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconeType(NotificationType type) {
    switch (type) {
      case NotificationType.commande:
        return Icons.receipt_long_rounded;
      case NotificationType.produit:
        return Icons.inventory_2_rounded;
      case NotificationType.mission:
        return Icons.route_rounded;
      case NotificationType.paiement:
        return Icons.payments_rounded;
      case NotificationType.litige:
        return Icons.gavel_rounded;
      case NotificationType.message:
        return Icons.chat_bubble_rounded;
      case NotificationType.systeme:
        return Icons.info_rounded;
    }
  }
}
