import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/company_announcement.dart';

/// Firma duyurusu kartı: başlık, hedef, zaman, metin; super admin için sil düğmesi.
class AnnouncementCard extends StatelessWidget {
  const AnnouncementCard({required this.announcement, this.onDelete, super.key});

  final CompanyAnnouncement announcement;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final target = announcement.isForAllCompanies
        ? AppStrings.allCompanies
        : (announcement.companyName ?? '');
    return Card(
      child: Padding(
        padding: AppPaddings.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(announcement.title, style: textTheme.titleMedium)),
                if (onDelete != null)
                  IconButton(
                    tooltip: AppStrings.delete,
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            Text(
              '$target · ${Formatters.dateTime(announcement.createdAt)}',
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(announcement.body),
          ],
        ),
      ),
    );
  }
}
