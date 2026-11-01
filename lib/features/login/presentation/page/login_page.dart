import 'package:flutter/material.dart';
import 'package:invoflow/features/login/data/repositories/auth_repository_impl.dart';
import 'package:invoflow/features/login/domain/usecases/login_usecase.dart';
import 'package:invoflow/features/login/presentation/cubit/auth_cubit.dart';
import '../widgets/login_form.dart';
import '../widgets/login_header.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:invoflow/features/login/data/datasources/auth_remote_data_source.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 150),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                LoginHeader(),
                SizedBox(height: 80),
                BlocProvider(
                  create: (context) => AuthCubit(
                    LoginUseCase(
                      AuthRepositoryImpl(
                        AuthRemoteDataSource(Supabase.instance.client),
                      ),
                    ),
                  ),
                  child: const LoginForm(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
