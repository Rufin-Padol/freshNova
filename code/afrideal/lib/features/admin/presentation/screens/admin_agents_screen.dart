import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/errors/error_view.dart';
import '../../../../shared/widgets/cards/app_avatar.dart';
import '../../../../shared/widgets/feedback/app_loading_indicator.dart';
import '../../providers/admin_provider.dart';

class AdminAgentsScreen extends ConsumerWidget {
  const AdminAgentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agentsAsync = ref.watch(agentsAdminProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text('Agents terrain', style: AppTypography.displayMedium),
          ),
          Expanded(
            child: agentsAsync.when(
              loading: () => const AppLoadingIndicator(),
              error: (_, __) => ErrorView(
                message: 'Impossible de charger les agents.',
                onRetry: () => ref.invalidate(agentsAdminProvider),
              ),
              data: (agents) {
                if (agents.isEmpty) {
                  return const EmptyView(message: 'Aucun agent terrain', icon: Icons.route_outlined);
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  itemCount: agents.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final agent = agents[i];
                    final missionsAsync = ref.watch(missionCountByAgentProvider(agent.id));
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      leading: AppAvatar(initiales: agent.initiales, size: 40),
                      title: Text(agent.nomComplet, style: AppTypography.titleMedium),
                      subtitle: Text(
                        '${agent.ville ?? 'Zone non précisée'} · '
                        '${missionsAsync.valueOrNull ?? '…'} mission(s)',
                        style: AppTypography.bodySmall,
                      ),
                      trailing: Switch(
                        value: agent.estActif,
                        onChanged: (v) => ref
                            .read(adminUserNotifierProvider.notifier)
                            .toggleActif(agent.id, v),
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
