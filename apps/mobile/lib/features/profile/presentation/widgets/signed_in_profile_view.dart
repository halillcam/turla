import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/widgets/bordered_group.dart';
import '../../../auth/presentation/bloc/session_bloc.dart';
import '../../../city_choice/presentation/cubit/selected_city_cubit.dart';
import '../utils/profile_display.dart';
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
        Card(
          child: Padding(
            padding: AppPaddings.card,
            child: Row(
              children: [
                CircleAvatar(
                  radius: AppSizes.avatarMd / 2,
                  backgroundColor: AppColors.primaryTint,
                  foregroundColor: AppColors.primary,
                  child: Text(
                    profile.initials,
                    style: textTheme.labelLarge?.copyWith(color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: AppSpacing.inputHorizontal),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.fullName, style: textTheme.headlineSmall),
                      Text(profile.role.label, style: textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        BorderedGroup(
          children: [
            ProfileInfoTile(
              icon: Icons.mail_outline,
              label: AppStrings.account,
              value: profile.email,
            ),
            ProfileInfoTile(
              icon: Icons.place_outlined,
              label: AppStrings.selectedCity,
              value: cityName,
              actionLabel: AppStrings.change,
              onAction: () => context.push(AppRoutes.citySelection),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        OutlinedButton(
          onPressed: () => context.read<SessionBloc>().add(const SessionSignOutRequested()),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.primary, width: AppSizes.borderWidth),
            minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          ),
          child: const Text(AppStrings.signOut),
        ),
      ],
    );
  }
}
