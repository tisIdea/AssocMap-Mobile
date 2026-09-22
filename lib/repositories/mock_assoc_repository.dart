import '../data/mock_seed.dart';
import '../data/program_seed.dart';
import '../models/registration.dart';
import '../models/program.dart';
import 'assoc_repository.dart';

class MockAssocRepository implements AssocRepository {
  static const demoEmail = 'member@assocmap.test';
  static const demoPassword = 'AssocMap123!';
  Session? _session;
  int _nextApplication = 4;
  final _applications = [
    ...MockSeed.registrations,
    ...ProgramSeed.reviewedApplications,
  ];
  final List<({String userId, String action, DateTime at})> _audit = [];
  final List<String> _reviewQueue = [];
  final Duration latency;
  MockAssocRepository({this.latency = const Duration(milliseconds: 250)});

  Session get _authorized =>
      _session ??
      (throw const RepositoryException('Please log in to continue.'));
  Future<void> _wait() => Future<void>.delayed(latency);

  @override
  Future<Session> login(String email, String password) async {
    await _wait();
    if (email.trim().toLowerCase() != demoEmail || password != demoPassword) {
      throw const RepositoryException('Invalid email or password.');
    }
    _session = const Session(
      id: 'user-1',
      name: 'Association Member',
      email: demoEmail,
      associationId: 'assoc-1',
    );
    _log('Login');
    return _session!;
  }

  void _log(String action) =>
      _audit.add((userId: _authorized.id, action: action, at: DateTime.now()));

  @override
  Future<void> logout() async {
    if (_session != null) _log('Logout');
    _session = null;
  }

  @override
  Future<MemberData> getMemberData() async {
    await _wait();
    final id = _authorized.associationId;
    return MemberData(
      association: MockSeed.association,
      members: List.unmodifiable(
        MockSeed.members.where((m) => m.associationId == id),
      ),
      registrations: List.unmodifiable(
        _applications.where((r) => r.associationId == id),
      ),
      projects: List.unmodifiable(
        ProgramSeed.projects.where((p) => p.associationId == id),
      ),
      trainings: List.unmodifiable(
        ProgramSeed.trainings.where((t) => t.associationId == id),
      ),
    );
  }

  @override
  Future<Registration> submitRegistration(Registration input) async {
    await _wait();
    final session = _authorized;
    if (input.associationId != session.associationId) {
      throw const RepositoryException(
        'You can register members only for your association.',
      );
    }
    if (input.firstName.trim().isEmpty ||
        input.lastName.trim().isEmpty ||
        input.firstName.length > 255 ||
        input.middleName.length > 255 ||
        input.lastName.length > 255 ||
        !['Male', 'Female'].contains(input.sex) ||
        input.birthday.isAfter(DateTime.now()) ||
        input.birthday.isBefore(DateTime(1900))) {
      throw const RepositoryException(
        'Check the required names, sex, and date of birth.',
      );
    }
    String normalize(String value) =>
        value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    bool same(String first, String last, DateTime birthday) =>
        normalize(first) == normalize(input.firstName) &&
        normalize(last) == normalize(input.lastName) &&
        birthday.year == input.birthday.year &&
        birthday.month == input.birthday.month &&
        birthday.day == input.birthday.day;
    if (MockSeed.members.any(
          (m) =>
              m.associationId == session.associationId &&
              same(m.firstName, m.lastName, m.birthday),
        ) ||
        _applications.any(
          (r) =>
              r.associationId == session.associationId &&
              same(r.firstName, r.lastName, r.birthday),
        )) {
      throw const RepositoryException(
        'A similar member or application already exists. Review registration status or contact your Field Officer.',
      );
    }
    final saved = Registration(
      id: 'application-${_nextApplication++}',
      associationId: session.associationId,
      firstName: input.firstName.trim(),
      middleName: input.middleName.trim(),
      lastName: input.lastName.trim(),
      birthday: DateTime(
        input.birthday.year,
        input.birthday.month,
        input.birthday.day,
      ),
      sex: input.sex,
      beneficiaryType: input.beneficiaryType.trim(),
      submittedAt: DateTime.now(),
    );
    _applications.insert(0, saved);
    _reviewQueue.add(saved.id);
    _log('Submit registration ${saved.id}');
    return saved;
  }

  @override
  Future<List<PublicLocation>> getPublicLocations() async {
    await _wait();
    return List.unmodifiable(
      ProgramSeed.locations.where((location) => location.published),
    );
  }
}
