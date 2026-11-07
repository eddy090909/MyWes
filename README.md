# MyWes

A SwiftUI campus app for Wesleyan students, backed by Supabase Auth and PostgreSQL. Discover events and organizations, save events, follow organizations, check dining schedules, and ask or answer campus questions.

## Status

This is an MVP under verification, not an App Store release. Events, organizations, saves, follows, onboarding, and Google OAuth were already integrated. The November 2026 implementation adds real Supabase Q&A, dining schedules, profile editing, and sign-out. The MVP migration has been applied to the existing hosted project. Google OAuth is configured in the hosted project; live flows must be verified before describing the full MVP as working. See [verification](docs/VERIFICATION.md).

There is no guest login or production authentication bypass. Sample data is used in SwiftUI previews. Onboarding offers static year and interest choices.

## Run locally

1. Install Xcode with an iOS 26.5 or newer simulator. Current verification uses Xcode 27.2. Open `MyWes/MyWes.xcodeproj` and select the MyWes scheme.
2. Copy `MyWes/Config/Secrets.example.xcconfig` to `MyWes/Config/Secrets.xcconfig` (ignored by Git).
3. Set `SUPABASE_URL` and `SUPABASE_ANON_KEY` to your project's HTTPS URL and **publishable/anon** key. In xcconfig files write the URL as `https:/$()/PROJECT.supabase.co` so `//` is not parsed as a comment. Do not put a service-role key, `sb_secret_` key, Google client secret, or database password in the app.
4. Apply `supabase/migrations` in filename order to your own Supabase project. For an existing project, inspect its migration history and apply only missing migrations. Never reset a hosted database to set up the app. `supabase/seed.sql` is sample catalog content, not a live event feed.
5. In Supabase Authentication → Providers enable Google with the Google OAuth web client. Register the Supabase callback URL shown in that dashboard in Google Cloud. Keep the OAuth client secret on Supabase only.
6. In Authentication → URL Configuration allow the exact redirect `mywes://auth-callback`.
7. In Authentication → Hooks enable **Before User Created** with `public.hook_restrict_wesleyan_email`. The SQL function existing in the database does not enable the hosted hook automatically. Keep anonymous sign-in disabled and disable Email/password signup for this Google-only app.
8. Run the app and sign in with an `@wesleyan.edu` Google account. Workspace administrator restrictions may require approval from Wesleyan; do not bypass them. Supabase persists the session in Keychain.

## Architecture and data

`AppSession` owns authentication, profile, engagement state, `CampusCatalog`, and `CommunityStore`. Views use the existing SwiftUI design system and async Supabase services. RLS controls access even when requests are made outside the app.

- Catalog: authenticated read-only events and organizations; maintain actual campus records through trusted backend tooling.
- Engagement: each student can read/write only their own follows and event saves. Writes are optimistic, roll back on failure, and serialize per item.
- Profile: students can read their own profile and update only editable profile columns. Auth identity is provisioned on the server.
- AskWes: authenticated campus readership, database-assigned authorship, student-authored questions and answers, author-only deletion. No public profile or email lookup. List/detail requests show up to 100 records; title search queries the server and returns up to 100 matches. Voting, attachments, notifications, and moderation tooling are not implemented.
- Dining: authenticated read-only schedules for Usdan Marketplace, Summerfields, and Usdan Café. Initial regular semester hours were checked against [Wesleyan's official hours](https://www.wesleyan.edu/dining/Hours%20of%20Operation.html) and [location information](https://www.wesleyan.edu/dining/placestoeat.html) on November 7, 2026. The app calculates **scheduled** open status in Eastern Time, including overnight service. This is not a real-time availability feed. Break exceptions must be checked on the official site. Schedules expire November 20, 2026; after expiry the app asks users to check official hours. A trusted maintainer must reverify schedules and advance validity dates. No fabricated ratings or occupancy.

## Checks

Build with local simulator signing (required for live Keychain/PKCE login checks):

```sh
xcodebuild -project MyWes/MyWes.xcodeproj -scheme MyWes -sdk iphonesimulator -configuration Debug -derivedDataPath /tmp/MyWesMVPDerivedData CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES CODE_SIGNING_REQUIRED=YES build
```

Dining logic (actual production models):

```sh
swiftc -module-cache-path /tmp/mywes-swift-module-cache MyWes/MyWes/Models/CampusContent.swift Tests/DiningTests.swift -o /tmp/mywes-dining-tests
/tmp/mywes-dining-tests
```

Database response/request formats (actual production wire models):

```sh
swiftc -module-cache-path /tmp/mywes-swift-module-cache MyWes/MyWes/Models/DatabaseRecords.swift MyWes/MyWes/Models/CampusContent.swift Tests/DatabaseCodingTests.swift -o /tmp/mywes-coding-tests
/tmp/mywes-coding-tests
```

Authentication error classification:

```sh
swiftc -module-cache-path /tmp/mywes-swift-module-cache MyWes/MyWes/Models/AuthFailureMessage.swift Tests/AuthFailureTests.swift -o /tmp/mywes-auth-failure-tests
/tmp/mywes-auth-failure-tests
```

Database migrations and permissions (isolated PostgreSQL via PGlite):

```sh
npm install --prefix Tests
npm test --prefix Tests
```

These tests create synthetic Auth roles/users in a temporary database, apply all migrations, and exercise access as two different students and an anonymous user. They do not prove hosted OAuth, dashboard settings, or iPhone behavior. See the manual checks in `docs/VERIFICATION.md`.

## Repository hygiene

`Secrets.xcconfig`, Xcode user state, Supabase CLI local state, and `.local-assets/` are ignored. The local design handoff is preserved in `.local-assets/design_handoff_wesiq 2/`, outside the app target; it is not part of the repository or app bundle. No license grant has been selected yet. Visibility changes and pushes require the owner's approval.
