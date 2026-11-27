import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../auth/presentation/bloc/session_bloc.dart';
import '../widgets/guest_profile_view.dart';
import '../widgets/signed_in_profile_view.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.select((SessionBloc bloc) => bloc.state.profile);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: AppPaddings.screen,
          children: [
            const PageHeader(title: AppStrings.profileTitle, padding: EdgeInsets.zero),
            const SizedBox(height: AppSpacing.md),
            if (profile == null)
              const GuestProfileView()
            else
              SignedInProfileView(profile: profile),
          ],
        ),
      ),
    );
  }
}
