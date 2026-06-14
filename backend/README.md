# Food Rescue Nepal — Backend

NestJS + Prisma + PostgreSQL (Neon) + Cloudinary + Firebase Admin

## Quick Start

```bash
# 1. Install dependencies
npm install

# 2. Copy and fill env
cp .env.example .env

# 3. Run database migration
npx prisma migrate dev --name init

# 4. Seed database (admin + test users + sample listings)
npm run prisma:seed

# 5. Start development server
npm run start:dev
```

API docs available at: http://localhost:3000/api/docs
Health check: http://localhost:3000/health

## Test Credentials

| Role     | Email                        | Password       |
|----------|------------------------------|----------------|
| Admin    | admin@foodrescuenepal.com    | Admin@12345!   |
| Customer | customer@test.com            | Test@1234!     |
| Vendor   | vendor@test.com (APPROVED)   | Test@1234!     |
| Vendor   | vendor2@test.com (PENDING)   | Test@1234!     |

## Deploy to Railway

1. Push to GitHub
2. Connect repo in Railway dashboard
3. Set all env vars from `.env.example`
4. Railway auto-deploys on push to main

## Architecture

- **Auth**: JWT access (15m) + refresh token (7d, httpOnly cookie)
- **Images**: Cloudinary v2 (avatars/, logos/, listings/ folders)
- **Push**: Firebase Admin SDK → FCM
- **ORM**: Prisma with Neon PostgreSQL (serverless)
