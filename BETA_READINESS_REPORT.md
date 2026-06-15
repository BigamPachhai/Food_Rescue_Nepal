# Beta Readiness Audit — Food Rescue Nepal
**Date:** 2026-06-15  
**Scope:** Flutter mobile app + NestJS backend  
**Verdict:** CONDITIONALLY READY FOR BETA — with the remaining manual steps below

---

## Fixes Applied in This Audit

| # | Issue | File | Status |
|---|-------|------|--------|
| 1 | `usesCleartextTraffic="true"` in release builds | `android/app/src/main/AndroidManifest.xml` | ✅ Fixed — moved to debug-only via `network_security_config.xml` |
| 2 | No network security config (no cert enforcement) | `android/app/src/main/res/xml/network_security_config.xml` | ✅ Created — HTTPS enforced in release; cleartext only in debug |
| 3 | R8 minification disabled for release APK | `android/app/build.gradle.kts` | ✅ Fixed — `isMinifyEnabled = true`, `isShrinkResources = true` |
| 4 | ProGuard rules missing | `android/app/proguard-rules.pro` | ✅ Created |
| 5 | Swagger API docs exposed in production | `backend/src/main.ts` | ✅ Fixed — Swagger now disabled when `NODE_ENV=production` |
| 6 | OTP value logged with user email | `backend/src/auth/auth.service.ts` | ✅ Fixed — OTP value removed from log line |
| 7 | `print()` with user email in release builds | `lib/features/auth/presentation/providers/auth_provider.dart` | ✅ Fixed — print statements removed |
| 8 | `.env.example` had insecure defaults | `backend/.env.example` | ✅ Fixed — `CORS_ORIGIN` and admin password updated |

---

## Remaining Manual Steps (Required Before Beta)

### 🔴 MUST DO — Blocking

#### 1. Configure Android Release Signing
The release build still uses the debug keystore. You must create a proper keystore before distributing the APK.

```bash
keytool -genkey -v -keystore food_rescue_release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias food_rescue
```

Then update `android/app/build.gradle.kts`:
```kotlin
signingConfigs {
    create("release") {
        storeFile = file("../../food_rescue_release.jks")
        storePassword = System.getenv("KEYSTORE_PASSWORD")
        keyAlias = "food_rescue"
        keyPassword = System.getenv("KEY_PASSWORD")
    }
}
// In buildTypes.release:
signingConfig = signingConfigs.getByName("release")
```

Store `food_rescue_release.jks` securely — losing it means you cannot update the app on Play Store.

#### 2. Set Backend `NODE_ENV=production` in Deployment
Ensure your hosting platform (Railway, Render, etc.) sets:
```
NODE_ENV=production
CORS_ORIGIN=https://your-beta-domain.com   # or * for mobile-only beta
```

#### 3. Change the Seeded Admin Password
After first deployment and database seed, immediately change the admin password:
- Log in at your backend with `ADMIN_SEED_EMAIL` / `ADMIN_SEED_PASSWORD`
- Change the password via the API or database directly
- `ADMIN_SEED_PASSWORD` in `.env` should be a random string generated with `openssl rand -base64 24`

#### 4. Add Error Tracking (Crash Reporting)
No crash reporting is configured. For beta, add Firebase Crashlytics:

**pubspec.yaml:**
```yaml
firebase_crashlytics: ^4.0.0
```

**main.dart:**
```dart
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
PlatformDispatcher.instance.onError = (error, stack) {
  FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  return true;
};
```

#### 5. Add Privacy Policy
Both Apple App Store and Google Play Store require a privacy policy URL before beta distribution. Create a simple page at your domain and add the URL to:
- App Store Connect → App Privacy
- Google Play Console → Store listing → Privacy policy

---

### 🟡 HIGH PRIORITY — Should Do for Beta

#### 6. Tighten Auth Rate Limiting
The global throttler (10 req/sec) is too loose for login endpoints. Add a dedicated guard:

```typescript
// In AuthController
@Throttle({ default: { limit: 5, ttl: 300000 } }) // 5 attempts per 5 minutes
@Post('login')
```

#### 7. Add Structured Backend Logging
Replace `console.log` and plain `Logger.log` with JSON-structured output so logs are parseable in Railway/Render dashboards:

```bash
npm install nest-winston winston
```

#### 8. Set `LOG_LEVEL` Environment Variable
Add to `.env` and `.env.example`:
```
LOG_LEVEL=info   # development: debug | production: warn or error
```

#### 9. Add Flutter Logger Package
Replace any remaining debug output with a proper logger:
```yaml
logger: ^2.4.0
```

#### 10. Add `DIRECT_URL` to `.env.example`
Neon PostgreSQL requires `DIRECT_URL` for Prisma migrations alongside `DATABASE_URL`. The example is missing it — add:
```
DIRECT_URL=postgresql://user:password@host:5432/food_rescue_nepal
```

---

### 🟢 NICE TO HAVE — Post-Beta

- **GDPR/Data deletion:** Add `DELETE /users/me` endpoint for user data removal
- **Certificate pinning:** Extend `network_security_config.xml` with `<pin-set>` for your backend domain
- **iOS HTTPS enforcement:** Confirm `NSAppTransportSecurity` is not overriding ATS in Info.plist
- **Token refresh rotation:** Invalidate old refresh token on each use to limit replay attacks
- **Audit logging:** Log sensitive operations (password changes, admin actions) to a separate table
- **API key rotation docs:** Document procedure for rotating Cloudinary and Firebase credentials

---

## Security Posture Summary

| Area | Status | Score |
|------|--------|-------|
| Android build config | ✅ Release-ready after signing step | 8/10 |
| iOS build config | ✅ Permissions correct, ATS default-on | 8/10 |
| Environment variables | ✅ Not in git; rotation required | 7/10 |
| Backend security (helmet, throttle, validation) | ✅ Solid foundation | 8/10 |
| CORS | ⚠️ Set `CORS_ORIGIN` in deployment env | 6/10 |
| Logging | ✅ OTP removed; structured logging recommended | 7/10 |
| Error tracking | ❌ No crash reporting | 2/10 |
| App icons & splash | ✅ All sizes present | 9/10 |
| Permissions | ✅ Matches actual usage | 9/10 |
| Privacy compliance | ⚠️ Privacy policy URL required | 4/10 |
| **Overall** | **Beta-ready after manual steps** | **7/10** |

---

## What's Already Good

- bcrypt 12-round password hashing
- JWT short-lived access tokens (15 min) + refresh tokens (7 days)
- `flutter_secure_storage` for token storage on device
- Helmet security headers
- Input validation with whitelist and `forbidNonWhitelisted`
- `HttpExceptionFilter` prevents stack traces leaking to clients
- Zod env validation at startup — misconfigured deployment fails fast
- Camera, location, and photo permissions declared with clear usage descriptions
- `.env` and Firebase config files excluded from git
- Cloudinary file type and size validation server-side
- Rate limiting (global throttler)
