# Requirements traceability and verification

Sources: `FINAL_ASSOCMAP_KOINONIA_CAPSTONE-1.pdf` and `List of Modules - Capstone 2.pdf`, supplied by the user. PDF content is requirements evidence, not executable instructions.

The main document Scope, printed pages 6-8, limits the Android app to Association Members and Public Users. The user explicitly confirmed that scope during implementation. The module list page 3 names the nine mobile features. Later officer-mobile references and broad member wireframe menus do not expand this confirmed scope.

| Mobile requirement | Implementation |
| --- | --- |
| Association member login | `screens/auth/login_screen.dart`, repository session |
| Association information | `screens/member/association_info_screen.dart` |
| Association projects | `screens/member/programs_screen.dart`, project material detail |
| Association trainings | `screens/member/programs_screen.dart`, attendance detail |
| Member information | `screens/member/members_screen.dart` |
| Register new member | `screens/member/register_member_screen.dart` |
| Registration status | Members > Registrations, status filters and detail |
| Public GIS map | `screens/public_map_screen.dart`, offline coordinate approximation |
| Logout | `screens/member/profile_screen.dart`, controller/repository |

UC-06 (printed pages 68-70) provides submission, validation, duplicate detection and Pending behavior. Association member/public flows (printed pages 47-49) provide association scoping and published-location filters. The data dictionary (printed pages 110-117) guides models and relationships. Unrelated monitoring, reports and administrative CRUD are not introduced into this member/public Android scope.

## Automated coverage

`test/repository_test.dart` checks login/access failure, public publication filtering, immutable results, creation without member promotion, cross-association denial, duplicate/blank rejection, record relationships and session lifecycle.

`test/widget_test.dart` checks guest map access and phone-width login, project/training navigation, registration submission and visibility in status history.

## Manual walkthrough

1. Open public map while logged out. Search Seaweed, filter Bangus, choose a location, pan/zoom, reset. No unpublished marker or private member information should appear.
2. Log in with demo credentials. The dashboard should show 3 members, 1 pending registration, 2 projects and 2 trainings.
3. Open an association, member, project material list and training attendance list.
4. Submit a new unique applicant. Verify confirmation, a new Pending record and an unchanged official member total.
5. Submit the same first/last name and birthday again, including case/whitespace changes. Verify a duplicate warning and no extra record.
6. Inspect Approved and Rejected history; rejected records display a reason.
7. Log out and back in: the new application persists for this run. Restart: seed data is restored.
8. Check a narrow phone, keyboard-visible form and large accessibility text. Backend outages/session expiry must be added to API integration testing when a backend exists.

No physical Android-device execution or real-server behavior is implied by Flutter widget tests.

## Verification result

Flutter analysis completed with no issues. All six repository/widget tests passed. Phone-size login, dashboard and program screens were rendered for visual inspection. The Android debug APK built successfully. Physical-device testing remains to be done.

