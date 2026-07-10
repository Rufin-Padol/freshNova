import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/errors/error_view.dart';
import '../../../../domain/entities/demande_vendeur.dart';
import '../../../../domain/enums/product_status.dart';
import '../../../../domain/enums/seller_request_status.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/cards/info_row.dart';
import '../../../../shared/widgets/feedback/app_loading_indicator.dart';
import '../../../../shared/widgets/feedback/app_snackbar.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/layout/progress_steps.dart';
import '../../../agent/providers/agent_provider.dart';
import '../../providers/sell_provider.dart';

const _etapes = ['Soumise', 'Agent assigné', 'Collectée', 'En traitement', 'En vente'];

Uint8List _decodeDataUrl(String dataUrl) => base64Decode(dataUrl.split(',').last);

Future<String?> _capturerPhoto(ImageSource source) async {
  try {
    final xfile = await ImagePicker().pickImage(source: source, imageQuality: 70);
    if (xfile == null) return null;
    final bytes = await xfile.readAsBytes();
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  } catch (_) {
    return null;
  }
}

final _demandeDetailProvider =
    FutureProvider.family<DemandeVendeur?, String>((ref, requestId) async {
  final repo = ref.watch(sellerRequestRepositoryProvider);
  return repo.getById(requestId);
});

/// Suivi visuel de la progression d'une demande vendeur — du dépôt de
/// la demande jusqu'à la mise en vente effective du produit. Tant
/// qu'aucun agent n'est encore assigné, le vendeur peut aussi modifier
/// sa demande directement ici (voir _ouvrirEdition).
class SellRequestDetailScreen extends ConsumerWidget {
  final String requestId;
  const SellRequestDetailScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demandeAsync = ref.watch(_demandeDetailProvider(requestId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Suivi de ma demande'),
        actions: [
          demandeAsync.maybeWhen(
            data: (demande) {
              if (demande == null || demande.missionId != null) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Modifier ma demande',
                onPressed: () => _ouvrirEdition(context, ref, demande),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: demandeAsync.when(
        loading: () => const AppLoadingIndicator(),
        error: (_, __) => const ErrorView(message: 'Impossible de charger cette demande.'),
        data: (demande) {
          if (demande == null) {
            return const ErrorView(message: 'Demande introuvable.');
          }
          return _Contenu(demande: demande);
        },
      ),
    );
  }

  void _ouvrirEdition(BuildContext context, WidgetRef ref, DemandeVendeur demande) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.xlRadius),
      builder: (_) => _EditionDemandeSheet(demande: demande, requestId: requestId),
    );
  }
}

class _Contenu extends ConsumerWidget {
  final DemandeVendeur demande;
  const _Contenu({required this.demande});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estException = demande.statut == SellerRequestStatus.refusee;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(demande.typeProduitSouhaite, style: AppTypography.displayMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${Formatters.currency(demande.prixSouhaite)} souhaité · '
            '${Formatters.shortDate(demande.dateCreation)}',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xxl),
          if (estException)
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
                      Text('Demande refusée',
                          style: AppTypography.titleMedium.copyWith(color: AppColors.danger)),
                    ],
                  ),
                  if (demande.raisonRefus != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(demande.raisonRefus!, style: AppTypography.bodySmall),
                  ],
                ],
              ),
            )
          else if (demande.missionId == null)
            ProgressSteps(steps: _etapes, currentIndex: 0)
          else
            Consumer(
              builder: (context, ref, _) {
                final produitAsync = ref.watch(produitDeMissionProvider(demande.missionId!));
                return produitAsync.when(
                  loading: () => ProgressSteps(steps: _etapes, currentIndex: 1),
                  error: (_, __) => ProgressSteps(steps: _etapes, currentIndex: 1),
                  data: (produit) =>
                      ProgressSteps(steps: _etapes, currentIndex: _indexPour(produit?.statut)),
                );
              },
            ),
          const SizedBox(height: AppSpacing.xxl),
          if (demande.photos.isNotEmpty) ...[
            Text('Photos', style: AppTypography.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final photo in demande.photos)
                  ClipRRect(
                    borderRadius: AppRadius.mdRadius,
                    child: Image.memory(
                      _decodeDataUrl(photo),
                      height: 110,
                      width: 110,
                      fit: BoxFit.cover,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
          Text('Description', style: AppTypography.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(demande.descriptionInitiale, style: AppTypography.bodyLarge),
          const SizedBox(height: AppSpacing.xxl),
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
                  icon: Icons.sell_outlined,
                  label: 'Prix souhaité',
                  value: Formatters.currency(demande.prixSouhaite),
                ),
                const Divider(height: AppSpacing.xl),
                InfoRow(
                  icon: Icons.inventory_2_outlined,
                  label: 'Quantité',
                  value: '${demande.quantite}',
                ),
                const Divider(height: AppSpacing.xl),
                InfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Adresse',
                  value: demande.adresse,
                ),
                const Divider(height: AppSpacing.xl),
                InfoRow(
                  icon: Icons.map_outlined,
                  label: 'Zone',
                  value: demande.zone,
                ),
                const Divider(height: AppSpacing.xl),
                InfoRow(
                  icon: Icons.schedule_outlined,
                  label: 'Disponibilité',
                  value: demande.disponibilite,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _indexPour(ProductStatus? statut) {
    if (statut == null) return 1;
    switch (statut) {
      case ProductStatus.soumis:
      case ProductStatus.missionAssignee:
      case ProductStatus.enVerification:
        return 1;
      case ProductStatus.collecte:
        return 2;
      case ProductStatus.enTraitement:
        return 3;
      case ProductStatus.enVente:
      case ProductStatus.reserve:
      case ProductStatus.enLivraison:
      case ProductStatus.livre:
        return 4;
      default:
        return 1;
    }
  }
}

/// Formulaire de modification d'une demande vendeur, disponible tant
/// qu'aucun agent n'est encore assigné (au-delà, la fiche est déjà
/// prise en charge sur le terrain et ne peut plus être changée ici).
class _EditionDemandeSheet extends ConsumerStatefulWidget {
  final DemandeVendeur demande;
  final String requestId;

  const _EditionDemandeSheet({required this.demande, required this.requestId});

  @override
  ConsumerState<_EditionDemandeSheet> createState() => _EditionDemandeSheetState();
}

class _EditionDemandeSheetState extends ConsumerState<_EditionDemandeSheet> {
  late final TextEditingController _typeCtrl;
  late final TextEditingController _prixCtrl;
  late final TextEditingController _quantiteCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _adresseCtrl;
  late final TextEditingController _zoneCtrl;
  late final TextEditingController _disponibiliteCtrl;
  late List<String> _photos;
  bool _enCours = false;

  @override
  void initState() {
    super.initState();
    final d = widget.demande;
    _typeCtrl = TextEditingController(text: d.typeProduitSouhaite);
    _prixCtrl = TextEditingController(text: d.prixSouhaite.toStringAsFixed(0));
    _quantiteCtrl = TextEditingController(text: '${d.quantite}');
    _descriptionCtrl = TextEditingController(text: d.descriptionInitiale);
    _adresseCtrl = TextEditingController(text: d.adresse);
    _zoneCtrl = TextEditingController(text: d.zone);
    _disponibiliteCtrl = TextEditingController(text: d.disponibilite);
    _photos = [...d.photos];
  }

  @override
  void dispose() {
    _typeCtrl.dispose();
    _prixCtrl.dispose();
    _quantiteCtrl.dispose();
    _descriptionCtrl.dispose();
    _adresseCtrl.dispose();
    _zoneCtrl.dispose();
    _disponibiliteCtrl.dispose();
    super.dispose();
  }

  Future<void> _ajouterPhoto() async {
    if (_photos.length >= AppConstants.maxSellerPreviewPhotos) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choisir depuis la galerie'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final dataUrl = await _capturerPhoto(source);
    if (dataUrl != null) setState(() => _photos.add(dataUrl));
  }

  Future<void> _enregistrer() async {
    if (_typeCtrl.text.trim().isEmpty ||
        _adresseCtrl.text.trim().isEmpty ||
        _disponibiliteCtrl.text.trim().isEmpty) {
      AppSnackbar.showError(context, 'Le produit, l\'adresse et la disponibilité sont obligatoires.');
      return;
    }
    final prix = double.tryParse(_prixCtrl.text.replaceAll(' ', ''));
    if (prix == null || prix <= 0) {
      AppSnackbar.showError(context, 'Indiquez un prix valide.');
      return;
    }
    final quantite = int.tryParse(_quantiteCtrl.text.trim());
    if (quantite == null || quantite <= 0) {
      AppSnackbar.showError(context, 'Indiquez une quantité valide.');
      return;
    }
    if (_photos.length < AppConstants.minSellerPreviewPhotos) {
      AppSnackbar.showError(
        context,
        'Gardez au moins ${AppConstants.minSellerPreviewPhotos} photos.',
      );
      return;
    }

    setState(() => _enCours = true);

    final demandeMiseAJour = widget.demande.copyWith(
      typeProduitSouhaite: _typeCtrl.text.trim(),
      prixSouhaite: prix,
      quantite: quantite,
      descriptionInitiale: _descriptionCtrl.text.trim(),
      adresse: _adresseCtrl.text.trim(),
      zone: _zoneCtrl.text.trim().isEmpty ? 'Non précisée' : _zoneCtrl.text.trim(),
      disponibilite: _disponibiliteCtrl.text.trim(),
      photos: _photos,
    );

    await ref.read(sellerRequestRepositoryProvider).save(demandeMiseAJour);
    ref.invalidate(_demandeDetailProvider(widget.requestId));
    ref.invalidate(mySellerRequestsProvider);

    if (mounted) {
      Navigator.of(context).pop();
      AppSnackbar.showSuccess(context, 'Demande mise à jour.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Modifier ma demande', style: AppTypography.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(label: 'Produit', controller: _typeCtrl),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Prix souhaité (FCFA)',
                    controller: _prixCtrl,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppTextField(
                    label: 'Quantité',
                    controller: _quantiteCtrl,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(label: 'Description', controller: _descriptionCtrl, maxLines: 4),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(label: 'Adresse de collecte', controller: _adresseCtrl),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(label: 'Zone', controller: _zoneCtrl),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(label: 'Disponibilité', controller: _disponibiliteCtrl),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Photos '
              '(${AppConstants.minSellerPreviewPhotos} min. — ${AppConstants.maxSellerPreviewPhotos} max.)',
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (var i = 0; i < _photos.length; i++)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: AppRadius.smRadius,
                        child: Image.memory(
                          _decodeDataUrl(_photos[i]),
                          height: 80,
                          width: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: -6,
                        right: -6,
                        child: GestureDetector(
                          onTap: () => setState(() => _photos.removeAt(i)),
                          child: const CircleAvatar(
                            radius: 11,
                            backgroundColor: AppColors.danger,
                            child: Icon(Icons.close_rounded, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                if (_photos.length < AppConstants.maxSellerPreviewPhotos)
                  InkWell(
                    onTap: _ajouterPhoto,
                    borderRadius: AppRadius.smRadius,
                    child: Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        color: AppColors.violetSurface,
                        borderRadius: AppRadius.smRadius,
                        border: Border.all(color: AppColors.violet),
                      ),
                      child: const Icon(Icons.add_a_photo_outlined, color: AppColors.violet),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            AppPrimaryButton(
              label: 'Enregistrer',
              isLoading: _enCours,
              onPressed: _enCours ? null : _enregistrer,
            ),
          ],
        ),
      ),
    );
  }
}
