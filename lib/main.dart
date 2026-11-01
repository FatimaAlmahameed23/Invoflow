import 'package:flutter/material.dart';
import 'mobile_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
    throw StateError('Missing Supabase configuration.');
  }

  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);

  runApp(const InvoFlowApp());
}

class InvoFlowApp extends StatelessWidget {
  const InvoFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const InvoFlowPreview();
  }
}
