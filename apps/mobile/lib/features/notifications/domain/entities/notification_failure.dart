/// Bildirim işlemlerinin hata türleri.
enum NotificationFailureReason { network, notSignedIn, unknown }

class NotificationFailure implements Exception {
  const NotificationFailure(this.reason, [this.cause]);

  final NotificationFailureReason reason;
  final Object? cause;

  @override
  String toString() => 'NotificationFailure($reason, $cause)';
}
