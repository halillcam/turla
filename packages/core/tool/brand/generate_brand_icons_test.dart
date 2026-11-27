// Turla marka ikonlarını üretir (uygulama ikonu, uyarlanabilir ikon ön planı, web ikonları).
//
// Çalıştırma (packages/core içinde):
//   flutter test tool/brand/generate_brand_icons_test.dart
//
// Gömülü Fraunces fontunu kullanır; internetten bir şey indirmez. Çıktılar:
//   apps/mobile/assets/icon/app_icon.png             (1024, tam ikon)
//   apps/mobile/assets/icon/app_icon_foreground.png  (1024, şeffaf zeminde işaret)
//   apps/web/web/favicon.png, apps/web/web/icons/*.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turla_core/turla_core.dart';

const String _fontFamily = 'BrandFraunces';
const double _canvas = 1024;
// Fraunces: height 1 satırda taban çizgisinin altında kalan pay (yazı boyutuna oran).
const double _baselineGap = 0.205;

/// "T" ve yanında küçük terracotta nokta. [scale] işaretin kutuya oranıdır.
class _Mark extends StatelessWidget {
  const _Mark({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final fontSize = _canvas * scale;
    final dot = fontSize * 0.16;
    // Satır kutusu harfin altında inen payı da tuttuğu için işaret biraz aşağı itilir.
    return Padding(
      padding: EdgeInsets.only(top: fontSize * _baselineGap * 0.9),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Noktayla dengelensin diye solda nokta kadar boşluk: işaret optik olarak ortalanır.
          SizedBox(width: dot * 0.7),
          Text(
            'T',
            style: TextStyle(
              fontFamily: _fontFamily,
              fontSize: fontSize,
              height: 1,
              fontWeight: FontWeight.w600,
              color: AppColors.background,
            ),
          ),
          SizedBox(width: dot * 0.35),
          Padding(
            // Satır kutusunun altındaki inen boşluk kadar yukarı: nokta harfin tabanına oturur.
            padding: EdgeInsets.only(bottom: fontSize * _baselineGap),
            child: Container(
              width: dot,
              height: dot,
              decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tam ikon: çam yeşili yuvarlak kare + işaret. [rounded] false ise kare (maskelenebilir).
class _FullIcon extends StatelessWidget {
  const _FullIcon({required this.rounded, required this.scale});

  final bool rounded;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _canvas,
      height: _canvas,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: rounded ? BorderRadius.circular(_canvas * 0.22) : null,
      ),
      alignment: Alignment.center,
      child: _Mark(scale: scale),
    );
  }
}

Future<void> _render(WidgetTester tester, Widget child, List<(String, int)> outputs) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: RepaintBoundary(
          key: key,
          child: SizedBox(width: _canvas, height: _canvas, child: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  for (final (path, size) in outputs) {
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: size / _canvas);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File(path)..createSync(recursive: true);
      file.writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }
}

void main() {
  const root = '../..';

  setUpAll(() async {
    final bytes = File('assets/fonts/fraunces/Fraunces-SemiBold.ttf').readAsBytesSync();
    final loader = FontLoader(_fontFamily)..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  });

  testWidgets('marka ikonları üretilir', (tester) async {
    tester.view.physicalSize = const Size(_canvas, _canvas);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // Mobil: launcher ikonu (yuvarlak köşeli, eski Android ve genel kullanım).
    await _render(tester, const _FullIcon(rounded: true, scale: 0.62), [
      ('$root/apps/mobile/assets/icon/app_icon.png', 1024),
      ('$root/apps/web/web/icons/Icon-192.png', 192),
      ('$root/apps/web/web/icons/Icon-512.png', 512),
      ('$root/apps/web/web/favicon.png', 64),
    ]);

    // Web: maskelenebilir ikon (tam kare, işaret güvenli alanda).
    await _render(tester, const _FullIcon(rounded: false, scale: 0.46), [
      ('$root/apps/web/web/icons/Icon-maskable-192.png', 192),
      ('$root/apps/web/web/icons/Icon-maskable-512.png', 512),
    ]);

    // Android uyarlanabilir ikon ön planı: şeffaf zemin, işaret orta %66'lık alanda.
    await _render(tester, const Center(child: _Mark(scale: 0.58)), [
      ('$root/apps/mobile/assets/icon/app_icon_foreground.png', 1024),
    ]);
  });
}
