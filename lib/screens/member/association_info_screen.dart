import 'package:flutter/material.dart';

import '../../repositories/assoc_repository.dart';
import '../../theme/app_theme.dart';

class AssociationInfoScreen extends StatelessWidget {
  final MemberData data;
  const AssociationInfoScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final association = data.association;

    return Scaffold(
      appBar: AppBar(title: const Text('Association Information')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.groups_outlined,
              color: AppColors.primaryBlue,
              size: 58,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            association.name,
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 18),
          _InfoRow(label: 'Municipality', value: association.municipality),
          _InfoRow(label: 'Barangay', value: association.barangay),
          _InfoRow(label: 'Address', value: association.address),
          _InfoRow(label: 'Program Type', value: association.programType),
          _InfoRow(label: 'Member Count', value: '${data.members.length}'),
          _InfoRow(label: 'Status', value: association.status),
          const SizedBox(height: 20),
          const Text(
            'Read-only information',
            style: TextStyle(color: AppColors.grayText, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.grayText),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
