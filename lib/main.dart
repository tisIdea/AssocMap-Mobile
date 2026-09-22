import 'package:flutter/material.dart';
import 'controllers/app_controller.dart';
import 'repositories/mock_assoc_repository.dart';
import 'screens/auth/login_screen.dart';
import 'screens/member/member_dashboard.dart';
import 'theme/app_theme.dart';

void main() => runApp(const AssocMapApp());

class AssocMapApp extends StatefulWidget {
  const AssocMapApp({super.key});
  @override
  State<AssocMapApp> createState() => _AssocMapAppState();
}

class _AssocMapAppState extends State<AssocMapApp> {
  final controller = AppController(MockAssocRepository());
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'AssocMap',
    theme: AppTheme.theme,
    home: ListenableBuilder(
      listenable: controller,
      builder: (context, _) => controller.session == null
          ? LoginScreen(controller: controller)
          : MemberDashboard(controller: controller),
    ),
  );
}
