import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

/// Biletin iki yarısı arasındaki delikli kesim çizgisi: iki yanda yarım daire çentik,
/// ortada kesik çizgi.
class TicketPerforation extends StatelessWidget {
  const TicketPerforation({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.ticketNotchHeight,
      child: Row(
        children: [
          const _Notch(isLeft: true),
          Expanded(
            child: Padding(
              padding: AppPaddings.horizontalXs,
              child: CustomPaint(
                size: const Size.fromHeight(AppSizes.borderWidth),
                painter: _DashPainter(),
              ),
            ),
          ),
          const _Notch(isLeft: false),
        ],
      ),
    );
  }
}

class _Notch extends StatelessWidget {
  const _Notch({required this.isLeft});

  final bool isLeft;

  @override
  Widget build(BuildContext context) {
    // Daire kartın kenarına ortalanır; dış yarısını kart kırpar, yarım çentik kalır.
    return SizedBox(
      width: AppSizes.ticketNotchHeight / 2,
      child: OverflowBox(
        maxWidth: AppSizes.ticketNotchHeight,
        alignment: isLeft ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: AppSizes.ticketNotchHeight,
          height: AppSizes.ticketNotchHeight,
          decoration: BoxDecoration(
            color: AppColors.background,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border, width: AppSizes.borderWidth),
          ),
        ),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = AppSizes.borderWidth;
    final y = size.height / 2;
    for (var x = 0.0; x < size.width; x += AppSizes.dashLength * 2) {
      canvas.drawLine(Offset(x, y), Offset(x + AppSizes.dashLength, y), paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter oldDelegate) => false;
}
