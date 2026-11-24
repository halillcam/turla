import 'package:flutter/widgets.dart';

/// Sekme değişince içeriğin (ve Cubit'inin) yok edilmemesini sağlar:
/// kaydedilmemiş düzenlemeler kaybolmaz, veri tekrar sunucudan çekilmez.
class KeepTabAlive extends StatefulWidget {
  const KeepTabAlive({required this.child, super.key});

  final Widget child;

  @override
  State<KeepTabAlive> createState() => _KeepTabAliveState();
}

class _KeepTabAliveState extends State<KeepTabAlive> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
