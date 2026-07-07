import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/errors/error_view.dart';
import '../../../../shared/widgets/cards/status_badge.dart';
import '../../../../shared/widgets/feedback/app_loading_indicator.dart';

/// Toutes les commandes de la plateforme, triées par date décroissante.
/// Déclaré au niveau global (et non dans build()) pour respecter les
/// règles de Riverpod : les providers doivent être des variables
/// top-level ou statiques, jamais créées à l'intérieur de fonctions.
final allOrdersAdminProvider = FutureProvider((ref) async {
  final repo = ref.watch(orderRepositoryProvider);
  final all = await repo.getAll();
  all.sort((a, b) => b.dateCommande.compareTo(a.dateCommande));
  return all;
});

class AdminOrdersScreen extends ConsumerWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(allOrdersAdminProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text('Commandes', style: AppTypography.displayMedium),
          ),
          Expanded(
            child: async.when(
              loading: () => const AppLoadingIndicator(),
              error: (_, __) => const ErrorView(message: 'Impossible de charger les commandes.'),
              data: (commandes) {
                if (commandes.isEmpty) {
                  return const EmptyView(message: 'Aucune commande', icon: Icons.receipt_long_outlined);
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  itemCount: commandes.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final c = commandes[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      title: Row(
                        children: [
                          Expanded(child: Text('#${c.reference}', style: AppTypography.titleMedium)),
                          StatusBadge(label: c.statut.label, color: c.statut.color),
                        ],
                      ),
                      subtitle: Text(
                        '${Formatters.currency(c.montantTotal)} · ${Formatters.shortDate(c.dateCommande)}',
                        style: AppTypography.bodySmall,
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
