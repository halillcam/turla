import 'package:flutter/material.dart';

import '../../../../core/constants/strings.dart';
import '../../../../core/widgets/panel_page.dart';
import '../../domain/entities/staff_member.dart';

/// Hesap tablosu: ad, giriş kimliği, telefon, durum ve aktif/pasif düğmesi.
class MemberTable extends StatelessWidget {
  const MemberTable({
    required this.members,
    required this.emptyMessage,
    required this.onToggleActive,
    this.enabled = true,
    this.showLoginId = true,
    super.key,
  });

  final List<StaffMember> members;
  final String emptyMessage;
  final ValueChanged<StaffMember> onToggleActive;
  final bool enabled;
  final bool showLoginId;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return Center(child: Text(emptyMessage));

    return SingleChildScrollView(
      child: SizedBox(
        width: double.infinity,
        child: DataTable(
          columns: [
            const DataColumn(label: Text(AppStrings.nameColumn)),
            if (showLoginId) const DataColumn(label: Text(AppStrings.loginIdColumn)),
            const DataColumn(label: Text(AppStrings.phoneColumn)),
            const DataColumn(label: Text(AppStrings.statusColumn)),
            const DataColumn(label: SizedBox.shrink()),
          ],
          rows: [
            for (final member in members)
              DataRow(
                cells: [
                  DataCell(Text(member.fullName)),
                  if (showLoginId) DataCell(SelectableText(member.loginId ?? AppStrings.empty)),
                  DataCell(Text(member.phone ?? AppStrings.empty)),
                  DataCell(
                    ActiveChip(
                      isActive: member.isActive,
                      activeLabel: AppStrings.active,
                      passiveLabel: AppStrings.passive,
                    ),
                  ),
                  DataCell(
                    TextButton(
                      onPressed: enabled ? () => onToggleActive(member) : null,
                      child: Text(member.isActive ? AppStrings.makePassive : AppStrings.makeActive),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
