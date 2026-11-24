import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turla_core/turla_core.dart';

import '../../core/di/injection.dart';
import '../../features/auth/presentation/bloc/session_bloc.dart';
import '../../features/companies/domain/entities/company.dart';
import '../router/app_routes.dart';
import 'company_context_cubit.dart';
import 'widgets/panel_sidebar.dart';
import 'widgets/panel_top_bar.dart';

/// Giriş sonrası tüm ekranların kabuğu: solda menü, üstte firma / kullanıcı.
class PanelShell extends StatelessWidget {
  const PanelShell({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final session = context.select((SessionBloc bloc) => bloc.state.session);
    if (session == null) return const SizedBox.shrink();

    final companyId = AppRoutes.companyIdOf(location);
    final body = Scaffold(
      body: Row(
        children: [
          PanelSidebar(
            location: location,
            companyId: companyId,
            showCompanies: session.isSuperAdmin,
          ),
          const VerticalDivider(width: AppSizes.borderWidth),
          Expanded(
            child: Column(
              children: [
                PanelTopBar(
                  userName: session.profile.fullName,
                  roleLabel: session.profile.role.label,
                  onSignOut: () => context.read<SessionBloc>().add(const SessionSignOutRequested()),
                ),
                const Divider(height: AppSizes.borderWidth),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );

    if (companyId == null) return body;
    return BlocProvider(
      key: ValueKey(companyId),
      create: (_) =>
          CompanyContextCubit(companyId: companyId, repository: getIt(), known: session.company)
            ..load(),
      child: BlocBuilder<CompanyContextCubit, Company?>(
        builder: (context, company) => CompanyScope(company: company, child: body),
      ),
    );
  }
}

/// Firma alanındaki ekranların üst çubukta firmayı görebilmesi için.
class CompanyScope extends InheritedWidget {
  const CompanyScope({required this.company, required super.child, super.key});

  final Company? company;

  static Company? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CompanyScope>()?.company;

  @override
  bool updateShouldNotify(CompanyScope oldWidget) => company != oldWidget.company;
}
