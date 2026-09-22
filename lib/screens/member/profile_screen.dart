import 'package:flutter/material.dart';

import '../../repositories/assoc_repository.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  final VoidCallback onLogout;

  final Session user;
  final String associationName;
  const ProfileScreen({
    super.key,
    required this.onLogout,
    required this.user,
    required this.associationName,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
      children: [
        const CircleAvatar(
          radius: 42,
          backgroundColor: AppColors.lightBlue,
          child: Icon(Icons.person, size: 46, color: AppColors.primaryBlue),
        ),
        const SizedBox(height: 14),
        Text(
          user.name,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Text(
          'Shared association account',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.grayText),
        ),
        const SizedBox(height: 25),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('Email'),
                subtitle: Text(user.email),
              ),
              ListTile(
                leading: const Icon(Icons.groups_outlined),
                title: const Text('Association'),
                subtitle: Text(associationName),
              ),
              ListTile(
                leading: const Icon(Icons.security_outlined),
                title: const Text('Access'),
                subtitle: const Text('Association Member'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Log out?'),
              content: const Text(
                'You will need to log in again to access the member area.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    onLogout();
                  },
                  child: const Text('Log out'),
                ),
              ],
            ),
          ),
          icon: const Icon(Icons.logout),
          label: const Text('Log Out'),
        ),
        const SizedBox(height: 20),
        const Text(
          'This account is a shared Association Member account. Individual user tracking is therefore limited.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.grayText, fontSize: 12),
        ),
      ],
    );
  }
}
