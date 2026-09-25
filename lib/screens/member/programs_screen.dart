import 'package:flutter/material.dart';
import '../../repositories/assoc_repository.dart';
import '../../widgets/record_details.dart';

class ProgramsScreen extends StatefulWidget {
  final MemberData data;
  const ProgramsScreen({super.key, required this.data});
  @override
  State<ProgramsScreen> createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends State<ProgramsScreen> {
  String query = '';
  String status = 'All';
  bool trainings = false;
  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final projects = data.projects.where(
      (p) =>
          '${p.title} ${p.commodity}'.toLowerCase().contains(
            query.toLowerCase(),
          ) &&
          (status == 'All' || p.status == status),
    );
    final sessions = data.trainings.where(
      (t) => t.title.toLowerCase().contains(query.toLowerCase()),
    );
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Association programs',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Projects')),
            ButtonSegment(value: true, label: Text('Trainings')),
          ],
          selected: {trainings},
          onSelectionChanged: (v) => setState(() {
            trainings = v.first;
            status = 'All';
          }),
        ),
        const SizedBox(height: 16),
        TextField(
          onChanged: (v) => setState(() => query = v.trim()),
          decoration: const InputDecoration(
            labelText: 'Search programs',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        if (!trainings)
          Wrap(
            spacing: 8,
            children: ['All', 'Ongoing', 'Completed']
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
        if (trainings && sessions.isEmpty || !trainings && projects.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No programs match your search.'),
          ),
        if (!trainings)
          ...projects.map(
            (p) => Card(
              child: ListTile(
                leading: const Icon(Icons.set_meal_outlined),
                title: Text(p.title),
                subtitle: Text(
                  '${p.commodity} • ${p.status}\n${dateLabel(p.implementationDate)}',
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecordDetails(
                      title: 'Project details',
                      fields: {
                        'Project': p.title,
                        'Commodity': p.commodity,
                        'Program': p.component,
                        'Status': p.status,
                        'Implementation date': dateLabel(p.implementationDate),
                      },
                      children: [
                        const ListTile(title: Text('Project materials')),
                        if (p.materials.isEmpty)
                          const ListTile(title: Text('No materials recorded.')),
                        ...p.materials.map(
                          (m) => Card(
                            child: ListTile(
                              title: Text(m.name),
                              subtitle: Text(
                                '${m.quantity} ${m.unit} • PHP ${m.unitCost?.toStringAsFixed(2) ?? 'Not recorded'} / unit\n${m.status} • Delivery: ${dateLabel(m.deliveryDate)}',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (trainings)
          ...sessions.map(
            (t) => Card(
              child: ListTile(
                leading: const Icon(Icons.school_outlined),
                title: Text(t.title),
                subtitle: Text(
                  '${dateLabel(t.date)} • ${t.participants.length} participants',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecordDetails(
                      title: 'Training details',
                      fields: {
                        'Training': t.title,
                        'Component': t.component,
                        'Date conducted': dateLabel(t.date),
                        'Training cost':
                            'PHP ${t.cost?.toStringAsFixed(2) ?? 'Not recorded'}',
                        'Present':
                            '${t.participants.where((p) => p.attendance == 'Present').length} / ${t.participants.length}',
                      },
                      children: [
                        const ListTile(title: Text('Participant attendance')),
                        if (t.participants.isEmpty)
                          const ListTile(
                            title: Text('No attendance recorded.'),
                          ),
                        ...t.participants.map(
                          (p) => ListTile(
                            title: Text(
                              data.members
                                      .where((m) => m.id == p.memberId)
                                      .firstOrNull
                                      ?.fullName ??
                                  'Member unavailable',
                            ),
                            trailing: Text(p.attendance),
                          ),
                        ),
                      ],
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
