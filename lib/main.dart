import 'package:flutter/material.dart';
import 'controllers/app_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'repositories/supabase_assoc_repository.dart';
import 'repositories/assoc_repository.dart';
import 'screens/auth/login_screen.dart';
import 'screens/member/member_dashboard.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!SupabaseConfig.valid(SupabaseConfig.url, SupabaseConfig.key)) {
    runApp(
      const SetupMessage(
        'Supabase configuration is missing or invalid. Add the project URL and client publishable/anon key to .env, then restart using --dart-define-from-file=.env.',
      ),
    );
    return;
  }
  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.key,
      authOptions: FlutterAuthClientOptions(
        localStorage: SecureSessionStorage(
          'assocmap_session_${Uri.parse(SupabaseConfig.url).host}',
        ),
      ),
    );
    runApp(
      AssocMapApp(
        repository: SupabaseAssocRepository(Supabase.instance.client),
      ),
    );
  } catch (_) {
    runApp(
      const SetupMessage(
        'Unable to initialize AssocMap. Check your internet connection and device storage, then restart the app.',
      ),
    );
  }
}

class SetupMessage extends StatelessWidget {
  final String message;
  const SetupMessage(this.message, {super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: AppTheme.theme,
    home: Scaffold(
      appBar: AppBar(title: const Text('AssocMap setup')),
      body: Center(
        child: Padding(padding: const EdgeInsets.all(24), child: Text(message)),
      ),
    ),
  );
}

class AssocMapApp extends StatefulWidget {
  final AssocRepository repository;
  const AssocMapApp({super.key, required this.repository});
  @override
  State<AssocMapApp> createState() => _AssocMapAppState();
}

class _AssocMapAppState extends State<AssocMapApp> with WidgetsBindingObserver {
  late final controller = AppController(widget.repository);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller.restore();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        controller.session != null &&
        !controller.loading) {
      controller.refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AssocMap',
      theme: AppTheme.theme,
      key: ValueKey(controller.session?.id),
      home: controller.restoring
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : controller.session == null
          ? LoginScreen(controller: controller)
          : MemberDashboard(controller: controller),
    ),
  );
}
