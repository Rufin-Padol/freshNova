import 'package:equatable/equatable.dart';
import '../enums/photo_type.dart';

/// Entité métier Photo, conforme au diagramme UML.
///
/// Le champ [url] contient, selon le contexte :
///   - en mode local sur mobile : un chemin de fichier local
///     (ex: /data/user/0/.../image123.jpg)
///   - en mode local sur web : une URL de données en mémoire (blob)
///   - en mode API : une URL HTTP réelle pointant vers le serveur
/// Cette ambiguïté volontaire est gérée par le widget d'affichage
/// d'image partagé (voir lib/shared/widgets), qui sait choisir la
/// bonne méthode de chargement selon la plateforme et le mode.
class Photo extends Equatable {
  final String id;
  final String url;
  final PhotoType type;
  final bool estOfficielle;
  final DateTime horodatage;
  final String? geoloc;

  const Photo({
    required this.id,
    required this.url,
    required this.type,
    required this.horodatage,
    this.estOfficielle = false,
    this.geoloc,
  });

  Photo copyWith({
    String? id,
    String? url,
    PhotoType? type,
    bool? estOfficielle,
    DateTime? horodatage,
    String? geoloc,
  }) {
    return Photo(
      id: id ?? this.id,
      url: url ?? this.url,
      type: type ?? this.type,
      estOfficielle: estOfficielle ?? this.estOfficielle,
      horodatage: horodatage ?? this.horodatage,
      geoloc: geoloc ?? this.geoloc,
    );
  }

  @override
  List<Object?> get props => [id, url, type, estOfficielle, horodatage, geoloc];
}
