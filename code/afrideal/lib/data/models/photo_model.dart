import '../../domain/entities/photo.dart';
import '../../domain/enums/photo_type.dart';

class PhotoModel {
  final String id;
  final String url;
  final String type;
  final bool estOfficielle;
  final String horodatage;
  final String? geoloc;

  const PhotoModel({
    required this.id,
    required this.url,
    required this.type,
    required this.horodatage,
    this.estOfficielle = false,
    this.geoloc,
  });

  factory PhotoModel.fromEntity(Photo e) {
    return PhotoModel(
      id: e.id,
      url: e.url,
      type: e.type.name,
      estOfficielle: e.estOfficielle,
      horodatage: e.horodatage.toIso8601String(),
      geoloc: e.geoloc,
    );
  }

  Photo toEntity() {
    return Photo(
      id: id,
      url: url,
      type: PhotoType.values.firstWhere((t) => t.name == type),
      estOfficielle: estOfficielle,
      horodatage: DateTime.parse(horodatage),
      geoloc: geoloc,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'type': type,
        'estOfficielle': estOfficielle,
        'horodatage': horodatage,
        'geoloc': geoloc,
      };

  factory PhotoModel.fromJson(Map<String, dynamic> json) {
    return PhotoModel(
      id: json['id'] as String,
      url: json['url'] as String,
      type: json['type'] as String,
      estOfficielle: json['estOfficielle'] as bool? ?? false,
      horodatage: json['horodatage'] as String,
      geoloc: json['geoloc'] as String?,
    );
  }
}
