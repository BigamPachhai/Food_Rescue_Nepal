import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { APP_GUARD } from '@nestjs/core';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { VendorsModule } from './vendors/vendors.module';
import { ListingsModule } from './listings/listings.module';
import { OrdersModule } from './orders/orders.module';
import { ReviewsModule } from './reviews/reviews.module';
import { NotificationsModule } from './notifications/notifications.module';
import { FavoritesModule } from './favorites/favorites.module';
import { UploadModule } from './upload/upload.module';
import { AdminModule } from './admin/admin.module';
import { ReportsModule } from './reports/reports.module';
import { validateEnv } from './config/env.config';
// New feature modules
import { WaitlistModule } from './waitlist/waitlist.module';
import { PromoCodesModule } from './promo-codes/promo-codes.module';
import { LoyaltyModule } from './loyalty/loyalty.module';
import { ReferralModule } from './referral/referral.module';
import { ChatModule } from './chat/chat.module';
import { ListingTemplatesModule } from './listing-templates/listing-templates.module';
import { FlashSalesModule } from './flash-sales/flash-sales.module';
import { OperatingHoursModule } from './operating-hours/operating-hours.module';
import { DonationsModule } from './donations/donations.module';
import { DisputesModule } from './disputes/disputes.module';
import { AnnouncementsModule } from './announcements/announcements.module';
import { AuditLogModule } from './audit-log/audit-log.module';
import { VendorVerificationModule } from './vendor-verification/vendor-verification.module';
import { DataExportModule } from './data-export/data-export.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      validate: validateEnv,
      envFilePath: '.env',
    }),
    ThrottlerModule.forRoot([
      { name: 'short', ttl: 1000, limit: 10 },
      { name: 'medium', ttl: 60000, limit: 100 },
    ]),
    PrismaModule,
    AuthModule,
    UsersModule,
    VendorsModule,
    ListingsModule,
    OrdersModule,
    ReviewsModule,
    NotificationsModule,
    FavoritesModule,
    UploadModule,
    AdminModule,
    ReportsModule,
    // Feature modules
    WaitlistModule,
    PromoCodesModule,
    LoyaltyModule,
    ReferralModule,
    ChatModule,
    ListingTemplatesModule,
    FlashSalesModule,
    OperatingHoursModule,
    DonationsModule,
    DisputesModule,
    AnnouncementsModule,
    AuditLogModule,
    VendorVerificationModule,
    DataExportModule,
  ],
  providers: [
    { provide: APP_GUARD, useClass: ThrottlerGuard },
  ],
})
export class AppModule {}
