import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invoflow/features/settings/data/datasources/settings_remote_data_source.dart';
import 'package:invoflow/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:invoflow/features/settings/domain/usecases/get_current_user_use_case.dart';
import 'package:invoflow/features/settings/domain/usecases/sign_out_use_case.dart';
import 'package:invoflow/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsDependencies extends StatelessWidget {
  const SettingsDependencies({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SettingsCubit>(
      create: (_) {
        final repository = SettingsRepositoryImpl(
          SettingsRemoteDataSource(Supabase.instance.client),
        );
        return SettingsCubit(
          getCurrentUser: GetCurrentUserUseCase(repository),
          signOutUseCase: SignOutUseCase(repository),
        )..loadAccount();
      },
      child: child,
    );
  }
}
