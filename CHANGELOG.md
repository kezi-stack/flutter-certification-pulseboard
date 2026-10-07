# Changelog

All notable project changes are documented here.

## [2.1.0] — 2026-10-07

- Added a five-section Pulseboard workspace with overview metrics and task filters.
- Added French and English UI copy with an in-app language selector.
- Added semantic labels, lazy list rendering, and downsampled user avatars.
- Added unit, widget, and Android integration tests.
- Added GitHub Actions analysis, test, Android APK, and screenshot-artifact jobs.
- Reworked the project documentation and added a certification-ready setup guide.

## [2.0.1] — 2026-09-26

- Registered the Mocktail response fallback used by repository and authentication tests.
- Kept API client construction behind the `SessionStore` abstraction.

## [2.0.0] — 2026-09-25

- Added the Pulseboard Flutter application with JWT login, registration, and logout.
- Added REST-backed users, posts, and tasks with Hive cache fallback.
- Introduced the `data / domain / presentation` architecture and repository contracts.
