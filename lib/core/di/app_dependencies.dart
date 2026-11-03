import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invoflow/features/login/data/datasources/auth_remote_data_source.dart';
import 'package:invoflow/features/login/data/repositories/auth_repository_impl.dart';
import 'package:invoflow/features/login/domain/usecases/login_usecase.dart';
import 'package:invoflow/features/login/presentation/cubit/auth_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Composes dependencies above the navigator so all routes can access them.
class AppDependencies extends StatelessWidget {
  const AppDependencies({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthCubit>(
      create: (_) => AuthCubit(
        LoginUseCase(
          AuthRepositoryImpl(AuthRemoteDataSource(Supabase.instance.client)),
        ),
      ),
      child: child,
    );
  }
}
