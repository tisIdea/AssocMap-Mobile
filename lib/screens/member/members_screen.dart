import 'package:flutter/material.dart';
import '../../repositories/assoc_repository.dart';
import '../../widgets/record_details.dart';

class MembersScreen extends StatefulWidget {
  final MemberData data;
  const MembersScreen({super.key, required this.data});
  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  String query = '';
  String status = 'All';
  bool applications = false;
  @override
  Widget build(BuildContext context) {
    final members = widget.data.members.where(
      (m) => m.fullName.toLowerCase().contains(query.toLowerCase()),
    );
    final registrations = widget.data.registrations.where(
      (r) =>
          r.fullName.toLowerCase().contains(query.toLowerCase()) &&
          (status == 'All' || r.status == status),
    );
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Members & registrations',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Members')),
            ButtonSegment(value: true, label: Text('Registrations')),
          ],
          selected: {applications},
          onSelectionChanged: (v) => setState(() => applications = v.first),
        ),
        const SizedBox(height: 16),
        TextField(
          onChanged: (v) => setState(() => query = v.trim()),
          decoration: const InputDecoration(
            labelText: 'Search by name',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        if (applications)
          Wrap(
            spacing: 8,
            children: ['All', 'Pending', 'Approved', 'Rejected']
                .map(
                  (s) => ChoiceChip(
                    label: Text(s),
                    selected: status == s,
                    onSelected: (_) => setState(() => status = s),
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: 12),
        if (applications && registrations.isEmpty ||
            !applications && members.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No matching records. Try a different name or filter.'),
          ),
        if (!applications)
          ...members.map(
            (m) => Card(
              child: ListTile(
                title: Text(m.fullName),
                subtitle: Text(m.roleInAssociation),
                trailing: StatusBadge(m.status),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecordDetails(
                      title: 'Member information',
                      fields: {
                        'Name': m.fullName,
                        'Member ID': m.id,
                        'Birthday': dateLabel(m.birthday),
                        'Sex': m.sex,
                        'Association role': m.roleInAssociation,
                        'Beneficiary type': m.beneficiaryType,
                        'Status': m.status,
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (applications)
          ...registrations.map(
            (r) => Card(
              child: ListTile(
                title: Text(r.fullName),
                subtitle: Text('Submitted ${dateLabel(r.submittedAt)}'),
                trailing: StatusBadge(r.status),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecordDetails(
                      title: 'Registration status',
                      fields: {
                        'Applicant': r.fullName,
                        'Reference': r.id,
                        'Status': r.status,
                        'Birthday': dateLabel(r.birthday),
                        'Sex': r.sex,
                        'Beneficiary type': r.beneficiaryType.isEmpty
                            ? 'Not specified'
                            : r.beneficiaryType,
                        'Submitted': dateLabel(r.submittedAt),
                        'Reviewed': dateLabel(r.reviewedAt),
                        if (r.rejectionReason != null)
                          'Reason for rejection': r.rejectionReason!,
                        if (r.status == 'Pending')
                          'Next step':
                              'Await Field Officer review. This application is not yet an official member record.',
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
