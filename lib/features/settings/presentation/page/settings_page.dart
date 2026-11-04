import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invoflow/core/widgets/app_app_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../login/presentation/page/login_page.dart';
import '../../data/datasources/settings_remote_data_source.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/usecases/get_current_user_use_case.dart';
import '../../domain/usecases/sign_out_use_case.dart';
import '../cubit/settings_cubit.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = SettingsRepositoryImpl(
      SettingsRemoteDataSource(Supabase.instance.client),
    );

    return BlocProvider(
      create: (_) => SettingsCubit(
        getCurrentUser: GetCurrentUserUseCase(repository),
        signOutUseCase: SignOutUseCase(repository),
      )..loadAccount(),
      child: const Scaffold(
        appBar: AppAppBar(title: 'Settings', backButton: false),
        body: _SettingsView(),
      ),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SettingsCubit, SettingsState>(
      listenWhen: (previous, current) => current.isSignedOut,
      listener: (context, state) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const LoginPage()),
          (_) => false,
        );
      },
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                title: const Text('Account'),
                subtitle: Text(state.user?.email ?? 'No account email found'),
              ),
            ),
            if (state.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                state.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              if (state.user == null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: context.read<SettingsCubit>().loadAccount,
                    child: const Text('Try again'),
                  ),
                ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: state.isSigningOut
                    ? null
                    : context.read<SettingsCubit>().signOut,
                icon: state.isSigningOut
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout),
                label: Text(state.isSigningOut ? 'Signing out...' : 'Sign out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF92257E),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
