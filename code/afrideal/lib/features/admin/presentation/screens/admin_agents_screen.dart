import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/errors/error_view.dart';
import '../../../../domain/entities/utilisateur.dart';
import '../../../../shared/widgets/cards/app_avatar.dart';
import '../../../../shared/widgets/feedback/app_loading_indicator.dart';
import '../../../../shared/widgets/inputs/app_search_field.dart';
import '../../providers/admin_provider.dart';

class AdminAgentsScreen extends ConsumerStatefulWidget {
  const AdminAgentsScreen({super.key});

  @override
  ConsumerState<AdminAgentsScreen> createState() => _AdminAgentsScreenState();
}

class _AdminAgentsScreenState extends ConsumerState<AdminAgentsScreen> {
  String _requete = '';

  @override
  Widget build(BuildContext context) {
    final agentsAsync = ref.watch(agentsAdminProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Agents terrain', style: AppTypography.displayMedium),
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
                      hint: 'Rechercher un agent...',
                      onChanged: (v) => setState(() => _requete = v),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    agentsAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: Center(child: AppLoadingIndicator()),
                      ),
                      error: (_, __) => ErrorView(
                        message: 'Impossible de charger les agents.',
                        onRetry: () => ref.invalidate(agentsAdminProvider),
                      ),
                      data: (agents) {
                        final req = _requete.trim().toLowerCase();
                        final filtres = agents
                            .where((a) => req.isEmpty || a.nomComplet.toLowerCase().contains(req))
                            .toList();

                        if (filtres.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                            child: EmptyView(message: 'Aucun agent terrain', icon: Icons.route_outlined),
                          );
                        }

                        return Column(
                          children: [
                            for (final agent in filtres) ...[
                              _AgentTile(agent: agent),
                              if (agent != filtres.last) const Divider(height: 1),
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

class _AgentTile extends ConsumerWidget {
  final Utilisateur agent;
  const _AgentTile({required this.agent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missionsAsync = ref.watch(missionCountByAgentProvider(agent.id));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          AppAvatar(initiales: agent.initiales, size: 44),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(agent.nomComplet, style: AppTypography.titleMedium),
                const SizedBox(height: 2),
                Text(
                  '${agent.ville ?? 'Zone non précisée'} · '
                  '${missionsAsync.valueOrNull ?? '…'} mission(s)',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          Switch(
            value: agent.estActif,
            activeThumbColor: AppColors.violet,
            onChanged: (v) => ref.read(adminUserNotifierProvider.notifier).toggleActif(agent.id, v),
          ),
        ],
      ),
    );
  }
}
