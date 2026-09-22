import 'package:flutter/material.dart';

String dateLabel(DateTime? date) => date == null
    ? 'Not recorded'
    : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

class RecordDetails extends StatelessWidget {
  final String title;
  final Map<String, String> fields;
  final List<Widget> children;
  const RecordDetails({
    super.key,
    required this.title,
    required this.fields,
    this.children = const [],
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ...fields.entries.map(
              (entry) => Card(
                child: ListTile(
                  title: Text(entry.key),
                  subtitle: SelectableText(entry.value),
                ),
              ),
            ),
            ...children,
          ],
        ),
      ),
    ),
  );
}

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge(this.status, {super.key});
  @override
  Widget build(BuildContext context) => Chip(
    label: Text(status),
    backgroundColor: status == 'Rejected'
        ? Colors.red.shade50
        : status == 'Pending'
        ? Colors.orange.shade50
        : Colors.blue.shade50,
    side: BorderSide.none,
  );
}
