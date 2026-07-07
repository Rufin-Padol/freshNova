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
