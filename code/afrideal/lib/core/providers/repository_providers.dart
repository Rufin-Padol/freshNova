import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../../domain/repositories/i_cart_repository.dart';
import '../../domain/repositories/i_category_repository.dart';
import '../../domain/repositories/i_dispute_repository.dart';
import '../../domain/repositories/i_favorite_repository.dart';
import '../../domain/repositories/i_message_repository.dart';
import '../../domain/repositories/i_mission_repository.dart';
import '../../domain/repositories/i_notification_repository.dart';
import '../../domain/repositories/i_order_repository.dart';
import '../../domain/repositories/i_payment_repository.dart';
import '../../domain/repositories/i_product_repository.dart';
import '../../domain/repositories/i_proprietaire_repository.dart';
import '../../domain/repositories/i_seller_request_repository.dart';
import '../../domain/repositories/i_user_repository.dart';
import '../../data/repositories/local/local_auth_repository.dart';
import '../../data/repositories/local/local_cart_repository.dart';
import '../../data/repositories/local/local_category_repository.dart';
import '../../data/repositories/local/local_dispute_repository.dart';
import '../../data/repositories/local/local_favorite_repository.dart';
import '../../data/repositories/local/local_message_repository.dart';
import '../../data/repositories/local/local_mission_repository.dart';
import '../../data/repositories/local/local_notification_repository.dart';
import '../../data/repositories/local/local_order_repository.dart';
import '../../data/repositories/local/local_payment_repository.dart';
import '../../data/repositories/local/local_product_repository.dart';
import '../../data/repositories/local/local_proprietaire_repository.dart';
import '../../data/repositories/local/local_seller_request_repository.dart';
import '../../data/repositories/local/local_user_repository.dart';

/// ════════════════════════════════════════════════════════════════
/// POINT D'INJECTION CENTRAL DE L'APPLICATION
/// ════════════════════════════════════════════════════════════════
///
/// Chaque provider ci-dessous retourne une IMPLÉMENTATION CONCRÈTE
/// d'une interface du domaine, choisie selon AppConfig.dataMode.
///
/// RÈGLE D'OR : tout le reste de l'application (providers de feature,
/// écrans) ne doit JAMAIS importer directement une classe
/// "Local...Repository" ou "Api...Repository". Il doit toujours
/// passer par ces providers, en utilisant le TYPE D'INTERFACE
/// (ex: ref.watch(productRepositoryProvider) retourne un
/// IProductRepository, jamais explicitement un LocalProductRepository).
///
/// C'est cette unique règle qui permet de basculer l'intégralité de
/// l'application vers l'API en ne modifiant QUE ce fichier.

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  if (AppConfig.isLocal) {
    return LocalAuthRepository();
  }
  throw UnimplementedError(
    'ApiAuthRepository sera branché au script 09. '
    'Passez AppConfig.dataMode à DataMode.local en attendant.',
  );
});

final productRepositoryProvider = Provider<IProductRepository>((ref) {
  if (AppConfig.isLocal) {
    return LocalProductRepository();
  }
  throw UnimplementedError('ApiProductRepository sera branché au script 09.');
});

final orderRepositoryProvider = Provider<IOrderRepository>((ref) {
  if (AppConfig.isLocal) {
    return LocalOrderRepository();
  }
  throw UnimplementedError('ApiOrderRepository sera branché au script 09.');
});

final paymentRepositoryProvider = Provider<IPaymentRepository>((ref) {
  if (AppConfig.isLocal) {
    return LocalPaymentRepository();
  }
  throw UnimplementedError('ApiPaymentRepository sera branché au script 09.');
});

final sellerRequestRepositoryProvider = Provider<ISellerRequestRepository>((ref) {
  if (AppConfig.isLocal) {
    return LocalSellerRequestRepository();
  }
  throw UnimplementedError('ApiSellerRequestRepository sera branché au script 09.');
});

final missionRepositoryProvider = Provider<IMissionRepository>((ref) {
  if (AppConfig.isLocal) {
    return LocalMissionRepository();
  }
  throw UnimplementedError('ApiMissionRepository sera branché au script 09.');
});

final disputeRepositoryProvider = Provider<IDisputeRepository>((ref) {
  if (AppConfig.isLocal) {
    return LocalDisputeRepository();
  }
  throw UnimplementedError('ApiDisputeRepository sera branché au script 09.');
});

final notificationRepositoryProvider = Provider<INotificationRepository>((ref) {
  if (AppConfig.isLocal) {
    return LocalNotificationRepository();
  }
  throw UnimplementedError('ApiNotificationRepository sera branché au script 09.');
});

final messageRepositoryProvider = Provider<IMessageRepository>((ref) {
  if (AppConfig.isLocal) {
    return LocalMessageRepository();
  }
  throw UnimplementedError('ApiMessageRepository sera branché au script 09.');
});

final categoryRepositoryProvider = Provider<ICategoryRepository>((ref) {
  if (AppConfig.isLocal) {
    return LocalCategoryRepository();
  }
  throw UnimplementedError('ApiCategoryRepository sera branché au script 09.');
});

final favoriteRepositoryProvider = Provider<IFavoriteRepository>((ref) {
  if (AppConfig.isLocal) {
    return LocalFavoriteRepository();
  }
  throw UnimplementedError('ApiFavoriteRepository sera branché au script 09.');
});

final cartRepositoryProvider = Provider<ICartRepository>((ref) {
  if (AppConfig.isLocal) {
    return LocalCartRepository();
  }
  throw UnimplementedError('ApiCartRepository sera branché au script 09.');
});

final userRepositoryProvider = Provider<IUserRepository>((ref) {
  if (AppConfig.isLocal) {
    return LocalUserRepository();
  }
  throw UnimplementedError('ApiUserRepository sera branché au script 09.');
});

final proprietaireRepositoryProvider = Provider<IProprietaireRepository>((ref) {
  if (AppConfig.isLocal) {
    return LocalProprietaireRepository();
  }
  throw UnimplementedError('ApiProprietaireRepository sera branché au script 09.');
});
