import 'dart:async';
import 'package:flutter/foundation.dart';

/// Permet à [GoRouter] d'écouter un [ChangeNotifier] (ex: l'état de
/// session de l'utilisateur) et de ré-évaluer automatiquement les
/// redirections lorsqu'il change (connexion, déconnexion, changement
/// de rôle...).
///
/// Sans cet outil, go_router ne se "réveillerait" pas tout seul après
/// une connexion réussie : l'utilisateur resterait bloqué sur l'écran
/// de login même si son état de session a changé en arrière-plan.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (_) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
