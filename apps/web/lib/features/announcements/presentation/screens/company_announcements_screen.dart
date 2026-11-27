import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/bloc/load_status.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/failure_messages.dart';
import '../../../../core/widgets/dialogs.dart';
import '../../../../core/widgets/panel_page.dart';
import '../../../../core/widgets/status_view.dart';
import '../../../../core/widgets/title_body_form_dialog.dart';
import '../../domain/entities/company_announcement.dart';
import '../cubit/company_announcements_cubit.dart';
import '../widgets/announcement_card.dart';

/// Firma duyuruları. [companyId] null: super admin yönetimi (yayınla / sil);
/// verilirse firma alanında okuma.
class CompanyAnnouncementsScreen extends StatelessWidget {
  const CompanyAnnouncementsScreen({this.companyId, super.key});

  final String? companyId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CompanyAnnouncementsCubit>(param1: companyId)..load(),
      child: const _AnnouncementsView(),
    );
  }
}

class _AnnouncementsView extends StatelessWidget {
  const _AnnouncementsView();

  Future<void> _publish(BuildContext context) async {
    final cubit = context.read<CompanyAnnouncementsCubit>();
    final sent = await showTitleBodyFormDialog(
      context,
      title: AppStrings.publishAnnouncement,
      submitLabel: AppStrings.publish,
      titleMaxLength: CompanyAnnouncement.titleMaxLength,
      bodyMaxLength: CompanyAnnouncement.bodyMaxLength,
      targetLabel: AppStrings.announcementTarget,
      targets: [
        (value: null, label: AppStrings.allCompanies),
        for (final company in cubit.state.companies) (value: company.id, label: company.name),
      ],
      onSubmit: (title, body, target) =>
          cubit.publish(title: title, body: body, targetCompanyId: target),
    );
    if (sent && context.mounted) showMessage(context, AppStrings.announcementPublished);
  }

  Future<void> _delete(BuildContext context, CompanyAnnouncement announcement) async {
    final cubit = context.read<CompanyAnnouncementsCubit>();
    final confirmed = await showConfirmDialog(
      context,
      title: AppStrings.deleteAnnouncementTitle,
      message: announcement.title,
      confirmLabel: AppStrings.delete,
      isDestructive: true,
    );
    if (!confirmed) return;
    final result = await cubit.delete(announcement);
    if (context.mounted) {
      showMessage(context, result.isSuccess ? AppStrings.deleted : result.failure!.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CompanyAnnouncementsCubit>();
    final state = context.watch<CompanyAnnouncementsCubit>().state;
    return PanelPage(
      title: AppStrings.announcementsTitle,
      actions: [
        if (cubit.canManage)
          FilledButton.icon(
            onPressed: state.status == LoadStatus.ready ? () => _publish(context) : null,
            icon: const Icon(Icons.campaign_outlined),
            label: const Text(AppStrings.publishAnnouncement),
          ),
        IconButton(
          onPressed: state.status == LoadStatus.loading ? null : cubit.load,
          icon: const Icon(Icons.refresh),
          tooltip: AppStrings.retry,
        ),
      ],
      child: switch (state.status) {
        LoadStatus.initial || LoadStatus.loading => const StatusView.loading(),
        LoadStatus.failure => StatusView.message(
          message: state.loadFailure!.message,
          onAction: cubit.load,
        ),
        LoadStatus.ready when state.announcements.isEmpty => const StatusView.message(
          message: AppStrings.announcementsEmpty,
        ),
        LoadStatus.ready => ListView(
          children: [
            for (final announcement in state.announcements)
              Padding(
                padding: AppMargins.cardList,
                child: AnnouncementCard(
                  announcement: announcement,
                  onDelete: cubit.canManage ? () => _delete(context, announcement) : null,
                ),
              ),
          ],
        ),
      },
    );
  }
}
