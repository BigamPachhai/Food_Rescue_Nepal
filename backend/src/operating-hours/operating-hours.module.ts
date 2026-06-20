import { Module } from '@nestjs/common';
import { OperatingHoursService } from './operating-hours.service';
import { OperatingHoursController } from './operating-hours.controller';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [OperatingHoursController],
  providers: [OperatingHoursService],
  exports: [OperatingHoursService],
})
export class OperatingHoursModule {}
