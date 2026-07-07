import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as latlong;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';

/// Carte réelle (OpenStreetMap) permettant au vendeur de placer un
/// repère sur sa position exacte, en complément de l'adresse texte —
/// c'est ce point qui guidera l'agent terrain lors de la collecte.
class LocationPickerMap extends StatefulWidget {
  final double? latitudeInitiale;
  final double? longitudeInitiale;
  final void Function(double latitude, double longitude) onPositionChoisie;

  const LocationPickerMap({
    super.key,
    required this.onPositionChoisie,
    this.latitudeInitiale,
    this.longitudeInitiale,
  });

  @override
  State<LocationPickerMap> createState() => _LocationPickerMapState();
}

class _LocationPickerMapState extends State<LocationPickerMap> {
  static const _centreParDefaut = latlong.LatLng(4.0511, 9.7679); // Douala

  late final MapController _mapController;
  latlong.LatLng? _pointChoisi;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    if (widget.latitudeInitiale != null && widget.longitudeInitiale != null) {
      _pointChoisi = latlong.LatLng(widget.latitudeInitiale!, widget.longitudeInitiale!);
    }
  }

  Future<void> _centrerSurMaPosition() async {
    try {
      final serviceActif = await Geolocator.isLocationServiceEnabled();
      if (!serviceActif) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      final point = latlong.LatLng(position.latitude, position.longitude);
      setState(() => _pointChoisi = point);
      _mapController.move(point, 15);
      widget.onPositionChoisie(point.latitude, point.longitude);
    } catch (_) {
      // Position indisponible : le vendeur peut toujours taper sur la carte.
    }
  }

  void _onTap(TapPosition tapPosition, latlong.LatLng point) {
    setState(() => _pointChoisi = point);
    widget.onPositionChoisie(point.latitude, point.longitude);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Votre position sur la carte (optionnel)', style: AppTypography.titleMedium),
            TextButton.icon(
              onPressed: _centrerSurMaPosition,
              icon: const Icon(Icons.my_location_rounded, size: 18),
              label: const Text('Me localiser'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Tapez sur la carte pour placer un repère précis à votre position.',
          style: AppTypography.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: AppRadius.lgRadius,
          child: SizedBox(
            height: 220,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _pointChoisi ?? _centreParDefaut,
                initialZoom: 13,
                onTap: _onTap,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.afrideal.app',
                ),
                if (_pointChoisi != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _pointChoisi!,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.location_on_rounded,
                            color: AppColors.violet, size: 36),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
