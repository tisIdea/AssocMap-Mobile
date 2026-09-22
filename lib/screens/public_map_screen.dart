import 'package:flutter/material.dart';
import '../models/program.dart';
import '../repositories/assoc_repository.dart';
import '../widgets/record_details.dart';

class PublicMapScreen extends StatefulWidget {
  final AssocRepository repository;
  const PublicMapScreen({super.key, required this.repository});
  @override
  State<PublicMapScreen> createState() => _PublicMapScreenState();
}

class _PublicMapScreenState extends State<PublicMapScreen> {
  late Future<List<PublicLocation>> locations;
  final transformation = TransformationController();
  String query = '', municipality = 'All', commodity = 'All';
  @override
  void initState() {
    super.initState();
    locations = widget.repository.getPublicLocations();
  }

  @override
  void dispose() {
    transformation.dispose();
    super.dispose();
  }

  void details(PublicLocation location) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => RecordDetails(
        title: 'Published location',
        fields: {
          'Location': location.name,
          'Association': location.associationName,
          'Area': '${location.barangay}, ${location.municipality}, Cebu',
          'Program': location.program,
          'Commodity': location.commodity,
          'Activities': location.activities,
          'Latitude': location.latitude.toStringAsFixed(6),
          'Longitude': location.longitude.toStringAsFixed(6),
        },
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Public GIS map')),
    body: SafeArea(
      child: FutureBuilder<List<PublicLocation>>(
        future: locations,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Unable to load published locations.'),
                  FilledButton(
                    onPressed: () => setState(
                      () => locations = widget.repository.getPublicLocations(),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          final all = snapshot.data ?? [];
          final visible = all
              .where(
                (p) =>
                    (municipality == 'All' || municipality == p.municipality) &&
                    (commodity == 'All' || commodity == p.commodity) &&
                    '${p.name} ${p.associationName} ${p.program} ${p.activities}'
                        .toLowerCase()
                        .contains(query.toLowerCase()),
              )
              .toList();
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 840),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Explore published program locations',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (v) => setState(() => query = v.trim()),
                    decoration: const InputDecoration(
                      labelText: 'Search locations or activities',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: 200,
                        child: DropdownButtonFormField<String>(
                          initialValue: municipality,
                          decoration: const InputDecoration(
                            labelText: 'Municipality',
                          ),
                          items:
                              ['All', ...all.map((p) => p.municipality).toSet()]
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (s) => setState(() => municipality = s!),
                        ),
                      ),
                      SizedBox(
                        width: 200,
                        child: DropdownButtonFormField<String>(
                          initialValue: commodity,
                          decoration: const InputDecoration(
                            labelText: 'Commodity',
                          ),
                          items: ['All', ...all.map((p) => p.commodity).toSet()]
                              .map(
                                (s) =>
                                    DropdownMenuItem(value: s, child: Text(s)),
                              )
                              .toList(),
                          onChanged: (s) => setState(() => commodity = s!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Offline coordinate preview • Fictional sites, no live basemap. Pinch to zoom and drag to pan.',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 320,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return InteractiveViewer(
                            transformationController: transformation,
                            minScale: 1,
                            maxScale: 5,
                            child: SizedBox(
                              width: constraints.maxWidth,
                              height: 320,
                              child: Stack(
                                children: [
                                  const Positioned.fill(
                                    child: CustomPaint(
                                      painter: _CoordinateGrid(),
                                    ),
                                  ),
                                  ...visible.map(
                                    (p) => Positioned(
                                      left:
                                          ((p.longitude - 123.92) / 0.06) *
                                              constraints.maxWidth -
                                          24,
                                      top:
                                          ((10.28 - p.latitude) / 0.06) * 320 -
                                          24,
                                      child: IconButton(
                                        tooltip: p.name,
                                        onPressed: () => details(p),
                                        iconSize: 36,
                                        icon: Icon(
                                          Icons.location_on,
                                          color: p.commodity == 'Bangus'
                                              ? Colors.blue.shade800
                                              : Colors.teal.shade800,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () =>
                          transformation.value = Matrix4.identity(),
                      icon: const Icon(Icons.center_focus_strong),
                      label: const Text('Reset view'),
                    ),
                  ),
                  Text(
                    '${visible.length} published locations',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (visible.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No published locations match your search or filters.',
                      ),
                    ),
                  ...visible.map(
                    (p) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.location_on_outlined),
                        title: Text(p.name),
                        subtitle: Text('${p.municipality} • ${p.commodity}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => details(p),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _CoordinateGrid extends CustomPainter {
  const _CoordinateGrid();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFE7F2F5),
    );
    final line = Paint()
      ..color = const Color(0xFFB3CED5)
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final x = size.width * i / 4;
      final y = size.height * i / 4;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
      final label = TextPainter(
        text: TextSpan(
          text: '${(10.28 - .06 * i / 4).toStringAsFixed(3)}° N',
          style: const TextStyle(color: Color(0xFF365A68), fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, Offset(4, y.clamp(4, size.height - 16)));
    }
    final label = TextPainter(
      text: const TextSpan(
        text: '123.920° E                         123.980° E   •   N ↑',
        style: TextStyle(color: Color(0xFF365A68), fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 12);
    label.paint(canvas, Offset(6, size.height - 30));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
