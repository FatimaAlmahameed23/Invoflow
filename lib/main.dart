import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
    throw StateError('Missing Supabase configuration.');
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);

  runApp(const InvoFlowApp());
}

class InvoFlowApp extends StatelessWidget {
  const InvoFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InvoFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, brightness: Brightness.light),
      home: const Scaffold(body: Center(child: Text('InvoFlow'))),
    );
  }
}
