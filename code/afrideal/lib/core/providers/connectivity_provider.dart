import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Expose l'état de connexion réseau en continu (Stream), pour
/// afficher un indicateur "Hors-ligne" cohérent dans toute
/// l'application. Particulièrement utile pour préparer la transition
/// vers le mode API : en mode local, le réseau n'est jamais
/// indispensable, mais on veut déjà avoir l'infrastructure prête.
final connectivityStreamProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

/// Raccourci pratique : true si l'appareil a une connexion active
/// (Wi-Fi ou données mobiles), false sinon. Pendant le chargement
/// initial de l'état, considéré comme connecté par défaut pour ne
/// pas afficher un bandeau "Hors-ligne" qui clignote au démarrage.
final isOnlineProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityStreamProvider);
  return connectivity.when(
    data: (results) => !results.contains(ConnectivityResult.none),
    loading: () => true,
    error: (_, __) => true,
  );
});
