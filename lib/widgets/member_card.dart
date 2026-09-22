import 'package:flutter/material.dart';

import '../models/member.dart';
import '../theme/app_theme.dart';

class MemberCard extends StatelessWidget {
  final Member member;

  const MemberCard({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: AppColors.lightBlue,
          child: Text(
            member.firstName.substring(0, 1),
            style: const TextStyle(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          member.fullName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          member.roleInAssociation.isEmpty
              ? 'Member'
              : member.roleInAssociation,
        ),
        trailing: _StatusChip(status: member.status),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(status),
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
      backgroundColor: status == 'Active'
          ? AppColors.lightBlue
          : Colors.orange.shade50,
      labelStyle: TextStyle(
        color: status == 'Active'
            ? AppColors.primaryBlue
            : Colors.orange.shade800,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
