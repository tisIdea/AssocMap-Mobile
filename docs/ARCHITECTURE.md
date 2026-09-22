# Architecture and defense guide

## Data flow

```text
Flutter screens -> AppController -> AssocRepository interface
                                      |
                              MockAssocRepository
                                      |
                             MockSeed / ProgramSeed
```

`lib/main.dart` is the composition root: it creates one repository and controller for the app. This is where the concrete data provider is selected.

- `lib/models/`: association, member, application, project/material, training/attendance and public-location records.
- `lib/data/mock_seed.dart`: pilot association, official members and a pending application.
- `lib/data/program_seed.dart`: projects, materials, trainings, attendance, reviewed applications and map locations.
- `lib/repositories/assoc_repository.dart`: asynchronous contract, session and aggregate member data. UI code depends on this contract, not mock lists.
- `lib/repositories/mock_assoc_repository.dart`: mock login, authenticated/scoped retrieval, validation, unique application IDs, duplicate detection, review queue and local audit events. Private collections are returned as unmodifiable lists.
- `lib/controllers/app_controller.dart`: session state, loading/error handling, refresh and submission orchestration. ChangeNotifier tells Flutter when to rebuild.
- `lib/screens/`: user interactions and rendering. The public map uses the public-only repository method and never loads member records.
- `lib/widgets/`: reusable record details, date formatting, status badges and statistics.

## Explain a registration during the defense

1. The user enters a name, birthday, sex and optional beneficiary classification.
2. The form checks required inputs; the repository checks validity and association authorization again.
3. The repository compares normalized first/last names plus birthday with existing members and applications. Similar records are blocked for officer follow-up; this is a conservative prototype policy, not proof that two people are identical.
4. A new application gets a unique local ID, association ID, timestamp and Pending status. The client cannot select Approved.
5. Local audit and review-queue entries are added. No real notification is delivered.
6. The controller reloads member data and notifies screens. The application is visible in registration history, while official member count is unchanged.

IDs preserve relationships: projects reference associations; materials belong to projects; training participants reference existing member IDs; applications reference associations. Registration input can have an empty ID because the repository assigns it when saved.

## Backend replacement

1. Implement `AssocRepository` as an API-backed repository in `lib/repositories/`. Keep the same method signatures and domain models.
2. Add explicit JSON/request DTO conversion for the actual API schema, including status/sex lookup IDs and ISO date handling. Those mappings are intentionally not fabricated before an API contract exists.
3. Change the repository construction in `lib/main.dart`. Screens and controller continue using the interface.
4. Have the server derive association scope from the authenticated account. Never trust a client association ID or approved status.
5. Implement secure session/token storage, session expiry, active-account checks and backend login/logout. Remove the demo credentials from the login presentation.
6. Move validation, duplicate checks, ID generation, application creation, review notification and audit logging into a server transaction. Backend review must promote approved applications to members exactly once and retain rejected requests with reasons.
7. Return only published, authorized public fields from the map endpoint. Replace the offline coordinate viewport with a geographic map adapter when authorized.

The future server should support the capstone Laravel/PostgreSQL design, but no schema, migrations, server, token or live connection is created here.

## Why this structure

A repository is the boundary between app behavior and data storage. The controller coordinates work; widgets display state. This keeps a data-source change from forcing a screen rewrite without adding a state-management dependency or complex framework.

In-memory storage is deliberately temporary. It avoids storing personal test data on disk and is replaceable. It does not claim the capstone supports offline production synchronization.
