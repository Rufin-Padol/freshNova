import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/entities/mission.dart';
import '../../../../domain/entities/photo.dart';
import '../../../../domain/entities/produit.dart';
import '../../../../domain/entities/proprietaire.dart';
import '../../../../domain/enums/photo_type.dart';
import '../../../../domain/enums/product_status.dart';
import '../../../../domain/enums/proof_type.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/feedback/app_snackbar.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../shop/providers/category_provider.dart';
import '../../providers/agent_provider.dart';
import '../../providers/proprietaire_provider.dart';
import 'proprietaire_selector_sheet.dart';

const _uuid = Uuid();
const _photosMinimum = 4;

Uint8List _decodeDataUrl(String dataUrl) => base64Decode(dataUrl.split(',').last);

/// Formulaire complet rempli par l'agent sur place pour transformer le
/// produit brouillon en fiche complète : propriétaire, preuve de
/// propriété, photos officielles, dimensions, état réel, défauts,
/// prix confirmé. C'est ce contenu que l'admin relira et publiera
/// ensuite (voir AdminProductEditScreen) — l'agent, lui, crée
/// vraiment la fiche.
class MissionCollecteForm extends ConsumerStatefulWidget {
  final Mission mission;
  final Produit produitBrouillon;

  const MissionCollecteForm({
    super.key,
    required this.mission,
    required this.produitBrouillon,
  });

  @override
  ConsumerState<MissionCollecteForm> createState() => _MissionCollecteFormState();
}

class _MissionCollecteFormState extends ConsumerState<MissionCollecteForm> {
  late final TextEditingController _titreCtrl;
  late final TextEditingController _dimensionsCtrl;
  late final TextEditingController _defautsCtrl;
  late final TextEditingController _prixCtrl;
  final _preuveTexteCtrl = TextEditingController();

  Proprietaire? _proprietaire;
  bool _proprietaireInitTente = false;
  ProofType? _preuveType;
  String? _preuveImageDataUrl;
  final List<Photo> _photos = [];
  late String _categorieId;
  ProductCondition? _etat;
  bool _enCours = false;

  /// null = pas encore répondu, true = "aucun défaut", false =
  /// "défauts constatés" (voir _defautsCtrl pour le détail).
  bool? _aucunDefaut;

  @override
  void initState() {
    super.initState();
    final p = widget.produitBrouillon;
    _titreCtrl = TextEditingController(text: p.titre);
    _dimensionsCtrl = TextEditingController();
    _defautsCtrl = TextEditingController();
    _prixCtrl = TextEditingController(text: p.prix.toStringAsFixed(0));
    _categorieId = p.categorieId;
  }

  @override
  void dispose() {
    _titreCtrl.dispose();
    _dimensionsCtrl.dispose();
    _defautsCtrl.dispose();
    _prixCtrl.dispose();
    _preuveTexteCtrl.dispose();
    super.dispose();
  }

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

  Future<void> _choisirSource(Future<void> Function(ImageSource) onChoix) async {
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
    if (source != null) await onChoix(source);
  }

  Future<void> _ajouterPhotoProduit() async {
    await _choisirSource((source) async {
      final dataUrl = await _capturerPhoto(source);
      if (dataUrl == null) return;
      String? geoloc;
      try {
        final position = await Geolocator.getCurrentPosition();
        geoloc = '${position.latitude},${position.longitude}';
      } catch (_) {
        // Position indisponible : la photo reste valable sans geoloc.
      }
      setState(() {
        _photos.add(Photo(
          id: _uuid.v4(),
          url: dataUrl,
          type: PhotoType.officielleAgent,
          estOfficielle: true,
          horodatage: DateTime.now(),
          geoloc: geoloc,
        ));
      });
    });
  }

  Future<void> _capturerPreuveImage() async {
    await _choisirSource((source) async {
      final dataUrl = await _capturerPhoto(source);
      if (dataUrl != null) setState(() => _preuveImageDataUrl = dataUrl);
    });
  }

  Future<void> _selectionnerProprietaire() async {
    final proprietaire = await showProprietaireSelector(context);
    if (proprietaire != null) setState(() => _proprietaire = proprietaire);
  }

  bool get _formulaireValide {
    if (_proprietaire == null) return false;
    if (_preuveType == ProofType.image && _preuveImageDataUrl == null) return false;
    if (_preuveType == ProofType.texte && _preuveTexteCtrl.text.trim().isEmpty) return false;
    if (_preuveType == null) return false;
    if (_photos.length < _photosMinimum) return false;
    if (_titreCtrl.text.trim().isEmpty) return false;
    if (_etat == null) return false;
    // Le constat de défauts n'est pas optionnel : l'agent doit
    // explicitement confirmer qu'il n'y a rien à signaler, plutôt que
    // de simplement laisser le champ vide. C'est nous qui garantissons
    // le produit à l'acheteur, un défaut non mentionné ici ne sera
    // jamais découvert ailleurs.
    if (_aucunDefaut == null) return false;
    if (_aucunDefaut == false && _defautsCtrl.text.trim().isEmpty) return false;
    final prix = double.tryParse(_prixCtrl.text.replaceAll(' ', ''));
    if (prix == null || prix <= 0) return false;
    return true;
  }

  Future<void> _valider() async {
    if (!_formulaireValide) {
      AppSnackbar.showError(
        context,
        'Complétez tous les champs obligatoires (propriétaire, preuve, '
        'au moins $_photosMinimum photos, état, constat de défauts, prix).',
      );
      return;
    }

    setState(() => _enCours = true);

    final preuveValeur =
        _preuveType == ProofType.image ? _preuveImageDataUrl! : _preuveTexteCtrl.text.trim();
    final prix = double.parse(_prixCtrl.text.replaceAll(' ', ''));

    await ref.read(agentMissionNotifierProvider.notifier).validerCollecteComplete(
          widget.mission,
          proprietaireId: _proprietaire!.id,
          preuveType: _preuveType!,
          preuveValeur: preuveValeur,
          photosOfficielles: _photos,
          titre: _titreCtrl.text.trim(),
          categorieId: _categorieId,
          dimensions: _dimensionsCtrl.text.trim().isEmpty ? null : _dimensionsCtrl.text.trim(),
          etat: _etat!,
          defautsConnus: _aucunDefaut == true ? null : _defautsCtrl.text.trim(),
          prixConfirme: prix,
        );

    if (mounted) {
      setState(() => _enCours = false);
      AppSnackbar.showSuccess(context, 'Collecte validée ! Le produit part en relecture admin.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    // Pré-remplit le propriétaire depuis celui déjà résolu à
    // l'assignation (compte vendeur) — l'agent n'a plus qu'à confirmer
    // ou corriger via le sélecteur si la personne présente diffère.
    final proprietaireBrouillonId = widget.produitBrouillon.proprietaireId;
    if (_proprietaire == null && !_proprietaireInitTente && proprietaireBrouillonId != null) {
      final proprietaireAsync = ref.watch(proprietaireByIdProvider(proprietaireBrouillonId));
      proprietaireAsync.whenData((p) {
        if (p != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _proprietaire = p);
          });
        }
      });
      _proprietaireInitTente = true;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fiche produit à compléter sur place', style: AppTypography.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Ces informations remplacent le formulaire papier — l\'admin ne fera '
          'que relire et publier ensuite.',
          style: AppTypography.bodySmall,
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── Propriétaire ──
        Text('Propriétaire du bien *', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        InkWell(
          onTap: _selectionnerProprietaire,
          borderRadius: AppRadius.mdRadius,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.mdRadius,
              border: Border.all(
                color: _proprietaire != null ? AppColors.violet : AppColors.gray200,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.person_outline_rounded,
                    color: _proprietaire != null ? AppColors.violet : AppColors.gray400),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _proprietaire != null
                        ? '${_proprietaire!.nom} · ${_proprietaire!.telephone}'
                        : 'Rechercher ou créer un propriétaire',
                    style: AppTypography.bodyMedium,
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.gray400),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── Preuve de propriété ──
        Text('Preuve de propriété *', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            ChoiceChip(
              label: const Text('Photo'),
              selected: _preuveType == ProofType.image,
              onSelected: (_) => setState(() => _preuveType = ProofType.image),
            ),
            const SizedBox(width: AppSpacing.sm),
            ChoiceChip(
              label: const Text('Texte'),
              selected: _preuveType == ProofType.texte,
              onSelected: (_) => setState(() => _preuveType = ProofType.texte),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_preuveType == ProofType.image)
          _preuveImageDataUrl != null
              ? ClipRRect(
                  borderRadius: AppRadius.smRadius,
                  child: Image.memory(_decodeDataUrl(_preuveImageDataUrl!),
                      height: 100, width: 100, fit: BoxFit.cover),
                )
              : OutlinedButton.icon(
                  onPressed: _capturerPreuveImage,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Photographier la preuve'),
                ),
        if (_preuveType == ProofType.texte)
          AppTextField(
            hint: 'Ex : numéro de facture, référence CNI...',
            controller: _preuveTexteCtrl,
            maxLines: 2,
          ),
        const SizedBox(height: AppSpacing.lg),

        // ── Photos officielles ──
        Text('Photos officielles du produit * (min. $_photosMinimum)',
            style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final photo in _photos)
              ClipRRect(
                borderRadius: AppRadius.smRadius,
                child: Image.memory(_decodeDataUrl(photo.url),
                    height: 72, width: 72, fit: BoxFit.cover),
              ),
            InkWell(
              onTap: _ajouterPhotoProduit,
              borderRadius: AppRadius.smRadius,
              child: Container(
                height: 72,
                width: 72,
                decoration: BoxDecoration(
                  color: AppColors.violetSurface,
                  borderRadius: AppRadius.smRadius,
                  border: Border.all(color: AppColors.violet, style: BorderStyle.solid),
                ),
                child: const Icon(Icons.add_a_photo_outlined, color: AppColors.violet),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── Confirmation produit ──
        AppTextField(label: 'Titre du produit', controller: _titreCtrl),
        const SizedBox(height: AppSpacing.md),
        Text('Catégorie', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        categoriesAsync.when(
          loading: () => const SizedBox(height: 32),
          error: (_, __) => const SizedBox.shrink(),
          data: (cats) => Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: cats.map((cat) {
              final sel = _categorieId == cat.id;
              return ChoiceChip(
                label: Text(cat.nom),
                selected: sel,
                onSelected: (_) => setState(() => _categorieId = cat.id),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'Dimensions (optionnel)',
          hint: 'Ex : 120x60x75 cm',
          controller: _dimensionsCtrl,
        ),
        const SizedBox(height: AppSpacing.md),
        Text('État réel constaté *', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: ProductCondition.values.map((c) {
            final sel = _etat == c;
            return ChoiceChip(
              label: Text(c.label),
              selected: sel,
              onSelected: (_) => setState(() => _etat = c),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Défauts constatés *', style: AppTypography.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Obligatoire : un défaut non mentionné ici ne sera jamais repéré ailleurs.',
          style: AppTypography.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            ChoiceChip(
              label: const Text('Aucun défaut constaté'),
              selected: _aucunDefaut == true,
              onSelected: (_) => setState(() => _aucunDefaut = true),
            ),
            ChoiceChip(
              label: const Text('Défauts constatés'),
              selected: _aucunDefaut == false,
              onSelected: (_) => setState(() => _aucunDefaut = false),
            ),
          ],
        ),
        if (_aucunDefaut == false) ...[
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Description des défauts',
            hint: 'Ex : petite rayure sur le côté gauche',
            controller: _defautsCtrl,
            maxLines: 2,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'Prix confirmé (FCFA)',
          controller: _prixCtrl,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: AppSpacing.xl),
        AppPrimaryButton(
          label: 'Valider la collecte',
          icon: Icons.check_circle_outline_rounded,
          isLoading: _enCours,
          onPressed: _enCours ? null : _valider,
        ),
      ],
    );
  }
}
