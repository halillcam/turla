import 'package:flutter/material.dart';

/// Profilde etiket + değer satırı, isteğe bağlı eylem düğmesiyle.
class ProfileInfoTile extends StatelessWidget {
  const ProfileInfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label, style: Theme.of(context).textTheme.bodySmall),
      subtitle: Text(value, style: Theme.of(context).textTheme.bodyLarge),
      trailing: actionLabel == null
          ? null
          : TextButton(onPressed: onAction, child: Text(actionLabel!)),
    );
  }
}
