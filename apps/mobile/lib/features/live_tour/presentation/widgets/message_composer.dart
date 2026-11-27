import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

/// Yazı kutusu + gönder düğmesi (sohbet ve duyuru). [resetToken] değişince kutu
/// temizlenir (gönderim başarılı oldu).
class MessageComposer extends StatefulWidget {
  const MessageComposer({
    required this.hint,
    required this.sendLabel,
    required this.maxLength,
    required this.isSending,
    required this.onSend,
    required this.resetToken,
    this.maxLines = 4,
    super.key,
  });

  final String hint;
  final String sendLabel;
  final int maxLength;
  final bool isSending;
  final ValueChanged<String> onSend;
  final int resetToken;
  final int maxLines;

  @override
  State<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<MessageComposer> {
  final TextEditingController _controller = TextEditingController();

  @override
  void didUpdateWidget(MessageComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resetToken != widget.resetToken) _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.isSending) return;
    widget.onSend(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: AppSizes.borderWidth),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: AppPaddings.composer,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: widget.maxLines,
                  maxLength: widget.maxLength,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    counterText: '',
                    fillColor: AppColors.background,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton.filled(
                onPressed: widget.isSending ? null : _submit,
                style: IconButton.styleFrom(
                  shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
                  minimumSize: const Size.square(AppSizes.minTapTarget),
                ),
                tooltip: widget.sendLabel,
                icon: widget.isSending
                    ? const SizedBox.square(
                        dimension: AppSizes.iconMd,
                        child: CircularProgressIndicator(strokeWidth: AppSizes.progressStroke),
                      )
                    : const Icon(Icons.send, size: AppSizes.iconMd, color: AppColors.onPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
