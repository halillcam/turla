import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/strings.dart';
import '../../../auth/presentation/bloc/session_bloc.dart';
import '../../../city_choice/presentation/cubit/selected_city_cubit.dart';
import 'profile_info_tile.dart';

class SignedInProfileView extends StatelessWidget {
  const SignedInProfileView({required this.profile, super.key});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cityName = context.select(
      (SelectedCityCubit cubit) => cubit.state.city?.name ?? AppStrings.noCitySelected,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CircleAvatar(
          radius: AppSizes.avatarMd / 2,
          backgroundColor: AppColors.primaryLight,
          child: Icon(Icons.person, color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(profile.fullName, style: textTheme.titleMedium, textAlign: TextAlign.center),
        Text(profile.role.label, style: textTheme.bodySmall, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.xl),
        ProfileInfoTile(icon: Icons.mail_outline, label: AppStrings.account, value: profile.email),
        ProfileInfoTile(
          icon: Icons.place_outlined,
          label: AppStrings.selectedCity,
          value: cityName,
          actionLabel: AppStrings.change,
          onAction: () => context.push(AppRoutes.citySelection),
        ),
        const SizedBox(height: AppSpacing.xl),
        OutlinedButton.icon(
          onPressed: () => context.read<SessionBloc>().add(const SessionSignOutRequested()),
          icon: const Icon(Icons.logout),
          label: const Text(AppStrings.signOut),
        ),
      ],
    );
  }
}
