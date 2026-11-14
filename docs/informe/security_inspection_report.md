# Security Inspection Report — MicroplastIA

- Date: 2026-11-14
- Scope: backend (FastAPI), admin web (Angular), mobile app (Flutter), repository and Git workflow
- Branch: `feat/security-hardening` (merged into `dev`)
- Baseline: `main` `e4ed61c`, integration line `feature/reports` `8c75355`

## 1. Executive summary

The project already had solid foundations: JWT validation with token-type checks, bcrypt
password hashing, a password policy, login rate limiting keyed by a hashed email, trusted
hosts, CORS allow-lists, security headers, MIME and image decoding validation, and
ownership checks on history, results and reports.

This inspection found no committed secrets and no SQL injection or broken access-control
path. The main gaps were configuration hardening, denial-of-service edges, a login timing
side channel, plaintext mobile token storage, Android cleartext/backup defaults, and the
lack of a Content Security Policy in the admin web.

All P1 findings below are fixed in this branch. Residual accepted risks are listed in
section 5.

## 2. Findings

| ID | Severity | Area | Finding | Status |
|---|---|---|---|---|
| SEC-01 | High | Mobile | JWT stored in `shared_preferences` (plaintext). | Fixed: `flutter_secure_storage` with legacy migration and fallback. |
| SEC-02 | Medium | Mobile | `android:usesCleartextTraffic="true"` in the main manifest allowed HTTP in release builds. | Fixed: HTTPS only in release; cleartext enabled only in debug/profile manifests. |
| SEC-03 | Medium | Mobile | Android backup enabled; app data could be extracted from backups. | Fixed: `android:allowBackup="false"`. |
| SEC-04 | Medium | Auth | Login timing differed between existing and non-existing emails, enabling account enumeration. | Fixed: always verify against a dummy bcrypt hash. |
| SEC-05 | Medium | Auth | Passwords with many multibyte characters exceeded bcrypt's 72-byte limit and produced HTTP 500. | Fixed: UTF-8 byte-length check in the password policy. |
| SEC-06 | Medium | Backend config | Production could start with placeholder JWT secret, localhost hosts/origins, or wildcard CORS. | Fixed: fail-fast production validation at startup. |
| SEC-07 | Medium | Backend config | Interactive docs and OpenAPI could be enabled in production. | Fixed: docs are always disabled when `ENVIRONMENT=production`. |
| SEC-08 | Medium | Uploads | Image dimensions were validated only after full decoding; a highly compressed image with huge dimensions could exhaust memory. | Fixed: Pillow pixel limit plus header-only dimension check before decode. |
| SEC-09 | Low | Reports | Report filenames had only 24 bits of randomness, so public `/static/reports` URLs were guessable. | Fixed: 128-bit random filenames. |
| SEC-10 | Low | Analysis API | Mobile analysis payload had no upper bounds for particle count, processing time, breakdown size or detection count. | Fixed: bounded fields and breakdown validator. |
| SEC-11 | Low | Admin web | No Content Security Policy or referrer policy. | Fixed: restrictive CSP and `no-referrer` meta tags. |
| SEC-12 | Low | Repository | Stale feature branches and mixed branch workflow. | Fixed: `dev` integration branch, documented hierarchy, stale branches retired. |

## 3. Implemented controls

### Backend

- `backend/app/core/config.py`
  - `production_config_errors()` validates the JWT secret, trusted hosts and CORS origins.
  - `docs_available` disables `/docs`, `/redoc` and `/openapi.json` in production.
- `backend/app/main.py`
  - Calls `validate_production_settings()` at startup.
  - Uses `docs_available` instead of `docs_enabled`.
- `backend/app/core/password_policy.py`
  - Rejects passwords whose UTF-8 encoding exceeds 72 bytes.
- `backend/app/core/security.py`
  - Adds a dummy bcrypt hash for constant-work authentication failures.
- `backend/app/services/auth_service.py`
  - Verifies the dummy hash when the email does not exist.
- `backend/app/core/file_validation.py`
  - Sets `Image.MAX_IMAGE_PIXELS`.
  - Validates width, height and pixel count from the image header before decoding.
  - Rejects Pillow decompression bombs.
- `backend/app/api/v1/endpoints/analyze.py`
  - `total_particles <= 100000`
  - `processing_time_ms <= 86400000`
  - at most 10 breakdown categories, keys up to 50 chars, values `0..100000`
  - at most 1000 detections
- `backend/app/services/report_service.py`
  - Report filenames use a full `uuid4().hex` (128 bits).

### Admin web

- `admin_web/src/index.html`
  - CSP restricts scripts, styles, images, frames and network connections.
  - `Referrer-Policy: no-referrer`.

### Mobile

- `mobile/lib/services/session_service.dart`
  - JWT stored with `flutter_secure_storage`.
  - One-time migration from `shared_preferences`.
  - Fallback only when secure storage is unavailable, with a 1-second timeout.
  - Logout clears both stores.
- `mobile/android/app/src/main/AndroidManifest.xml`
  - `usesCleartextTraffic="false"`, `allowBackup="false"`.
- `mobile/android/app/src/debug/AndroidManifest.xml`,
  `mobile/android/app/src/profile/AndroidManifest.xml`
  - Cleartext allowed only for local development builds.

## 4. Verification

| Suite | Result |
|---|---|
| Backend (`pytest`, SQLite test database) | 56 passed, 1 known SQLite-only failure (`test_login_rate_limit`, timezone-naive datetime) |
| Admin web (`npm test`) | 17 passed |
| Admin web (`npm run build`) | Build OK, pre-existing CSS budget warnings only |
| Mobile (`flutter analyze`) | No issues |
| Mobile (`flutter test`) | 12 passed |

Backend command:

```bash
cd backend
DATABASE_URL=sqlite:////tmp/opencode/micro_test.db ./venv/bin/python -m pytest -q
```

Admin commands:

```bash
cd admin_web
npm test -- --watch=false
npm run build
```

Mobile commands (Flutter SDK 3.47.7):

```bash
cd mobile
flutter analyze
flutter test
```

## 5. Residual risks and recommendations

| Risk | Current mitigation | Recommendation |
|---|---|---|
| `/static/uploads`, `/static/detections` and `/static/reports` are publicly readable capability URLs. | 128-bit random filenames, no directory listing, `Cache-Control: no-store`. | Move reports and sample images behind an authenticated endpoint or short-lived signed URLs if they become sensitive. |
| Admin JWT remains in `localStorage`/`sessionStorage`. | CSP limits script sources; short 60-minute token. | Consider HttpOnly, Secure, SameSite cookies with CSRF protection. |
| Mobile WebSocket sends the JWT in the query string. | HTTPS/WSS only; short-lived token. | Switch to an `Authorization` header or a first-message handshake. |
| Release APK is signed with the debug key. | None. | Create a private release keystore, keep it out of Git, and configure signing in CI or locally. |
| Login rate limiting is per email, not per IP. | Account-based lockout, hashed identifiers. | Add a per-IP limit at the reverse proxy or application layer. |
| No database migration tool in use at startup (`create_all`). | Schema is created from models. | Adopt Alembic migrations for production changes. |
| Local `backend/.env` contains a development secret. | File is ignored and was never tracked. | Keep it local; rotate if it ever leaves the machine. |

No secrets are committed. `backend/.env.example` contains placeholders only.

## 6. Git branch consolidation

- `dev` created from `main` and fast-forwarded to `feature/reports`.
- `main` was not modified.
- Retired branches after verification: `feature/reports`, `feature/historial-analisis`,
  `fix/historial-esquema`, `origin/feature/flutter-views`.
- Archive tags preserve the retired tips: `archive/feature-historial-analisis`,
  `archive/fix-historial-esquema`.
- Workflow documented in `README.md`: `main` ← `dev` ← `feat/*` / `fix/*`.
