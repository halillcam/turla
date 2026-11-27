/// Uygulamaya gömülü yazı tipleri (`packages/core/assets/fonts`, SIL OFL).
///
/// Fontlar `turla_core` paketinde tanımlı olduğu için aile adı `packages/turla_core/`
/// önekiyle yazılır; uygulamalar fontu internetten indirmez.
abstract final class AppFonts {
  static const String _prefix = 'packages/turla_core/';

  /// Başlıklar (Fraunces 600).
  static const String display = '${_prefix}Fraunces';

  /// Metin ve etiketler (IBM Plex Sans 400/500/600).
  static const String sans = '${_prefix}IBMPlexSans';

  /// Plaka, giriş kimliği (REH-/MUS-), bilet kodu (IBM Plex Mono 500).
  static const String mono = '${_prefix}IBMPlexMono';
}
