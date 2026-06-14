# Food Rescue Nepal

Connect food vendors with customers to reduce food waste. One Flutter app, three roles: Customer, Vendor, Admin.

## Structure

```
food_rescue_nepal/
├── lib/               # Flutter app
├── backend/           # NestJS API
├── android/           # Android platform config
└── ios/               # iOS platform config
```

## Stack

**Frontend:** Flutter 3.x + Riverpod + GoRouter + Dio + flutter_map (OSM) + Firebase Messaging

**Backend:** NestJS + Prisma + PostgreSQL (Neon) + Cloudinary + Firebase Admin

## Setup

### Backend
See [backend/README.md](backend/README.md)

### Flutter App

```bash
# Install dependencies
flutter pub get

# Run on Android emulator (backend must be running)
flutter run --dart-define=BASE_URL=http://10.0.2.2:3000

# Run on iOS simulator
flutter run --dart-define=BASE_URL=http://localhost:3000

# Production build (Android)
flutter build apk --release --dart-define=BASE_URL=https://your-app.railway.app
```

### Firebase Setup (required for push notifications)

1. Create a Firebase project at console.firebase.google.com
2. Enable Cloud Messaging (FCM)
3. Download `google-services.json` → place at `android/app/google-services.json`
4. Download `GoogleService-Info.plist` → place at `ios/Runner/GoogleService-Info.plist`
5. Copy Firebase credentials to `backend/.env`

## Roles

| Role     | Access                                    |
|----------|-------------------------------------------|
| Customer | Browse listings, reserve, view QR pickup  |
| Vendor   | Post food, manage orders, scan QR codes   |
| Admin    | Manage users, approve vendors, view all   |

**Admin is seeded only** — no self-registration for admin.

## Payment

Cash on pickup only. No payment gateway.
