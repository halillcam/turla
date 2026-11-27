import 'package:flutter/material.dart';

/// Kenarlıklı tek kart içinde, aralarında ince çizgi olan satırlar (profil bilgileri,
/// katılımcı listesi gibi).
class BorderedGroup extends StatelessWidget {
  const BorderedGroup({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, child) in children.indexed) ...[if (index > 0) const Divider(), child],
        ],
      ),
    );
  }
}
