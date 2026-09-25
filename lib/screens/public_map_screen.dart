import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
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
  final mapController = MapController();
  String query = '', municipality = 'All', program = 'All';
  bool tilesUnavailable = false;
  int tileAttempt = 0;
  @override
  void initState() {
    super.initState();
    locations = widget.repository.getPublicLocations();
  }

  @override
  void dispose() {
    mapController.dispose();
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
          if (location.commodity != 'Not published')
            'Commodity': location.commodity,
          if (location.activities != 'Not published')
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
                    (program == 'All' || program == p.program) &&
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
                          isExpanded: true,
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
                          isExpanded: true,
                          initialValue: program,
                          decoration: const InputDecoration(
                            labelText: 'Program',
                          ),
                          items: ['All', ...all.map((p) => p.program).toSet()]
                              .map(
                                (s) =>
                                    DropdownMenuItem(value: s, child: Text(s)),
                              )
                              .toList(),
                          onChanged: (s) => setState(() => program = s!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${visible.length} published ${visible.length == 1 ? 'location' : 'locations'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () async {
                      try {
                        final opened = await launchUrl(
                          Uri.parse('https://www.openstreetmap.org/copyright'),
                        );
                        if (!opened) {
                          throw StateError('Cannot open attribution');
                        }
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Open openstreetmap.org/copyright to view attribution.',
                              ),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text(
                      'Map data \u00a9 OpenStreetMap contributors',
                    ),
                  ),
                  if (tilesUnavailable)
                    Column(
                      children: [
                        const Text(
                          'The base map could not load. Published location markers and details are still available.',
                        ),
                        TextButton(
                          onPressed: () => setState(() {
                            tilesUnavailable = false;
                            tileAttempt++;
                          }),
                          child: const Text('Retry base map'),
                        ),
                      ],
                    ),
                  SizedBox(
                    height: 320,
                    child: FlutterMap(
                      mapController: mapController,
                      options: MapOptions(
                        initialCenter: visible.isEmpty
                            ? const LatLng(10.3, 123.8)
                            : LatLng(
                                visible.first.latitude,
                                visible.first.longitude,
                              ),
                        initialZoom: 10,
                      ),
                      children: [
                        TileLayer(
                          key: ValueKey(tileAttempt),
                          evictErrorTileStrategy:
                              EvictErrorTileStrategy.dispose,
                          errorTileCallback: (_, error, stack) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted && !tilesUnavailable) {
                                setState(() => tilesUnavailable = true);
                              }
                            });
                          },
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'org.assocmap.mobile',
                        ),
                        MarkerLayer(
                          markers: visible
                              .map(
                                (p) => Marker(
                                  point: LatLng(p.latitude, p.longitude),
                                  width: 48,
                                  height: 48,
                                  child: IconButton(
                                    tooltip: p.name,
                                    onPressed: () => details(p),
                                    icon: const Icon(
                                      Icons.location_on,
                                      color: Colors.blue,
                                      size: 36,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      if (visible.isNotEmpty) {
                        mapController.move(
                          LatLng(
                            visible.first.latitude,
                            visible.first.longitude,
                          ),
                          10,
                        );
                      }
                    },
                    icon: const Icon(Icons.center_focus_strong),
                    label: const Text('Reset view'),
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
                        subtitle: Text('${p.municipality} • ${p.program}'),
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
