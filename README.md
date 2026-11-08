<div align="center">

# MyWes

### Your Wesleyan, all in one place.

An iOS campus companion for discovering events, finding communities, checking dining, and getting answers from fellow students.

**SwiftUI · Supabase · PostgreSQL · Google OAuth**

[Features](#features) · [Engineering](#engineering) · [Run locally](#run-locally) · [Verification](docs/VERIFICATION.md)

</div>

---

MyWes brings everyday campus tasks into one app. Students can find an upcoming event, save it for later, follow its host organization, check a dining location, or ask the campus community a question—all through a Wesleyan Google account.

## Features

| | What students can do |
| --- | --- |
| **Discover** | Browse campus events and organizations, open their details, and search the loaded catalog. |
| **Save & follow** | Save events and follow organizations, with preferences persisted across app launches. Home surfaces upcoming events from followed organizations. |
| **AskWes** | Post questions, answer other students, search question titles, and delete their own contributions. |
| **Dining** | Check published hours for Usdan Marketplace, Summerfields, and Usdan Café, with Eastern Time schedule status and official menu pages available inside the app. |
| **Profile & onboarding** | Set class year and interests, edit profile information, and access saved events and followed organizations. |
| **Wesleyan sign-in** | Authenticate with Google through Supabase, with secure session storage and a server-side Wesleyan email restriction. |

## Engineering

Built in **Swift** and **SwiftUI**, with **Supabase Auth** and **PostgreSQL** supporting persistent campus and student data.

- **Shared application state:** `AppSession` coordinates authentication, profile, catalog, and community services using Swift Observation and asynchronous data access.
- **Responsive engagement:** saves and follows update optimistically, roll back on failure, and serialize changes per item to avoid conflicting writes.
- **Database-enforced access:** PostgreSQL row-level security protects student-owned saves, follows, profiles, and Q&A writes. The database assigns Q&A authorship; students can delete only their own contributions.
- **Secure authentication:** Google OAuth uses PKCE and Keychain-backed session storage. Provider secrets stay on the backend; the app uses a publishable/anon key.
- **Time-aware dining:** schedule calculations handle Eastern Time, overnight service, and expiration dates so outdated schedules do not claim a location is open.

## Project status

**Working iOS MVP, available as source.** MyWes is not currently distributed through the App Store or TestFlight. Running it requires Xcode and a configured Supabase backend. The hosted Google OAuth app is in Testing, so access currently requires an approved Wesleyan test account.

Real login, session restoration, event and organization browsing, persistent saves/follows, Q&A creation/search/deletion, profile saving, and dining schedules have been exercised against hosted Supabase in the iPhone simulator. Signed Debug and Release builds passed during MVP verification. Local checks cover database serialization, authentication errors, dining calculations, and 37 database permission/persistence assertions.

Dining menus open the official Bon Appétit website inside the app; native menu ingestion and reviews are future work. The new menu sheet has passed a Debug build but still needs simulator interaction testing. Catalog content is maintained through the backend rather than an automatic campus feed. Physical-device testing and additional failure-path checks remain on the roadmap.

See [verification notes](docs/VERIFICATION.md) for the scope and limits of completed checks.

## Run locally

1. Open `MyWes/MyWes.xcodeproj` in Xcode and select the **MyWes** scheme. The project currently targets **iOS 26.5**.
2. Copy `MyWes/Config/Secrets.example.xcconfig` to `MyWes/Config/Secrets.xcconfig` and supply your Supabase URL and publishable/anon key.
3. Apply the included database migrations to your own Supabase project, configure Google OAuth and the Wesleyan email hook, and allow the `mywes://auth-callback` redirect.
4. Build and run on a compatible simulator, then sign in with an authorized `@wesleyan.edu` Google account.

The [development guide](docs/DEVELOPMENT.md) includes complete backend setup, secret handling, architecture details, and test commands.

## Author

Built by [Edomias Zerihun](https://github.com/eddy090909).
