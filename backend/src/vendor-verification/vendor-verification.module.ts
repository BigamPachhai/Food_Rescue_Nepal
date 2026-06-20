import { Module } from '@nestjs/common';
import { VendorVerificationService } from './vendor-verification.service';
import { VendorVerificationController } from './vendor-verification.controller';
import { PrismaModule } from '../prisma/prisma.module';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [PrismaModule, NotificationsModule],
  controllers: [VendorVerificationController],
  providers: [VendorVerificationService],
  exports: [VendorVerificationService],
})
export class VendorVerificationModule {}
