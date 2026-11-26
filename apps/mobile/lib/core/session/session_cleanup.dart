/// Çıkış sırasında yapılacak temizlik (paylaşılan telefonda önceki hesabın verisi kalmasın).
abstract interface class SessionCleanup {
  /// Oturum hâlâ açıkken (sunucuya istek gerekiyorsa, ör. push token'ını silmek).
  Future<void> beforeSignOut(String userId);

  /// Oturum kapandıktan sonra (cihazdaki önbellekler).
  Future<void> afterSignOut(String userId);
}
