# MyWes verification — November 7, 2026

## Live simulator results

Tested the signed app on iPhone 17 / iOS 26.5 against the existing hosted Supabase project.

- The user completed Wesleyan Google/Duo login and reported success; authenticated Home was then observed directly in Device Hub.
- Restarted the app and observed authenticated Home without another Google/Duo prompt. Repeated after installing the Q&A correction: session restoration still succeeded.
- Loaded event details, host organization details, and the Saved Events surface from the hosted catalog.
- Saved Midnight Breakfast and followed Wesleyan Dining. Restarted the app: Home showed one saved event and an event from the followed organization. Detail screens retained Saved / Following.
- Un-saved the test event and unfollowed Wesleyan Dining afterward. Verified Saved Events is empty and Dining is back to Follow. The pre-existing WesWings Radio follow was preserved.
- Catalog search for `dining` returned Midnight Breakfast and Wesleyan Dining. AskWes title search queried the server, returned the disposable question, and opened its detail.
- With explicit approval, posted one disposable question and answer. Restarted the app, searched, and loaded both from Supabase. Deleted the answer and question afterward; verified No answers yet, then No questions yet and no search results for the test title.
- Profile loaded the existing year (2028), interests (Sports), email, and followed organizations. Saved the existing values unchanged and observed Profile saved. This verifies the write/response path; a changed-name/year round trip was not exercised.
- Dining displayed all three published locations, locations' descriptions, regular hours, schedule status, source links, verification dates, and validity dates. Runtime calendar/expiry edge cases are additionally covered by the local model checks.

Sign-out/relaunch is awaiting the user's preference because it will require another login. No physical iPhone test, fresh-account onboarding walkthrough, offline rollback UI test, login-cancellation check, or hosted second-account ownership attack was performed in this checkpoint. Cross-user ownership and domain restrictions were tested in isolated PostgreSQL, as described below.

## Build and regression checks

- Signed Debug and Release simulator builds pass, including the Q&A confirmation correction. Signing uses Xcode's local simulator identity (`CODE_SIGN_IDENTITY=-`), not a new developer account.
- Production database wire-model tests: before the field-mapping fix, 1 passed / 9 failed; after the fix, all 10 passed. These cover six response formats and four write payloads, compiled from the same Foundation-only models used by the app.
- Authentication-error regression checks pass for missing verifier, unrelated HTTP 400/403, domain denial, disabled provider, rate limiting, and secure-storage failure.
- Production dining checks pass for overnight service, closing boundaries, schedule validity, Eastern Time, DST, and malformed day counts.
- Applied all SQL migrations in isolated PostgreSQL with synthetic Auth roles/users. All 37 permission/persistence checks passed: anonymous denial, profile identity/ownership, catalog write protection, own-row follows/saves, Q&A authorship/deletion/cascade, and Wesleyan hook acceptance/rejection.
- Both app bundles were inspected: no design HTML/JS or handoff paths. No automated Xcode UI test target exists; the simulator flows above were observed through Device Hub.

Local tests do not establish physical-device behavior or hosted second-account denial.

## Hosted configuration

- Resumed the original paused Supabase project and observed Healthy.
- Verified all seven original migrations were already applied. Dry run identified only `202611070001_campus_mvp.sql`; applied it and verified matching hosted migration history. Did not run the sample catalog seed during this work.
- Google Cloud project `mywes-514007` has the MyWes consent screen and MyWes Supabase web OAuth client. The owner entered the secret directly in Supabase.
- Supabase Google provider enabled, expected client ID and stored secret present. Skip nonce checks and allow-missing-email remain off.
- Exact app redirect `mywes://auth-callback` is allowed. The enabled Before User Created hook is `public.hook_restrict_wesleyan_email`.
- Google audience remains External / Testing. Added the approved Wesleyan account as a test user and verified the saved list. Other students need test-user access until the Google app is prepared for production.
- Hosted anonymous sign-ins are off; email confirmation is on. The hosted Email provider was observed enabled; local CLI email signup is disabled for this Google-only app. Hosted Email-provider hardening remains a separate configuration item.

## Bugs found and corrected

1. **Database field names:** several models used camelCase while PostgreSQL returns snake_case. Explicit CodingKeys now cover profiles, onboarding/profile writes, events, organizations, Q&A, and dining. Auth's coders and engagement's existing keys were preserved. Profile-loading failures after OAuth preserve the valid session and show a retry screen.
2. **Simulator signing / PKCE:** an earlier compile-only bundle could not retain the login verifier. Hosted logs showed `/token` HTTP 400 for missing auth-code/verifier, not a domain rejection. Rebuilt with proper local signing and added a synthetic Keychain write/read/remove check before OAuth. The signed app passed it. No insecure storage fallback was introduced.
3. **Misleading errors:** HTTP 400/403 alone no longer produce a Wesleyan-only message. Specific server domain errors still do; PKCE/storage/provider failures have distinct messages.
4. **Answer confirmation:** live cleanup initially dismissed the dialog without deleting the answer. Separated the selected answer ID from the dialog's visibility state. Retested successfully against Supabase and removed both approved disposable entries.
5. **Release previews:** preview-only helpers were referenced by unguarded previews. Debug guards now keep those references out of Release compilation.

## Repository and file preservation

- Work was copied in full from `/Users/edomiasabebe/Developer/MyWes`; that original checkout was preserved and contains older code. Use the current workspace's MyWes project for further Xcode runs.
- Preserved all 23 local design handoff files with matching SHA-256 hashes in ignored `.local-assets/`, outside the synchronized app target. Untracked Xcode user state while keeping the file on disk.
- Secrets.xcconfig is ignored, untracked, and absent from Git history. Scoped credential-pattern scan of the initial 113 historical blobs found no matches; staged fixes were scanned too. No secret was added to the repository.
- With explicit approval, pushed the first three checkpoint commits and made `eddy090909/MyWes` public. Subsequent fixes remain local pending separate push approval.
- Verified all original 14 pushed commit authors are Edomias Zerihun and GitHub's contributor list contained only eddy090909. Subsequent local commits preserve that Git identity without added co-author attribution.
