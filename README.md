<div align="center">

# MyWes

### Your Wesleyan, all in one place.

An iOS campus companion for dining, events, Wesleyan resource hours, and advice from the Wes community.

**SwiftUI · Supabase · PostgreSQL · Google OAuth**

[Product vision](#product-vision) · [Engineering](#engineering) · [Run locally](#run-locally) · [Verification](docs/VERIFICATION.md)

</div>

---

**MyWes** is an iOS campus app that brings dining menus, campus events, and working hours for all Wes resources into one place. Its community forum, **AskWes**, lets students ask questions about choosing a major, planning their future, and navigating life at Wesleyan while sharing advice and experiences.

## Product vision

MyWes is being built as one place to navigate Wesleyan—from deciding where to eat and finding something to do, to getting advice on decisions that shape life during and after college. The experiences below describe the intended product.

| Experience | What MyWes is designed to offer |
| --- | --- |
| **Dining** | Find campus dining locations, explore menus and food options, and check hours before heading out. Student reviews are a possible future addition. |
| **Events & organizations** | Discover what is happening on campus, find communities around your interests, save events, and follow organizations you care about. |
| **Wesleyan resources** | Find working hours for resources across Wes, so students can plan around when services are available. The goal is campus-wide coverage beyond dining. |
| **AskWes** | Ask meaningful questions about majors, academic choices, future plans, and everyday campus life. Connect with upperclassmen and, as alumni access is developed, graduates who can share experience beyond Wesleyan. |
| **Your campus, personalized** | Keep saved events, followed organizations, and interests together to make campus life easier to navigate. |

## Current implementation

The MVP includes Wesleyan Google sign-in, event and organization browsing, persistent event saves and organization follows, catalog search, student questions and answers with title search and author deletion, profile editing, and dining schedules for three locations. Official Bon Appétit menu pages are available inside the app.

Campus-wide resource hours and alumni participation remain part of the product vision. Native menu listings and dining reviews are not implemented. Current sign-in is restricted to approved Wesleyan Google test accounts.

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
