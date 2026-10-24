# Owner decisions (design.md section 12)

Owner delegated 1-5, supplied 6, and 7 comes from the Xcode project. Items marked (call) are the builder's and open to change.

1. App name (call): **Waymark**, a waymark is a trail marker, which fits landmarks and trails. Not yet checked for App Store availability or trademark. Display name changes at the end of the slice; bundle id stays `beta.SimpleTask`.
2. Plus price (call): one-time **$14.99**, Family Sharing **on** (cannot be undone per product).
3. Shared pledges (call): **receipts only** for v1; no live CKShare.
4. Sound pack: **cut** (owner).
5. Reminders by default (call): iPhone, Mac and Watch on; iPad opt-in.
6. Universal-link domain (owner): `task.shapehaveninnovations.com`. Receipts link to `https://task.shapehaveninnovations.com/p/<id>`. Owner must host an `apple-app-site-association` file there.
7. IDs: Team `P9Z5QB8965` (from the existing project). App Group `group.beta.SimpleTask`. CloudKit container `iCloud.beta.SimpleTask` (needs creating in the developer portal; `Features.cloudSync` stays false until then).
8. Minimum OS: **iOS 26.0** (confirmed in Xcode).
