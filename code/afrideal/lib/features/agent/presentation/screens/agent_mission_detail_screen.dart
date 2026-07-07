import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/errors/error_view.dart';
import '../../../../domain/enums/mission_status.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/buttons/app_secondary_button.dart';
import '../../../../shared/widgets/cards/info_row.dart';
import '../../../../shared/widgets/cards/status_badge.dart';
import '../../../../shared/widgets/feedback/app_loading_indicator.dart';
import '../../../../shared/widgets/feedback/app_snackbar.dart';
import '../../providers/agent_provider.dart';

class AgentMissionDetailScreen extends ConsumerWidget {
  final String missionId;
  const AgentMissionDetailScreen({super.key, required this.missionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missionAsync = ref.watch(missionDetailProvider(missionId));
    final notifierState = ref.watch(agentMissionNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Détail de la mission')),
      body: missionAsync.when(
        loading: () => const AppLoadingIndicator(),
        error: (_, __) => const ErrorView(message: 'Mission introuvable.'),
        data: (mission) {
          if (mission == null) return const ErrorView(message: 'Mission introuvable.');
          final estComplete = mission.statut == MissionStatus.complete;
          final estEchec = mission.statut == MissionStatus.echec;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(mission.type.label, style: AppTypography.displayMedium),
                    StatusBadge(label: mission.statut.label, color: mission.statut.color),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.lgRadius,
                    border: Border.all(color: AppColors.gray200),
                  ),
                  child: Column(
                    children: [
                      InfoRow(
                        icon: Icons.schedule_outlined,
                        label: 'Date et heure prévues',
                        value: Formatters.dateWithTime(mission.dateHeure),
                      ),
                      if (mission.latitude != null) ...[
                        const Divider(height: AppSpacing.xl),
                        InfoRow(
                          icon: Icons.location_on_outlined,
                          label: 'Localisation GPS',
                          value: '${mission.latitude!.toStringAsFixed(4)}, '
                              '${mission.longitude!.toStringAsFixed(4)}',
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (!estComplete && !estEchec) ...[
                  if (mission.statut == MissionStatus.assignee)
                    AppPrimaryButton(
                      label: 'Démarrer la mission',
                      icon: Icons.directions_car_outlined,
                      isLoading: notifierState.isLoading,
                      onPressed: () async {
                        await ref.read(agentMissionNotifierProvider.notifier).demarrer(mission);
                        if (context.mounted) AppSnackbar.showSuccess(context, 'Mission démarrée.');
                      },
                    ),
                  if (mission.statut == MissionStatus.enRoute)
                    AppPrimaryButton(
                      label: 'Signaler mon arrivée',
                      icon: Icons.where_to_vote_outlined,
                      isLoading: notifierState.isLoading,
                      onPressed: () async {
                        await ref.read(agentMissionNotifierProvider.notifier).signalerArrivee(mission);
                        if (context.mounted) AppSnackbar.showSuccess(context, 'Arrivée signalée.');
                      },
                    ),
                  if (mission.statut == MissionStatus.surSite) ...[
                    AppPrimaryButton(
                      label: 'Valider la collecte',
                      icon: Icons.check_circle_outline_rounded,
                      isLoading: notifierState.isLoading,
                      onPressed: () async {
                        await ref.read(agentMissionNotifierProvider.notifier).validerCollecte(mission);
                        if (context.mounted) AppSnackbar.showSuccess(context, 'Collecte validée !');
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppSecondaryButton(
                      label: 'Signaler un refus',
                      icon: Icons.cancel_outlined,
                      onPressed: () => _showRefusDialog(context, ref, mission),
                    ),
                  ],
                ],
                if (estComplete)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.successSurface,
                      borderRadius: AppRadius.lgRadius,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppColors.success),
                        const SizedBox(width: AppSpacing.sm),
                        Text('Mission complétée avec succès.',
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.success)),
                      ],
                    ),
                  ),
                if (estEchec && mission.raisonRefus != null)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.dangerSurface,
                      borderRadius: AppRadius.lgRadius,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.cancel_rounded, color: AppColors.danger),
                            const SizedBox(width: AppSpacing.sm),
                            Text('Mission échouée', style: AppTypography.titleMedium.copyWith(color: AppColors.danger)),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(mission.raisonRefus!, style: AppTypography.bodySmall),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showRefusDialog(BuildContext context, WidgetRef ref, mission) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Raison du refus'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Décrivez pourquoi la collecte échoue...'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(agentMissionNotifierProvider.notifier).signalerRefus(mission, controller.text);
              if (context.mounted) AppSnackbar.showInfo(context, 'Refus signalé.');
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }
}
