import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as latlong;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';

/// Carte réelle (tuiles OpenStreetMap, sans clé API) affichant la
/// destination d'une mission et la position en direct de l'agent —
/// il peut ainsi se voir se déplacer par rapport à la cible pendant
/// son trajet, comme une vraie navigation.
class MissionMapView extends StatefulWidget {
  final double destinationLat;
  final double destinationLng;
  final String destinationLabel;

  const MissionMapView({
    super.key,
    required this.destinationLat,
    required this.destinationLng,
    required this.destinationLabel,
  });

  @override
  State<MissionMapView> createState() => _MissionMapViewState();
}

class _MissionMapViewState extends State<MissionMapView> {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionSub;
  Position? _position;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _demarrerSuiviPosition();
  }

  Future<void> _demarrerSuiviPosition() async {
    final serviceActif = await Geolocator.isLocationServiceEnabled();
    if (!serviceActif) {
      setState(() => _erreur = 'Activez la localisation pour voir votre position sur la carte.');
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() => _erreur = 'Autorisez la localisation pour voir votre position sur la carte.');
      return;
    }

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((position) {
      if (!mounted) return;
      setState(() => _position = position);
      _mapController.move(latlong.LatLng(position.latitude, position.longitude), 15);
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final destination = latlong.LatLng(widget.destinationLat, widget.destinationLng);
    final distanceMetres = _position != null
        ? Geolocator.distanceBetween(
            _position!.latitude,
            _position!.longitude,
            widget.destinationLat,
            widget.destinationLng,
          )
        : null;

    return ClipRRect(
      borderRadius: AppRadius.lgRadius,
      child: SizedBox(
        height: 220,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _position != null
                    ? latlong.LatLng(_position!.latitude, _position!.longitude)
                    : destination,
                initialZoom: 14,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.afrideal.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: destination,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_on_rounded,
                          color: AppColors.danger, size: 36),
                    ),
                    if (_position != null)
                      Marker(
                        point: latlong.LatLng(_position!.latitude, _position!.longitude),
                        width: 36,
                        height: 36,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: AppColors.blue,
                            shape: BoxShape.circle,
                            border: Border.fromBorderSide(
                              BorderSide(color: AppColors.white, width: 3),
                            ),
                          ),
                          child: const Icon(Icons.navigation_rounded,
                              color: AppColors.white, size: 16),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (distanceMetres != null)
              Positioned(
                left: AppSpacing.sm,
                bottom: AppSpacing.sm,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.black.withValues(alpha: 0.75),
                    borderRadius: AppRadius.smRadius,
                  ),
                  child: Text(
                    distanceMetres >= 1000
                        ? '${(distanceMetres / 1000).toStringAsFixed(1)} km de la cible'
                        : '${distanceMetres.toStringAsFixed(0)} m de la cible',
                    style: AppTypography.caption.copyWith(color: AppColors.white),
                  ),
                ),
              ),
            if (_erreur != null)
              Positioned(
                left: AppSpacing.sm,
                right: AppSpacing.sm,
                bottom: AppSpacing.sm,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.black.withValues(alpha: 0.75),
                    borderRadius: AppRadius.smRadius,
                  ),
                  child: Text(
                    _erreur!,
                    style: AppTypography.caption.copyWith(color: AppColors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
