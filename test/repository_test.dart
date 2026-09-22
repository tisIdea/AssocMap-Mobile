import 'package:flutter_test/flutter_test.dart';
import 'package:assocmap_mobile_app/models/registration.dart';
import 'package:assocmap_mobile_app/repositories/assoc_repository.dart';
import 'package:assocmap_mobile_app/repositories/mock_assoc_repository.dart';

void main() {
  late MockAssocRepository repository;
  setUp(() => repository = MockAssocRepository(latency: Duration.zero));
  Future<void> login() => repository.login(
    MockAssocRepository.demoEmail,
    MockAssocRepository.demoPassword,
  );
  Registration applicant({
    String associationId = 'assoc-1',
    String firstName = 'Liza',
  }) => Registration(
    associationId: associationId,
    firstName: firstName,
    middleName: '',
    lastName: 'Santos',
    birthday: DateTime(1995, 5, 10),
    sex: 'Female',
    beneficiaryType: 'Fisherfolk',
  );

  test(
    'private records require a session; public data excludes drafts',
    () async {
      await expectLater(
        repository.getMemberData(),
        throwsA(isA<RepositoryException>()),
      );
      final public = await repository.getPublicLocations();
      expect(public, hasLength(2));
      expect(public.every((p) => p.published), isTrue);
      await expectLater(
        repository.login('invalid@example.test', 'wrong'),
        throwsA(isA<RepositoryException>()),
      );
    },
  );
  test(
    'registration stays pending without changing official members',
    () async {
      await login();
      final before = await repository.getMemberData();
      final saved = await repository.submitRegistration(applicant());
      final after = await repository.getMemberData();
      expect(saved.status, 'Pending');
      expect(saved.id, isNotEmpty);
      expect(saved.submittedAt, isNotNull);
      expect(after.members.length, before.members.length);
      expect(after.registrations.length, before.registrations.length + 1);
      await repository.logout();
      await expectLater(
        repository.getMemberData(),
        throwsA(isA<RepositoryException>()),
      );
      await login();
      expect(
        (await repository.getMemberData()).registrations.any(
          (r) => r.id == saved.id,
        ),
        isTrue,
      );
    },
  );
  test(
    'duplicate, blank, and cross-association submissions are rejected',
    () async {
      await login();
      await repository.submitRegistration(applicant());
      await expectLater(
        repository.submitRegistration(applicant(firstName: '  LIZA  ')),
        throwsA(isA<RepositoryException>()),
      );
      await expectLater(
        repository.submitRegistration(applicant(firstName: ' ')),
        throwsA(isA<RepositoryException>()),
      );
      await expectLater(
        repository.submitRegistration(applicant(associationId: 'assoc-2')),
        throwsA(isA<RepositoryException>()),
      );
      expect((await repository.getMemberData()).registrations, hasLength(4));
    },
  );
  test('seed relationships and reviewed states are consistent', () async {
    await login();
    final data = await repository.getMemberData();
    final ids = data.members.map((m) => m.id).toSet();
    expect(
      data.trainings
          .expand((t) => t.participants)
          .every((p) => ids.contains(p.memberId)),
      isTrue,
    );
    expect(
      data.registrations
          .where((r) => r.status == 'Rejected')
          .every((r) => r.rejectionReason!.isNotEmpty),
      isTrue,
    );
    expect(
      data.registrations.map((r) => r.id).toSet().length,
      data.registrations.length,
    );
    expect(() => data.registrations.clear(), throwsUnsupportedError);
  });
}
