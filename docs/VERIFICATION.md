# MVP verification checkpoint — November 7, 2026

## Completed local checks

- Original checkout copied in full from `/Users/edomiasabebe/Developer/MyWes`; active work is in the current workspace's `MyWes` folder. Original checkout remains unchanged.
- All 23 design handoff files preserved with matching SHA-256 hashes, outside the synchronized app source folder.
- UserInterfaceState untracked, local file preserved; Secrets.xcconfig ignored and absent from Git history.
- Credential-pattern scan examined 113 historical blobs with no private-key, JWT, GitHub-token, or secret-key pattern matches. This is a scoped scan, not an absolute guarantee.
- Debug simulator build passed with the new tabs and services; Release simulator build also passed after guarding preview code. No design HTML/JS in the app bundle. ProfileRecord actor-isolation warning fixed.
- Production dining model checks passed for overnight service, exact boundaries, validity dates, Eastern Time, DST, and malformed day counts.
- All migrations applied to isolated PostgreSQL with synthetic Auth roles. 37 assertions passed for anonymous denial, profile ownership/identity protection, catalog write protection, own-row follows/saves, Q&A authorship/deletion/cascade, and Wesleyan signup hook acceptance/rejection.
- GitHub read-only check confirmed `eddy090909/MyWes` is private. No push or visibility change performed.

## Hosted checkpoint

- Resumed the paused, existing linked Supabase project; dashboard subsequently reported Healthy.
- Read hosted migration history: all seven original migrations were present.
- A dry run identified only `202611070001_campus_mvp.sql`; applied that migration successfully via the Supabase CLI. No catalog sample seed or Git push was performed.
- Hosted Google provider is disabled and Client IDs / Client Secret fields are empty. OAuth setup is a real remaining dependency, not a code-test success.
- Anonymous sign-ins are disabled and email confirmation is enabled in hosted settings.

- Final Debug simulator build also passed after all session and preview fixes.
- Installed on the iPhone 17 / iOS 26.5 simulator; `simctl launch` returned a process ID successfully. This is a launch smoke check, not authenticated UI verification.
- Both Debug and Release app bundles were inspected: no design HTML/JS or design handoff paths.
- Hosted `hook_restrict_wesleyan_email` is ENABLED under Before User Created.
- Hosted redirect allowlist contains the exact `mywes://auth-callback` URL.

## Still required before declaring the MVP working
- Configure the missing Google OAuth web client and enable the Google provider. Redirect allowlist and Before User Created hook have been verified.
- Sign in through Google with a real Wesleyan account, cancel login, and verify a non-Wesleyan account is rejected by the server.
- Verify first-login profile provisioning, onboarding persistence, relaunch/session restore, and sign-out followed by relaunch.
- Browse real events and organizations; save/unsave and follow/unfollow, relaunch, verify persistence and failure rollback.
- Post and answer a question, search for it, relaunch, verify persistence; use a second account to verify cross-user deletion is rejected.
- Verify dining schedule display and official links on a simulator and iPhone, including expired schedule handling.
- Edit name/year/interests and verify after relaunch.
- Complete physical-device testing. Debug and Release simulator builds passed. No automated UI test target exists yet.

No hosted OAuth or physical-device success is claimed by the local tests.
