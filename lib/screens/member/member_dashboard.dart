import 'package:flutter/material.dart';

import '../../controllers/app_controller.dart';
import '../../repositories/assoc_repository.dart';
import '../public_map_screen.dart';
import 'programs_screen.dart';
import '../../theme/app_theme.dart';
import '../../widgets/statistic_card.dart';
import 'association_info_screen.dart';
import 'members_screen.dart';
import 'profile_screen.dart';
import 'register_member_screen.dart';

class MemberDashboard extends StatefulWidget {
  final AppController controller;
  const MemberDashboard({super.key, required this.controller});
  @override
  State<MemberDashboard> createState() => _MemberDashboardState();
}

class _MemberDashboardState extends State<MemberDashboard> {
  int selected = 0;
  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final data = controller.data;
    return Scaffold(
      appBar: AppBar(
        title: const Text('AssocMap'),
        actions: [
          IconButton(
            tooltip: 'Public map',
            icon: const Icon(Icons.public),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    PublicMapScreen(repository: controller.repository),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: controller.loading ? null : controller.refresh,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: controller.loading
                ? const Center(child: CircularProgressIndicator())
                : controller.error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(controller.error!),
                        FilledButton(
                          onPressed: controller.refresh,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : data == null
                ? const Center(child: Text('Association unavailable.'))
                : IndexedStack(
                    index: selected,
                    children: [
                      _HomeTab(
                        data: data,
                        onRegister: () => setState(() => selected = 3),
                      ),
                      MembersScreen(data: data),
                      ProgramsScreen(data: data),
                      RegisterMemberScreen(controller: controller),
                      ProfileScreen(
                        user: controller.session!,
                        associationName: data.association.name,
                        onLogout: controller.logout,
                      ),
                    ],
                  ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (i) => setState(() => selected = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            label: 'Members',
          ),
          NavigationDestination(
            icon: Icon(Icons.work_outline),
            label: 'Programs',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_add_alt),
            label: 'Register',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_circle_outlined),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final MemberData data;
  final VoidCallback onRegister;
  const _HomeTab({required this.data, required this.onRegister});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        'SAAD PHASE II - CEBU',
        style: TextStyle(color: AppColors.grayText),
      ),
      const SizedBox(height: 8),
      Text(
        data.association.name,
        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      const Text(
        'Your association, programs, and membership updates in one place.',
      ),
      const SizedBox(height: 24),
      Row(
        children: [
          StatisticCard(
            label: 'Members',
            value: '${data.members.length}',
            icon: Icons.people_outline,
          ),
          const SizedBox(width: 12),
          StatisticCard(
            label: 'Pending',
            value:
                '${data.registrations.where((r) => r.status == 'Pending').length}',
            icon: Icons.pending_actions,
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          StatisticCard(
            label: 'Projects',
            value: '${data.projects.length}',
            icon: Icons.work_outline,
          ),
          const SizedBox(width: 12),
          StatisticCard(
            label: 'Trainings',
            value: '${data.trainings.length}',
            icon: Icons.school_outlined,
          ),
        ],
      ),
      const SizedBox(height: 24),
      Card(
        child: ListTile(
          leading: const Icon(Icons.groups_outlined),
          title: const Text('Association information'),
          subtitle: Text(
            '${data.association.barangay}, ${data.association.municipality}',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AssociationInfoScreen(data: data),
            ),
          ),
        ),
      ),
      const SizedBox(height: 20),
      ElevatedButton.icon(
        onPressed: onRegister,
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Register new member'),
      ),
      const SizedBox(height: 16),
      const Text(
        'New registrations require Field Officer approval before appearing in the official member list.',
      ),
      const SizedBox(height: 24),
      const Text(
        'Demo environment - Fictional records. Changes reset when the app restarts.',
        style: TextStyle(color: AppColors.grayText, fontSize: 12),
      ),
    ],
  );
}
