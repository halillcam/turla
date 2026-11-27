import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

/// "Hesabın yok mu? Kayıt ol" gibi alt bağlantı.
class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    required this.question,
    required this.actionLabel,
    required this.onPressed,
    super.key,
  });

  final String question;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(question, style: Theme.of(context).textTheme.bodySmall),
        TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(textStyle: AppTextStyles.labelMedium),
          child: Text(actionLabel),
        ),
      ],
    );
  }
}
