part of 'settings_cubit.dart';

class SettingsState {
  final SettingsUser? user;
  final bool isLoading;
  final bool isSigningOut;
  final bool isSignedOut;
  final String? errorMessage;

  const SettingsState({
    this.user,
    this.isLoading = false,
    this.isSigningOut = false,
    this.isSignedOut = false,
    this.errorMessage,
  });
}
