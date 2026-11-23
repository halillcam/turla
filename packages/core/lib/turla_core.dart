/// Turla ortak çekirdek paketi.
library;

export 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

export 'src/bloc/turla_bloc_observer.dart';
export 'src/config/env.dart';
export 'src/constants/colors.dart';
export 'src/constants/core_strings.dart';
export 'src/constants/durations.dart';
export 'src/constants/font_sizes.dart';
export 'src/constants/paddings.dart';
export 'src/constants/radius.dart';
export 'src/constants/sizes.dart';
export 'src/constants/storage_keys.dart';
export 'src/enums/departure_status.dart';
export 'src/enums/ticket_status.dart';
export 'src/enums/tour_region.dart';
export 'src/enums/user_role.dart';
export 'src/features/auth/data/repositories/auth_repository_impl.dart';
export 'src/features/auth/domain/entities/auth_failure.dart';
export 'src/features/auth/domain/entities/sign_up_result.dart';
export 'src/features/auth/domain/entities/user_profile.dart';
export 'src/features/auth/domain/login_id.dart';
export 'src/features/auth/domain/repositories/auth_repository.dart';
export 'src/features/cities/data/datasources/city_local_data_source.dart';
export 'src/features/cities/data/datasources/city_remote_data_source.dart';
export 'src/features/cities/data/models/city_model.dart';
export 'src/features/cities/data/repositories/city_repository_impl.dart';
export 'src/features/cities/domain/entities/city.dart';
export 'src/features/cities/domain/repositories/city_repository.dart';
export 'src/supabase/turla_supabase.dart';
export 'src/theme/app_theme.dart';
export 'src/widgets/config_error_app.dart';
