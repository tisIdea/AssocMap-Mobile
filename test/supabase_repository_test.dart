import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:assocmap_mobile_app/config/supabase_config.dart';
import 'package:assocmap_mobile_app/models/registration.dart';
import 'package:assocmap_mobile_app/repositories/assoc_repository.dart';
import 'package:assocmap_mobile_app/repositories/supabase_assoc_repository.dart';

void main() {
  late sb.SupabaseClient client;
  late SupabaseAssocRepository repository;
  final requests = <http.Request>[];
  String? failure;
  final applicant = <String, dynamic>{
    'id': 12,
    'association_id': 7,
    'first_name': 'Lina',
    'last_name': 'Demo',
    'birthday': '1990-01-01',
    'created_at': '2026-09-25T00:00:00Z',
    'sex': {'sex_name': 'Female'},
    'statuses': {'status_name': 'Pending'},
  };
  setUp(() {
    failure = null;
    requests.clear();
    client = sb.SupabaseClient(
      'https://example.supabase.co',
      'client-test-key',
      authOptions: const sb.AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        requests.add(request);
        dynamic result;
        final path = request.url.path;
        if (failure != null && path.contains('/rpc/')) {
          return http.Response(
            jsonEncode({'code': failure, 'message': 'private SQL diagnostic'}),
            403,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }
        if (path == '/auth/v1/token') {
          final payload = base64Url
              .encode(
                utf8.encode(
                  jsonEncode({
                    'sub': '11111111-1111-1111-1111-111111111111',
                    'exp':
                        DateTime.now()
                            .add(const Duration(hours: 1))
                            .millisecondsSinceEpoch ~/
                        1000,
                  }),
                ),
              )
              .replaceAll('=', '');
          result = {
            'access_token': 'e30.$payload.signature',
            'token_type': 'bearer',
            'expires_in': 3600,
            'refresh_token': 'test-refresh',
            'user': {
              'id': '11111111-1111-1111-1111-111111111111',
              'email': 'member@assocmap.test',
              'aud': 'authenticated',
              'created_at': '2026-01-01T00:00:00Z',
              'app_metadata': {},
              'user_metadata': {},
            },
          };
        } else if (path.endsWith('/users')) {
          result = {
            'id': 2,
            'name': 'Shared account',
            'email': 'member@assocmap.test',
            'association_id': 7,
            'roles': {'role_name': 'Association Member'},
          };
        } else if (path.endsWith('/associations')) {
          result = {
            'id': 7,
            'name': 'Pilot association',
            'area_units': {'name': 'Cordova'},
            'statuses': {'status_name': 'Active'},
          };
        } else if (path.endsWith('/members')) {
          result = [
            {
              ...applicant,
              'id': 3,
              'role_in_assoc': null,
              'is_archived': false,
            },
          ];
        } else if (path.endsWith('/member_applications')) {
          result = [applicant];
        } else if (path.endsWith('/projects')) {
          result = [
            {
              'id': 5,
              'association_id': 7,
              'title': 'Pilot project',
              'project_materials': [
                {
                  'id': 1,
                  'item_name': 'Nets',
                  'quantity': '2.50',
                  'unit_cost': null,
                },
              ],
            },
          ];
        } else if (path.endsWith('/trainings')) {
          result = [
            {
              'id': 6,
              'association_id': 7,
              'title': 'Pilot training',
              'training_participants': [
                {
                  'member_id': 3,
                  'statuses': {'status_name': 'Present'},
                },
              ],
            },
          ];
        } else if (path.endsWith('/sex')) {
          result = {'id': 2};
        } else if (path.endsWith('/submit_member_registration')) {
          result = applicant;
        } else if (path.endsWith('/public_locations')) {
          result = [
            {
              'id': 1,
              'association_id': 7,
              'location_name': 'Published site',
              'association_name': 'Pilot association',
              'municipality': 'Cordova',
              'latitude': '10.25',
              'longitude': 123.95,
              'is_published': true,
            },
          ];
        } else if (path == '/auth/v1/logout') {
          result = {};
        } else {
          fail('Unexpected request path: $path');
        }
        return http.Response(
          jsonEncode(result),
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    repository = SupabaseAssocRepository(client);
  });
  tearDown(() async {
    await client.dispose();
  });

  test(
    'SDK login resolves shared profile; scoped reads map nullable dates and numeric values',
    () async {
      final session = await repository.login(
        ' member@assocmap.test ',
        'local-test-password',
      );
      expect(session.associationId, '7');
      final data = await repository.getMemberData();
      expect(data.association.name, 'Pilot association');
      expect(data.members.single.middleName, '');
      expect(data.projects.single.materials.single.quantity, 2.5);
      expect(data.projects.single.materials.single.unitCost, isNull);
      expect(data.trainings.single.date, isNull);
      expect(data.registrations.single.status, 'Pending');
      for (final r in requests.where(
        (r) => [
          '/members',
          '/member_applications',
          '/projects',
          '/trainings',
        ].any((t) => r.url.path.endsWith(t)),
      )) {
        expect(r.url.queryParameters['association_id'], 'eq.7');
      }
      await repository.logout();
      expect(client.auth.currentSession, isNull);
      expect(await repository.restoreSession(), isNull);
    },
  );

  test(
    'submission cannot send caller-supplied association, approval, or reviewer fields',
    () async {
      final result = await repository.submitRegistration(
        Registration(
          associationId: '999',
          firstName: 'Lina',
          middleName: '',
          lastName: 'Demo',
          birthday: DateTime(1990),
          sex: 'Female',
          beneficiaryType: '',
          status: 'Approved',
        ),
      );
      final body = jsonDecode(requests.last.body) as Map;
      expect(
        body.keys,
        unorderedEquals([
          'first_name',
          'middle_name',
          'last_name',
          'birthday',
          'sex_id',
          'beneficiary_type',
        ]),
      );
      expect(result.status, 'Pending');
      expect(result.associationId, '7');
    },
  );

  test(
    'public map uses only published projection RPC without a session',
    () async {
      expect(client.auth.currentSession, isNull);
      final locations = await repository.getPublicLocations();
      expect(locations.single.latitude, 10.25);
      expect(locations.single.published, isTrue);
      expect(requests.single.url.path, '/rest/v1/rpc/public_locations');
    },
  );

  test('database diagnostics are replaced with safe errors', () async {
    failure = '42501';
    await expectLater(
      repository.getPublicLocations(),
      throwsA(
        isA<RepositoryException>().having(
          (e) => e.message,
          'safe message',
          isNot(contains('SQL diagnostic')),
        ),
      ),
    );
  });

  test(
    'client config rejects secret keys and accepts only client key types',
    () {
      expect(
        SupabaseConfig.valid(
          'https://kdyfhxwsxokwagpwvedq.supabase.co',
          'sb_secret_test',
        ),
        isFalse,
      );
      expect(
        SupabaseConfig.valid(
          'https://unrelated.supabase.co',
          'sb_publishable_test',
        ),
        isFalse,
      );
      final role = base64Url.encode(utf8.encode('{"role":"service_role"}'));
      expect(
        SupabaseConfig.valid(
          'https://kdyfhxwsxokwagpwvedq.supabase.co',
          'e30.$role.signature',
        ),
        isFalse,
      );
      expect(
        SupabaseConfig.valid(
          'https://kdyfhxwsxokwagpwvedq.supabase.co',
          'sb_publishable_test',
        ),
        isTrue,
      );
      expect(
        SupabaseConfig.valid(
          'http://kdyfhxwsxokwagpwvedq.supabase.co',
          'sb_publishable_test',
        ),
        isFalse,
      );
    },
  );
}
