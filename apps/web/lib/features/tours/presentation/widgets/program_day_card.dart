import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';
import '../../domain/entities/program_day.dart';

/// Programın bir günü: başlık, etkinlikler (satır satır), sıralama ve silme.
///
/// Metin alanları ilk değerle başlar; sonraki her değişiklik geri çağrıyla
/// Cubit'e iletilir. Kart, gün sırası değişse de doğru günle eşleşsin diye
/// dışarıdan sabit bir anahtarla oluşturulur.
class ProgramDayCard extends StatefulWidget {
  const ProgramDayCard({
    required this.dayNo,
    required this.day,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onTitleChanged,
    required this.onActivitiesChanged,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
    super.key,
  });

  final int dayNo;
  final ProgramDay day;
  final bool canMoveUp;
  final bool canMoveDown;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onActivitiesChanged;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onRemove;

  @override
  State<ProgramDayCard> createState() => _ProgramDayCardState();
}

class _ProgramDayCardState extends State<ProgramDayCard> {
  late final _title = TextEditingController(text: widget.day.title);
  late final _activities = TextEditingController(text: widget.day.activities.join('\n'));

  @override
  void dispose() {
    _title.dispose();
    _activities.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppPaddings.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  '${widget.dayNo}. ${AppStrings.dayLabel}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  onPressed: widget.canMoveUp ? widget.onMoveUp : null,
                  icon: const Icon(Icons.arrow_upward),
                  tooltip: AppStrings.moveUp,
                ),
                IconButton(
                  onPressed: widget.canMoveDown ? widget.onMoveDown : null,
                  icon: const Icon(Icons.arrow_downward),
                  tooltip: AppStrings.moveDown,
                ),
                IconButton(
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: AppStrings.removeDay,
                ),
              ],
            ),
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: AppStrings.dayTitle),
              onChanged: widget.onTitleChanged,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _activities,
              decoration: const InputDecoration(labelText: AppStrings.dayActivities),
              minLines: 3,
              maxLines: 10,
              onChanged: widget.onActivitiesChanged,
            ),
          ],
        ),
      ),
    );
  }
}
