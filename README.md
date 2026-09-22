# AssocMap mobile prototype

Flutter Android prototype for Association Members and Public Users. No database, backend, external API, network map tiles, or extra package dependencies are used.

## Run

```sh
flutter pub get
flutter run
flutter test
flutter analyze
flutter build apk --debug
```

Demo shared account: `member@assocmap.test` / `AssocMap123!`.
Select **Explore public map** for unauthenticated guest access.
These are public demo credentials, not production credentials.

## Implemented mobile scope

- Shared association account login and logout.
- Association information with member totals computed from actual records.
- Project search, status filters, details, quantities, material costs and delivery status.
- Training search, details, costs, participants and attendance.
- Association member search and personal information.
- Member registration with required-field/date validation and duplicate detection.
- Registration history, Pending/Approved/Rejected filters, review dates and rejection reasons.
- Public location search, municipality/commodity filtering, marker selection, pan and zoom.
- Loading, empty, retry and validation states.

Member accounts cannot edit/archive official records or approve applications. Those operations belong to the web administrator/Field Officer workflows. The mobile repository intentionally exposes only permitted reads and registration creation; unrestricted CRUD would violate the confirmed mobile scope.

## Prototype boundaries

All people, projects, attendance, costs and coordinates are fictional demonstration data based on the documented record types. The pilot association is a fictional Cordova fisherfolk association. It has three official members; counts are not inflated to imitate a real dataset.

Data is in memory. Submitted registrations survive logout/login within the same app instance and reset on restart. Reviewed seed examples demonstrate approved/rejected states; newly submitted records remain Pending until a future officer backend processes them. The review queue and audit events are local only; no notification is sent.

The map is an offline latitude/longitude preview of the mock sites, not a geographic basemap or navigation tool. It uses a fixed coordinate extent around the demo sites. A real map adapter and geographic tiles remain future work, subject to the no-external-API constraint being lifted or a bundled offline map being supplied.

The prototype authentication and association checks demonstrate access boundaries but are not production security. A real backend must enforce authentication, association scope, validation and publication restrictions independently.

See [architecture and defense guide](docs/ARCHITECTURE.md) and [requirements and verification](docs/REQUIREMENTS.md).
