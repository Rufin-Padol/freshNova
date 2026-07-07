/// Type de notification, déterminant l'icône et la destination au clic.
enum NotificationType {
  commande,
  produit,
  mission,
  paiement,
  litige,
  message,
  systeme;
}

/// Canal d'envoi de la notification, conforme au diagramme UML.
/// Pour l'instant seul [push] est réellement utilisé (notifications
/// locales), [sms] et [email] sont préparés pour une intégration future.
enum NotificationChannel { push, sms, email }
