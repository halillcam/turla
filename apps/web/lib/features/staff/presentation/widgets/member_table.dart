import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';
import '../../../../core/widgets/panel_page.dart';
import '../../domain/entities/staff_member.dart';

/// Hesap tablosu: ad, giriş kimliği, telefon, durum ve aktif/pasif düğmesi.
class MemberTable extends StatelessWidget {
  const MemberTable({
    required this.members,
    required this.emptyMessage,
    required this.onToggleActive,
    this.onResetPassword,
    this.enabled = true,
    this.showLoginId = true,
    this.emails,
    super.key,
  });

  final List<StaffMember> members;
  final String emptyMessage;
  final ValueChanged<StaffMember> onToggleActive;

  /// Verilirse giriş kimlikli hesaplarda "Şifre sıfırla" gösterilir.
  final ValueChanged<StaffMember>? onResetPassword;
  final bool enabled;
  final bool showLoginId;

  /// Verilirse "E-posta" sütunu gösterilir (firma yöneticileri).
  final Map<String, String>? emails;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return Center(child: Text(emptyMessage));

    return SingleChildScrollView(
      child: PanelTableCard(
        child: DataTable(
          columns: [
            const DataColumn(label: Text(AppStrings.nameColumn)),
            if (showLoginId) const DataColumn(label: Text(AppStrings.loginIdColumn)),
            if (emails != null) const DataColumn(label: Text(AppStrings.emailLabel)),
            const DataColumn(label: Text(AppStrings.phoneColumn)),
            const DataColumn(label: Text(AppStrings.statusColumn)),
            const DataColumn(label: SizedBox.shrink()),
          ],
          rows: [
            for (final member in members)
              DataRow(
                cells: [
                  DataCell(Text(member.fullName)),
                  if (showLoginId)
                    DataCell(
                      SelectableText(
                        member.loginId ?? AppStrings.empty,
                        style: PanelTextStyles.mono,
                      ),
                    ),
                  if (emails != null)
                    DataCell(SelectableText(emails![member.id] ?? AppStrings.empty)),
                  DataCell(Text(member.phone ?? AppStrings.empty)),
                  DataCell(
                    ActiveChip(
                      isActive: member.isActive,
                      activeLabel: AppStrings.active,
                      passiveLabel: AppStrings.passive,
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (member.loginId != null && onResetPassword != null)
                          TextButton(
                            onPressed: enabled ? () => onResetPassword!(member) : null,
                            child: const Text(AppStrings.resetPassword),
                          ),
                        TextButton(
                          onPressed: enabled ? () => onToggleActive(member) : null,
                          child: Text(
                            member.isActive ? AppStrings.makePassive : AppStrings.makeActive,
                          ),
                        ),
                      ],
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
