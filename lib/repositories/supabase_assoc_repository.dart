import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../models/association.dart';
import '../models/member.dart';
import '../models/program.dart';
import '../models/registration.dart';
import 'assoc_repository.dart';

class SupabaseAssocRepository
    implements AssocRepository, PersistentSessionRepository {
  final sb.SupabaseClient client;
  SupabaseAssocRepository(this.client);

  @override
  Stream<bool> get sessionChanges =>
      client.auth.onAuthStateChange.map((event) => event.session != null);

  Future<T> _request<T>(Future<T> Function() action) async {
    try {
      return await action().timeout(const Duration(seconds: 25));
    } on RepositoryException {
      rethrow;
    } on sb.AuthException catch (e) {
      if (e.statusCode == '429') {
        throw const RepositoryException(
          'Too many attempts. Please wait and retry.',
        );
      }
      throw const RepositoryException(
        'Sign-in failed. Check your email and password and confirm the account is enabled.',
      );
    } on sb.PostgrestException catch (e) {
      if (e.code == 'PGRST301' || e.code == 'PGRST303') {
        throw const SessionExpiredException();
      }
      if (e.code == '23505') {
        throw const RepositoryException(
          'A member or application already exists for this person.',
        );
      }
      if (e.code == '22023') {
        throw const RepositoryException(
          'Please check the names, birthday, sex and beneficiary type.',
        );
      }
      if (e.code == '42501') {
        throw const AccessRevokedException(
          'Your account cannot perform this action. Contact the administrator.',
        );
      }
      throw const RepositoryException(
        'Association data is unavailable. Check the database setup or retry.',
      );
    } on TimeoutException {
      throw const RepositoryException(
        'The request timed out. Check your connection and refresh before retrying a submission.',
      );
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('AssocMap request failed (${error.runtimeType})\n$stack');
      }
      throw const RepositoryException(
        'Cannot reach AssocMap. Check your internet connection and retry.',
      );
    }
  }

  Future<Session> _profile() async {
    final user = client.auth.currentUser;
    if (user == null) throw const SessionExpiredException();
    final p = await client
        .from('users')
        .select(
          'id,name,email,association_id,roles!users_role_id_fkey(role_name)',
        )
        .eq('auth_user_id', user.id)
        .eq('is_active', true)
        .maybeSingle();
    if (p == null ||
        p['roles']?['role_name'] != 'Association Member' ||
        p['association_id'] == null) {
      throw const AccessRevokedException(
        'This login is not linked to an active Association Member account. Contact the administrator.',
      );
    }
    final association = await client
        .from('associations')
        .select('id')
        .eq('id', p['association_id'])
        .eq('is_archived', false)
        .maybeSingle();
    if (association == null) {
      throw const AccessRevokedException(
        'Your association is unavailable. Contact the administrator.',
      );
    }
    return Session(
      id: '${p['id']}',
      name: p['name'],
      email: p['email'],
      associationId: '${p['association_id']}',
    );
  }

  @override
  Future<Session?> restoreSession() => _request(() async {
    if (client.auth.currentSession == null) return null;
    if (client.auth.currentSession!.isExpired) {
      await client.auth.refreshSession();
    }
    return _profile();
  });

  @override
  Future<Session> login(String email, String password) => _request(() async {
    await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    try {
      return await _profile();
    } catch (_) {
      await client.auth.signOut(scope: sb.SignOutScope.local);
      rethrow;
    }
  });

  @override
  Future<void> logout() =>
      _request(() => client.auth.signOut(scope: sb.SignOutScope.local));

  static String _label(
    Map<String, dynamic> row,
    String relation,
    String field, [
    String fallback = 'Not recorded',
  ]) => row[relation]?[field]?.toString() ?? fallback;
  static DateTime? _date(dynamic value) =>
      value == null ? null : DateTime.tryParse('$value');
  static double? _number(dynamic value) =>
      value == null ? null : double.tryParse('$value');
  static Registration registration(Map<String, dynamic> r) => Registration(
    id: '${r['id']}',
    associationId: '${r['association_id']}',
    firstName: r['first_name'],
    middleName: r['middle_name'] ?? '',
    lastName: r['last_name'],
    birthday: DateTime.parse(r['birthday']),
    sex: _label(r, 'sex', 'sex_name'),
    beneficiaryType: r['beneficiary_type'] ?? '',
    status: _label(r, 'statuses', 'status_name'),
    submittedAt: _date(r['created_at']),
    reviewedAt: _date(r['reviewed_at']),
    rejectionReason: r['rejection_reason'],
  );

  @override
  Future<MemberData> getMemberData() => _request(() async {
    final profile = await _profile();
    final id = profile.associationId;
    final results = await Future.wait<dynamic>([
      client
          .from('associations')
          .select(
            'id,name,address,area_units(name),sub_units(name),program_components(name),statuses(status_name)',
          )
          .eq('id', id)
          .single(),
      client
          .from('members')
          .select(
            'id,association_id,first_name,middle_name,last_name,birthday,sex(sex_name),role_in_assoc,beneficiary_type,is_archived',
          )
          .eq('association_id', id)
          .eq('is_archived', false)
          .order('last_name'),
      client
          .from('member_applications')
          .select(
            'id,association_id,first_name,middle_name,last_name,birthday,sex(sex_name),beneficiary_type,statuses(status_name),created_at,reviewed_at,rejection_reason',
          )
          .eq('association_id', id)
          .order('created_at', ascending: false),
      client
          .from('projects')
          .select(
            'id,association_id,title,commodity_type,implementation_date,program_components(name),statuses(status_name),project_materials(id,item_name,unit,quantity,unit_cost,delivery_date,statuses(status_name))',
          )
          .eq('association_id', id)
          .eq('is_archived', false)
          .order('id'),
      client
          .from('trainings')
          .select(
            'id,association_id,title,date_conducted,training_cost,program_components(name),training_participants(member_id,statuses(status_name))',
          )
          .eq('association_id', id)
          .eq('is_archived', false)
          .order('id'),
    ]);
    final a = results[0] as Map<String, dynamic>;
    final members = (results[1] as List)
        .map(
          (m) => Member(
            id: '${m['id']}',
            associationId: '${m['association_id']}',
            firstName: m['first_name'],
            middleName: m['middle_name'] ?? '',
            lastName: m['last_name'],
            birthday: DateTime.parse(m['birthday']),
            sex: _label(m, 'sex', 'sex_name'),
            roleInAssociation: m['role_in_assoc'] ?? 'Member',
            beneficiaryType: m['beneficiary_type'] ?? '',
            status: 'Active',
          ),
        )
        .toList();
    return MemberData(
      association: Association(
        id: '${a['id']}',
        name: a['name'],
        municipality: _label(a, 'area_units', 'name'),
        barangay: _label(a, 'sub_units', 'name'),
        address: a['address'] ?? '',
        programType: _label(a, 'program_components', 'name'),
        memberCount: members.length,
        status: _label(a, 'statuses', 'status_name'),
      ),
      members: members,
      registrations: (results[2] as List)
          .map((r) => registration(Map<String, dynamic>.from(r)))
          .toList(),
      projects: (results[3] as List)
          .map(
            (p) => Project(
              id: '${p['id']}',
              associationId: '${p['association_id']}',
              title: p['title'],
              commodity: p['commodity_type'] ?? 'Not recorded',
              component: _label(p, 'program_components', 'name'),
              status: _label(p, 'statuses', 'status_name'),
              implementationDate: _date(p['implementation_date']),
              materials: (p['project_materials'] as List? ?? [])
                  .map(
                    (m) => ProjectMaterial(
                      id: '${m['id']}',
                      name: m['item_name'],
                      unit: m['unit'] ?? '',
                      status: _label(m, 'statuses', 'status_name'),
                      quantity: _number(m['quantity']) ?? 0,
                      unitCost: _number(m['unit_cost']),
                      deliveryDate: _date(m['delivery_date']),
                    ),
                  )
                  .toList(),
            ),
          )
          .toList(),
      trainings: (results[4] as List)
          .map(
            (t) => Training(
              id: '${t['id']}',
              associationId: '${t['association_id']}',
              title: t['title'],
              component: _label(t, 'program_components', 'name'),
              date: _date(t['date_conducted']),
              cost: _number(t['training_cost']),
              participants: (t['training_participants'] as List? ?? [])
                  .map(
                    (p) => TrainingParticipant(
                      '${p['member_id']}',
                      _label(p, 'statuses', 'status_name'),
                    ),
                  )
                  .toList(),
            ),
          )
          .toList(),
    );
  });

  @override
  Future<Registration> submitRegistration(
    Registration input,
  ) => _request(() async {
    final sex = await client
        .from('sex')
        .select('id')
        .eq('sex_name', input.sex)
        .single();
    final result = await client.rpc(
      'submit_member_registration',
      params: {
        'first_name': input.firstName,
        'middle_name': input.middleName,
        'last_name': input.lastName,
        'birthday': input.birthday.toIso8601String().substring(0, 10),
        'sex_id': sex['id'],
        'beneficiary_type': input.beneficiaryType,
      },
    );
    final row = result is List ? result.single : result;
    // The transaction assigns Pending; no approval or association fields are accepted from the UI.
    return registration({
      ...Map<String, dynamic>.from(row),
      'sex': {'sex_name': input.sex},
      'statuses': {'status_name': 'Pending'},
    });
  });

  @override
  Future<List<PublicLocation>> getPublicLocations() => _request(() async {
    final rows = await client.rpc('public_locations');
    return (rows as List)
        .map(
          (p) => PublicLocation(
            id: '${p['id']}',
            associationId: '${p['association_id']}',
            name: p['location_name'] ?? p['association_name'],
            associationName: p['association_name'],
            municipality: p['municipality'],
            barangay: p['barangay'] ?? '',
            commodity: 'Not published',
            program: p['program'] ?? 'Not recorded',
            activities: 'Not published',
            latitude: _number(p['latitude'])!,
            longitude: _number(p['longitude'])!,
            published: p['is_published'] == true,
          ),
        )
        .toList();
  });
}
