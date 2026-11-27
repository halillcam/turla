import 'package:flutter/material.dart';

import 'round_icon.dart';

/// Temanın geri düğmesi ikonu: açık yüzeyli, ince kenarlıklı daire içinde ok.
class RoundBackIcon extends StatelessWidget {
  const RoundBackIcon({super.key});

  @override
  Widget build(BuildContext context) => const RoundIcon(icon: Icons.arrow_back);
}
