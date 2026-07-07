/// Type de preuve de propriété capturée par l'agent lors de la
/// vérification sur place (pièce d'identité + justificatif, conforme
/// au cahier des charges).
enum ProofType {
  image,
  texte;

  String get label => this == ProofType.image ? 'Photo' : 'Texte';
}
