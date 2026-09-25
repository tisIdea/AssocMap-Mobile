import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:assocmap_mobile_app/config/supabase_config.dart';
import 'package:assocmap_mobile_app/models/registration.dart';
import 'package:assocmap_mobile_app/repositories/supabase_assoc_repository.dart';

// Explicit opt-in: the authenticated test creates one persistent demo application.
void main() {
  const live = bool.fromEnvironment('LIVE_SUPABASE_TESTS');
  const email = String.fromEnvironment('SUPABASE_TEST_EMAIL');
  const password = String.fromEnvironment('SUPABASE_TEST_PASSWORD');
  setUp(() {
    if (live) {
      expect(
        SupabaseConfig.valid(SupabaseConfig.url, SupabaseConfig.key),
        isTrue,
        reason:
            'Live tests may use only the authorized AssocMap Development project.',
      );
    }
  });
  test('live public GIS and anonymous privacy', () async {
    final client = sb.SupabaseClient(SupabaseConfig.url, SupabaseConfig.key);
    try {
      final locations = await SupabaseAssocRepository(
        client,
      ).getPublicLocations();
      expect(locations, isNotEmpty);
      expect(locations.every((location) => location.published), isTrue);
      for (final table in ['members', 'member_applications', 'gis_locations']) {
        try {
          final rows = await client.from(table).select('id').limit(1);
          expect(
            rows,
            isEmpty,
            reason: 'Anonymous access must not expose $table',
          );
        } on sb.PostgrestException catch (e) {
          expect(e.code, '42501');
        }
      }
    } finally {
      await client.dispose();
    }
  }, skip: !live);

  test(
    'live demo account login, shared records, persistent pending submission and logout',
    () async {
      final client = sb.SupabaseClient(
        SupabaseConfig.url,
        SupabaseConfig.key,
        authOptions: const sb.AuthClientOptions(autoRefreshToken: false),
      );
      final repository = SupabaseAssocRepository(client);
      try {
        await repository.login(email, password);
        final data = await repository.getMemberData();
        expect(data.association.name, startsWith('Demo '));
        expect(data.projects, isNotEmpty);
        expect(data.trainings, isNotEmpty);
        expect(data.members, isNotEmpty);
        final record = await repository.submitRegistration(
          Registration(
            associationId: 'untrusted-client-value',
            firstName: 'Integration',
            middleName: '',
            lastName: 'Test ${DateTime.now().millisecondsSinceEpoch}',
            birthday: DateTime(1990, 2, 2),
            sex: 'Female',
            beneficiaryType: 'Fisherfolk',
          ),
        );
        expect(record.status, 'Pending');
        expect(record.associationId, data.association.id);
        final refreshed = await repository.getMemberData();
        expect(
          refreshed.registrations.any(
            (r) => r.id == record.id && r.status == 'Pending',
          ),
          isTrue,
        );
        expect(refreshed.members.length, data.members.length);
        await repository.logout();
        expect(client.auth.currentSession, isNull);
      } finally {
        await client.dispose();
      }
    },
    skip: !live || email.isEmpty || password.isEmpty,
  );
}
