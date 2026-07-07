#!/bin/bash
# ============================================================================
# SCRIPT 13 — Messagerie, Notifications, Profil et Admin web
# Projet : AfriDeal — Plateforme de revente de seconde main (Cameroun)
# ============================================================================
#
# CE QUE FAIT CE SCRIPT :
#   1. Providers :
#        • lib/features/messages/providers/message_provider.dart
#        • lib/features/notifications/providers/notification_provider.dart
#        • lib/features/admin/providers/admin_provider.dart
#   2. Écrans communs (Acheteur/Vendeur/Agent) :
#        • MessagesScreen        → liste des conversations
#        • ConversationScreen    → fil de messages
#        • NotificationsScreen   → liste des notifications
#        • ProfileScreen         → profil utilisateur + déconnexion
#   3. Interface Admin web :
#        • AdminShellScreen      → navigation latérale (sidebar) pour
#          le panel web, adaptée aussi en mobile
#        • AdminDashboardScreen  → tableau de bord (KPIs)
#        • AdminCatalogScreen    → gestion des produits (tous statuts,
#          actions : valider, refuser, publier)
#        • AdminOrdersScreen     → toutes les commandes
#        • AdminUsersScreen      → liste utilisateurs + activer/désactiver
#   4. Mise à jour du routeur pour brancher tous ces écrans
#
# COMMENT EXÉCUTER CE SCRIPT :
#   bash 13_messages_notifications_admin.sh
# ============================================================================

set -e

echo "============================================================"
echo "  AfriDeal — Script 13/14 : Messages, Notifs, Profil, Admin"
echo "============================================================"

if [ ! -f "lib/features/agent/presentation/screens/agent_dashboard_screen.dart" ]; then
  echo "ERREUR : agent_dashboard_screen.dart introuvable. Avez-vous exécuté le script 12 ?"
  exit 1
fi

mkdir -p lib/features/messages/providers
mkdir -p lib/features/messages/presentation/screens
mkdir -p lib/features/notifications/providers
mkdir -p lib/features/notifications/presentation/screens
mkdir -p lib/features/profile/providers
mkdir -p lib/features/profile/presentation/screens
mkdir -p lib/features/admin/providers
mkdir -p lib/features/admin/presentation/screens
mkdir -p lib/features/admin/presentation/widgets

# ============================================================================
# 1. PROVIDERS
# ============================================================================
cat > lib/features/messages/providers/message_provider.dart << 'EOF'
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../domain/entities/conversation.dart';
import '../../../domain/entities/message.dart';
import '../../auth/providers/session_provider.dart';

const _uuid = Uuid();

final myConversationsProvider = FutureProvider<List<Conversation>>((ref) async {
  final utilisateur = ref.watch(currentUserProvider);
  if (utilisateur == null) return [];
  final repo = ref.watch(messageRepositoryProvider);
  return repo.getConversations(utilisateur.id);
});

final conversationMessagesProvider =
    FutureProvider.family<List<Message>, String>((ref, conversationId) async {
  final repo = ref.watch(messageRepositoryProvider);
  return repo.getMessages(conversationId);
});

class ConversationNotifier extends FamilyNotifier<AsyncValue<List<Message>>, String> {
  @override
  AsyncValue<List<Message>> build(String conversationId) {
    _charger();
    return const AsyncLoading();
  }

  Future<void> _charger() async {
    try {
      final repo = ref.read(messageRepositoryProvider);
      final msgs = await repo.getMessages(arg);
      state = AsyncData(msgs);
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }

  Future<void> envoyer(String contenu) async {
    final utilisateur = ref.read(currentUserProvider);
    if (utilisateur == null || contenu.trim().isEmpty) return;
    final repo = ref.read(messageRepositoryProvider);
    final msg = Message(
      id: _uuid.v4(),
      conversationId: arg,
      expediteurId: utilisateur.id,
      contenu: contenu.trim(),
      dateEnvoi: DateTime.now(),
    );
    await repo.envoyerMessage(msg);
    await _charger();
    ref.invalidate(myConversationsProvider);
  }
}

final conversationNotifierProvider = NotifierProviderFamily<ConversationNotifier,
    AsyncValue<List<Message>>, String>(ConversationNotifier.new);
EOF
echo "→ lib/features/messages/providers/message_provider.dart créé."

cat > lib/features/notifications/providers/notification_provider.dart << 'EOF'
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../domain/entities/notification_entity.dart';
import '../../auth/providers/session_provider.dart';

final myNotificationsProvider = FutureProvider<List<NotificationEntity>>((ref) async {
  final utilisateur = ref.watch(currentUserProvider);
  if (utilisateur == null) return [];
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.getByDestinataire(utilisateur.id);
});

final unreadCountProvider = FutureProvider<int>((ref) async {
  final utilisateur = ref.watch(currentUserProvider);
  if (utilisateur == null) return 0;
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.compterNonLues(utilisateur.id);
});
EOF
echo "→ lib/features/notifications/providers/notification_provider.dart créé."

cat > lib/features/admin/providers/admin_provider.dart << 'EOF'
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../domain/entities/produit.dart';
import '../../../domain/entities/utilisateur.dart';
import '../../../domain/enums/product_status.dart';
import '../../../domain/enums/user_role.dart';

final allProductsAdminProvider = FutureProvider<List<Produit>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  final all = await repo.getAll();
  all.sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
  return all;
});

final allUsersAdminProvider = FutureProvider<List<Utilisateur>>((ref) async {
  final repo = ref.watch(userRepositoryProvider);
  return repo.getAll();
});

final agentsAdminProvider = FutureProvider<List<Utilisateur>>((ref) async {
  final repo = ref.watch(userRepositoryProvider);
  return repo.getByRole(UserRole.agentTerrain);
});

/// Actions admin sur les produits (changement de statut).
class AdminProductNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> changerStatut(String produitId, ProductStatus statut) async {
    final repo = ref.read(productRepositoryProvider);
    await repo.updateStatut(produitId, statut);
    ref.invalidate(allProductsAdminProvider);
  }
}

final adminProductNotifierProvider =
    NotifierProvider<AdminProductNotifier, void>(AdminProductNotifier.new);

/// Actions admin sur les utilisateurs (activer/désactiver).
class AdminUserNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> toggleActif(String userId, bool estActif) async {
    final repo = ref.read(userRepositoryProvider);
    await repo.toggleActif(userId, estActif);
    ref.invalidate(allUsersAdminProvider);
  }
}

final adminUserNotifierProvider =
    NotifierProvider<AdminUserNotifier, void>(AdminUserNotifier.new);
EOF
echo "→ lib/features/admin/providers/admin_provider.dart créé."

# ============================================================================
# 2. ÉCRANS COMMUNS
# ============================================================================
cat > lib/features/messages/presentation/screens/messages_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/errors/error_view.dart';
import '../../../../shared/widgets/cards/app_avatar.dart';
import '../../../../shared/widgets/feedback/app_loading_indicator.dart';
import '../../../auth/providers/session_provider.dart';
import '../../providers/message_provider.dart';

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final convsAsync = ref.watch(myConversationsProvider);
    final moi = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Messages')),
      body: convsAsync.when(
        loading: () => const AppLoadingIndicator(),
        error: (_, __) => ErrorView(
          message: 'Impossible de charger vos messages.',
          onRetry: () => ref.invalidate(myConversationsProvider),
        ),
        data: (convs) {
          if (convs.isEmpty) {
            return const EmptyView(
              message: 'Aucun message',
              subtitle: 'Contactez un vendeur depuis la fiche produit.',
              icon: Icons.chat_bubble_outline_rounded,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            itemCount: convs.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, i) {
              final conv = convs[i];
              final nonLu = conv.nombreNonLus > 0;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                leading: conv.estSupport
                    ? Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shield_rounded, color: AppColors.white, size: 24),
                      )
                    : AppAvatar(
                        initiales: conv.participantIds
                            .where((id) => id != moi?.id)
                            .firstOrNull
                            ?.substring(0, 2)
                            .toUpperCase() ??
                            'AF',
                        size: 48,
                      ),
                title: Text(
                  conv.estSupport ? 'Support AfriDeal' : 'Conversation',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: nonLu ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  conv.dernierMessage,
                  style: AppTypography.bodySmall.copyWith(
                    color: nonLu ? AppColors.black : AppColors.gray500,
                    fontWeight: nonLu ? FontWeight.w600 : FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.relativeDate(conv.dateDernierMessage),
                      style: AppTypography.caption,
                    ),
                    if (nonLu) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: AppColors.violet,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${conv.nombreNonLus}',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                onTap: () => context.push(
                  AppRoutes.conversation.replaceFirst(':conversationId', conv.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
EOF
echo "→ lib/features/messages/presentation/screens/messages_screen.dart créé."

cat > lib/features/messages/presentation/screens/conversation_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/errors/error_view.dart';
import '../../../../shared/widgets/feedback/app_loading_indicator.dart';
import '../../../auth/providers/session_provider.dart';
import '../../providers/message_provider.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  final String conversationId;
  const ConversationScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _envoyer() {
    final texte = _controller.text.trim();
    if (texte.isEmpty) return;
    _controller.clear();
    ref.read(conversationNotifierProvider(widget.conversationId).notifier).envoyer(texte);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final msgsState = ref.watch(conversationNotifierProvider(widget.conversationId));
    final moi = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Conversation')),
      body: Column(
        children: [
          Expanded(
            child: msgsState.when(
              loading: () => const AppLoadingIndicator(),
              error: (_, __) => const ErrorView(message: 'Impossible de charger la conversation.'),
              data: (msgs) => ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: msgs.length,
                itemBuilder: (context, i) {
                  final msg = msgs[i];
                  final estMoi = msg.expediteurId == moi?.id;
                  return Align(
                    alignment: estMoi ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.72,
                      ),
                      decoration: BoxDecoration(
                        color: estMoi ? AppColors.violet : AppColors.surface,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(AppRadius.md),
                          topRight: const Radius.circular(AppRadius.md),
                          bottomLeft: Radius.circular(estMoi ? AppRadius.md : AppRadius.xs),
                          bottomRight: Radius.circular(estMoi ? AppRadius.xs : AppRadius.md),
                        ),
                        border: estMoi ? null : Border.all(color: AppColors.gray200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            msg.contenu,
                            style: AppTypography.bodyLarge.copyWith(
                              color: estMoi ? AppColors.white : AppColors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            Formatters.dateWithTime(msg.dateEnvoi),
                            style: AppTypography.caption.copyWith(
                              color: estMoi
                                  ? AppColors.white.withValues(alpha: 0.7)
                                  : AppColors.gray400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.gray200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Votre message...',
                        border: InputBorder.none,
                        filled: false,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _envoyer(),
                    ),
                  ),
                  IconButton(
                    onPressed: _envoyer,
                    icon: const Icon(Icons.send_rounded, color: AppColors.violet),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
EOF
echo "→ lib/features/messages/presentation/screens/conversation_screen.dart créé."

cat > lib/features/notifications/presentation/screens/notifications_screen.dart << 'EOF'
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
EOF
echo "→ lib/features/notifications/presentation/screens/notifications_screen.dart créé."

cat > lib/features/profile/presentation/screens/profile_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/local/datasources/hive_service.dart';
import '../../../../data/local/seed/datasources_box_check.dart';
import '../../../../shared/widgets/cards/app_avatar.dart';
import '../../../../shared/widgets/feedback/app_snackbar.dart';
import '../../../auth/providers/session_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final utilisateur = ref.watch(currentUserProvider);
    if (utilisateur == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mon profil')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Center(
            child: Column(
              children: [
                AppAvatar(initiales: utilisateur.initiales, size: 80),
                const SizedBox(height: AppSpacing.md),
                Text(utilisateur.nomComplet, style: AppTypography.headline),
                const SizedBox(height: 4),
                Text(utilisateur.role.label, style: AppTypography.bodyMedium),
                if (utilisateur.ville != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: AppColors.gray400),
                      const SizedBox(width: 2),
                      Text(utilisateur.ville!, style: AppTypography.bodySmall),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          _SectionTitre('Informations'),
          _InfoTile(Icons.phone_outlined, 'Téléphone', utilisateur.telephone),
          _InfoTile(Icons.badge_outlined, 'Rôle', utilisateur.role.label),
          if (utilisateur.noteVendeur != null)
            _InfoTile(Icons.star_outline_rounded, 'Note vendeur',
                '${utilisateur.noteVendeur!.toStringAsFixed(1)} / 5.0'),
          const SizedBox(height: AppSpacing.xl),
          _SectionTitre('Application'),
          _InfoTile(
            AppConfig.isLocal ? Icons.storage_outlined : Icons.cloud_outlined,
            'Mode de données',
            AppConfig.isLocal ? 'Données locales' : 'API connectée',
          ),
          const SizedBox(height: AppSpacing.xl),
          if (AppConfig.isLocal) ...[
            _SectionTitre('Développement'),
            ListTile(
              leading: const Icon(Icons.refresh_rounded, color: AppColors.warning),
              title: Text('Réinitialiser les données de démo',
                  style: AppTypography.bodyLarge.copyWith(color: AppColors.warning)),
              onTap: () async {
                await HiveService.clearAll();
                await DemoSeedCheck.resetSeedFlag();
                if (context.mounted) {
                  AppSnackbar.showInfo(context, 'Données réinitialisées. Relancez l\'app.');
                }
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.danger),
            title: Text('Se déconnecter',
                style: AppTypography.bodyLarge.copyWith(color: AppColors.danger)),
            onTap: () async {
              await ref.read(sessionProvider.notifier).logout();
            },
          ),
          const SizedBox(height: AppSpacing.huge),
        ],
      ),
    );
  }
}

class _SectionTitre extends StatelessWidget {
  final String titre;
  const _SectionTitre(this.titre);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
      child: Text(titre, style: AppTypography.label.copyWith(letterSpacing: 0.8)),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.gray500, size: 22),
      title: Text(label, style: AppTypography.bodySmall),
      subtitle: Text(value, style: AppTypography.bodyLarge.copyWith(color: AppColors.black)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
    );
  }
}
EOF
echo "→ lib/features/profile/presentation/screens/profile_screen.dart créé."

# ============================================================================
# 3. INTERFACE ADMIN WEB
# ============================================================================
cat > lib/features/admin/presentation/widgets/admin_sidebar.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/providers/session_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Navigation latérale du panel Admin, utilisée à la fois sur le
/// web (sidebar fixe à gauche) et en repli sur mobile (Drawer).
class AdminSidebar extends ConsumerWidget {
  final String currentRoute;
  const AdminSidebar({super.key, required this.currentRoute});

  static const _items = [
    _NavItem(Icons.dashboard_rounded, 'Tableau de bord', AppRoutes.adminDashboard),
    _NavItem(Icons.inventory_2_outlined, 'Catalogue', AppRoutes.adminCatalog),
    _NavItem(Icons.receipt_long_outlined, 'Commandes', AppRoutes.adminOrders),
    _NavItem(Icons.people_outline_rounded, 'Utilisateurs', AppRoutes.adminUsers),
    _NavItem(Icons.gavel_rounded, 'Litiges', AppRoutes.adminDisputes),
    _NavItem(Icons.route_outlined, 'Agents', AppRoutes.adminAgents),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 220,
      decoration: const BoxDecoration(
        color: AppColors.black,
        border: Border(right: BorderSide(color: AppColors.gray800)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AfriDeal',
                      style: AppTypography.titleLarge.copyWith(color: AppColors.white)),
                  Text('Administration',
                      style: AppTypography.caption.copyWith(color: AppColors.gray400)),
                ],
              ),
            ),
            const Divider(color: AppColors.gray800, height: 1),
            const SizedBox(height: AppSpacing.sm),
            ...AdminSidebar._items.map((item) {
              final selected = currentRoute.startsWith(item.route);
              return _SidebarTile(item: item, selected: selected);
            }),
            const Spacer(),
            const Divider(color: AppColors.gray800, height: 1),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.gray400, size: 20),
              title: Text('Déconnexion',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.gray400)),
              onTap: () => ref.read(sessionProvider.notifier).logout(),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;
  const _NavItem(this.icon, this.label, this.route);
}

class _SidebarTile extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  const _SidebarTile({required this.item, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: selected ? AppColors.violet.withValues(alpha: 0.15) : null,
        borderRadius: AppRadius.smRadius,
      ),
      child: ListTile(
        leading: Icon(item.icon,
            color: selected ? AppColors.violet : AppColors.gray400, size: 20),
        title: Text(
          item.label,
          style: AppTypography.bodyMedium.copyWith(
            color: selected ? AppColors.white : AppColors.gray400,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        onTap: () => context.go(item.route),
        dense: true,
      ),
    );
  }
}
EOF
echo "→ lib/features/admin/presentation/widgets/admin_sidebar.dart créé."

cat > lib/features/admin/presentation/screens/admin_shell_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import '../widgets/admin_sidebar.dart';

/// Écran coquille du panel Admin.
///
/// Sur le web (ou écran large), affiche une sidebar fixe à gauche et
/// le contenu à droite. Sur mobile, la sidebar devient un Drawer
/// accessible via le bouton menu de l'AppBar — la même codebase
/// fonctionne sur les deux contextes sans duplication.
class AdminShellScreen extends StatelessWidget {
  final Widget child;
  const AdminShellScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isWide = kIsWeb || MediaQuery.of(context).size.width > 800;
    final currentRoute = GoRouterState.of(context).matchedLocation;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            AdminSidebar(currentRoute: currentRoute),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration'),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(child: AdminSidebar(currentRoute: currentRoute)),
      body: child,
    );
  }
}
EOF
echo "→ lib/features/admin/presentation/screens/admin_shell_screen.dart créé."

cat > lib/features/admin/presentation/screens/admin_dashboard_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/enums/product_status.dart';
import '../../providers/admin_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final produitsAsync = ref.watch(allProductsAdminProvider);
    final usersAsync = ref.watch(allUsersAdminProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tableau de bord', style: AppTypography.displayMedium),
            const SizedBox(height: AppSpacing.xxl),
            produitsAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Erreur de chargement'),
              data: (produits) => Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  _KpiCard(
                    titre: 'Produits en vente',
                    valeur: '${produits.where((p) => p.statut == ProductStatus.enVente).length}',
                    icon: Icons.storefront_rounded,
                    couleur: AppColors.success,
                  ),
                  _KpiCard(
                    titre: 'En attente',
                    valeur: '${produits.where((p) => p.statut == ProductStatus.soumis).length}',
                    icon: Icons.pending_rounded,
                    couleur: AppColors.gold,
                  ),
                  _KpiCard(
                    titre: 'En vérification',
                    valeur: '${produits.where((p) => p.statut == ProductStatus.enVerification).length}',
                    icon: Icons.manage_search_rounded,
                    couleur: AppColors.violet,
                  ),
                  usersAsync.when(
                    loading: () => const _KpiCard(titre: 'Utilisateurs', valeur: '…', icon: Icons.people_rounded, couleur: AppColors.blue),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (users) => _KpiCard(
                      titre: 'Utilisateurs',
                      valeur: '${users.length}',
                      icon: Icons.people_rounded,
                      couleur: AppColors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String titre;
  final String valeur;
  final IconData icon;
  final Color couleur;

  const _KpiCard({
    required this.titre,
    required this.valeur,
    required this.icon,
    required this.couleur,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: couleur.withValues(alpha: 0.12),
              borderRadius: AppRadius.smRadius,
            ),
            child: Icon(icon, color: couleur, size: 22),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(valeur,
              style: AppTypography.displayMedium.copyWith(color: AppColors.black)),
          Text(titre, style: AppTypography.bodySmall),
        ],
      ),
    );
  }
}
EOF
echo "→ lib/features/admin/presentation/screens/admin_dashboard_screen.dart créé."

cat > lib/features/admin/presentation/screens/admin_catalog_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/errors/error_view.dart';
import '../../../../domain/enums/product_status.dart';
import '../../../../shared/widgets/cards/status_badge.dart';
import '../../../../shared/widgets/feedback/app_loading_indicator.dart';
import '../../../../shared/widgets/feedback/app_snackbar.dart';
import '../../providers/admin_provider.dart';

class AdminCatalogScreen extends ConsumerWidget {
  const AdminCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final produitsAsync = ref.watch(allProductsAdminProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text('Catalogue produits', style: AppTypography.displayMedium),
          ),
          Expanded(
            child: produitsAsync.when(
              loading: () => const AppLoadingIndicator(),
              error: (_, __) => ErrorView(
                message: 'Impossible de charger le catalogue.',
                onRetry: () => ref.invalidate(allProductsAdminProvider),
              ),
              data: (produits) {
                if (produits.isEmpty) {
                  return const EmptyView(message: 'Aucun produit', icon: Icons.inventory_2_outlined);
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  itemCount: produits.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final p = produits[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      title: Row(
                        children: [
                          Expanded(child: Text(p.titre, style: AppTypography.titleMedium)),
                          StatusBadge(label: p.statut.label, color: p.statut.color),
                        ],
                      ),
                      subtitle: Text(
                        '${Formatters.currency(p.prix)} · ${p.localisation} · ${Formatters.shortDate(p.dateCreation)}',
                        style: AppTypography.bodySmall,
                      ),
                      trailing: p.statut == ProductStatus.soumis || p.statut == ProductStatus.enTraitement
                          ? PopupMenuButton<String>(
                              onSelected: (action) async {
                                final notifier = ref.read(adminProductNotifierProvider.notifier);
                                if (action == 'publier') {
                                  await notifier.changerStatut(p.id, ProductStatus.enVente);
                                  if (context.mounted) AppSnackbar.showSuccess(context, 'Produit publié.');
                                } else if (action == 'refuser') {
                                  await notifier.changerStatut(p.id, ProductStatus.refuse);
                                  if (context.mounted) AppSnackbar.showInfo(context, 'Produit refusé.');
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(value: 'publier', child: Text('Publier en boutique')),
                                const PopupMenuItem(value: 'refuser', child: Text('Refuser')),
                              ],
                            )
                          : null,
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
EOF
echo "→ lib/features/admin/presentation/screens/admin_catalog_screen.dart créé."

cat > lib/features/admin/presentation/screens/admin_orders_screen.dart << 'EOF'
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
EOF
echo "→ lib/features/admin/presentation/screens/admin_orders_screen.dart créé."

cat > lib/features/admin/presentation/screens/admin_users_screen.dart << 'EOF'
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
EOF
echo "→ lib/features/admin/presentation/screens/admin_users_screen.dart créé."

# ============================================================================
# 4. MISE À JOUR DU ROUTEUR
# ============================================================================
echo "→ Mise à jour de app_router.dart pour brancher tous les nouveaux écrans..."

python3 << 'PYEOF'
path = "lib/core/router/app_router.dart"
with open(path, encoding="utf-8") as f:
    content = f.read()

new_imports = (
    "import '../../features/messages/presentation/screens/messages_screen.dart';\n"
    "import '../../features/messages/presentation/screens/conversation_screen.dart';\n"
    "import '../../features/notifications/presentation/screens/notifications_screen.dart';\n"
    "import '../../features/profile/presentation/screens/profile_screen.dart';\n"
    "import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';\n"
    "import '../../features/admin/presentation/screens/admin_catalog_screen.dart';\n"
    "import '../../features/admin/presentation/screens/admin_orders_screen.dart';\n"
    "import '../../features/admin/presentation/screens/admin_users_screen.dart';\n"
)
marker = "import '../../features/agent/presentation/screens/agent_dashboard_screen.dart';\n"
if marker not in content:
    raise SystemExit("ERREUR : marqueur d'import introuvable dans app_router.dart")
content = content.replace(marker, marker + new_imports, 1)

replacements = [
    (
        "GoRoute(\n        path: AppRoutes.messages,\n        builder: (context, state) => const PlaceholderScreen(titre: 'Messages'),\n      ),",
        "GoRoute(\n        path: AppRoutes.messages,\n        builder: (context, state) => const MessagesScreen(),\n      ),",
    ),
    (
        "GoRoute(\n        path: AppRoutes.conversation,\n        builder: (context, state) => const PlaceholderScreen(titre: 'Conversation'),\n      ),",
        "GoRoute(\n        path: AppRoutes.conversation,\n        builder: (context, state) {\n          final id = state.pathParameters['conversationId']!;\n          return ConversationScreen(conversationId: id);\n        },\n      ),",
    ),
    (
        "GoRoute(\n        path: AppRoutes.notifications,\n        builder: (context, state) => const PlaceholderScreen(titre: 'Notifications'),\n      ),",
        "GoRoute(\n        path: AppRoutes.notifications,\n        builder: (context, state) => const NotificationsScreen(),\n      ),",
    ),
    (
        "GoRoute(\n        path: AppRoutes.profile,\n        builder: (context, state) => const PlaceholderScreen(titre: 'Profil'),\n      ),",
        "GoRoute(\n        path: AppRoutes.profile,\n        builder: (context, state) => const ProfileScreen(),\n      ),",
    ),
    (
        "GoRoute(\n        path: AppRoutes.adminDashboard,\n        builder: (context, state) => const PlaceholderScreen(titre: 'Tableau de bord Admin'),\n      ),",
        "GoRoute(\n        path: AppRoutes.adminDashboard,\n        builder: (context, state) => const AdminDashboardScreen(),\n      ),",
    ),
    (
        "GoRoute(\n        path: AppRoutes.adminCatalog,\n        builder: (context, state) => const PlaceholderScreen(titre: 'Catalogue'),\n      ),",
        "GoRoute(\n        path: AppRoutes.adminCatalog,\n        builder: (context, state) => const AdminCatalogScreen(),\n      ),",
    ),
    (
        "GoRoute(\n        path: AppRoutes.adminOrders,\n        builder: (context, state) => const PlaceholderScreen(titre: 'Commandes'),\n      ),",
        "GoRoute(\n        path: AppRoutes.adminOrders,\n        builder: (context, state) => const AdminOrdersScreen(),\n      ),",
    ),
    (
        "GoRoute(\n        path: AppRoutes.adminUsers,\n        builder: (context, state) => const PlaceholderScreen(titre: 'Utilisateurs'),\n      ),",
        "GoRoute(\n        path: AppRoutes.adminUsers,\n        builder: (context, state) => const AdminUsersScreen(),\n      ),",
    ),
]

for old, new in replacements:
    if old not in content:
        raise SystemExit(f"ERREUR : bloc introuvable :\n{old[:80]}...")
    content = content.replace(old, new, 1)

with open(path, "w", encoding="utf-8") as f:
    f.write(content)
print("app_router.dart : 8 routes supplémentaires branchées.")
PYEOF

echo ""
echo "============================================================"
echo "  ✔ Script 13 terminé avec succès."
echo "============================================================"
echo ""
echo "RÉCAPITULATIF DE CE QUI A ÉTÉ CRÉÉ :"
echo "  • Providers : messages, notifications, admin (produits + users)"
echo "  • MessagesScreen, ConversationScreen"
echo "  • NotificationsScreen"
echo "  • ProfileScreen (infos, déconnexion, réinitialisation démo)"
echo "  • AdminSidebar, AdminShellScreen (responsive web/mobile)"
echo "  • AdminDashboardScreen (KPIs)"
echo "  • AdminCatalogScreen (liste + actions publier/refuser)"
echo "  • AdminOrdersScreen"
echo "  • AdminUsersScreen (liste + toggle actif/inactif)"
echo "  • 8 routes supplémentaires branchées dans app_router.dart"
echo ""
echo "PROCHAINE ÉTAPE :"
echo "  Dites-moi quand vous êtes prêt pour le script 14 (dernier) :"
echo "  la navigation inférieure (BottomNavigationBar) pour chaque"
echo "  rôle, les transitions animées, et le script de vérification"
echo "  finale qui confirme que tout le projet est complet."
echo ""
